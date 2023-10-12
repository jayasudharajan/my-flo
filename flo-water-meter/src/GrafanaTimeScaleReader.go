package main

import (
	"context"
	"database/sql"
	"math"
	"sort"
	"time"

	"golang.org/x/sync/semaphore"
)

type GrafanaTimeScaleReader struct {
	ts          *PgSqlDb
	dynamodb    *dynamoDBSession
	waterReader WaterReader

	_ctx       context.Context
	_ctxCancel context.CancelFunc
	_semTs     *semaphore.Weighted
}

// Past5minTime returns the time after which we start using the unprocessed (5 minute buckets) telemetry data
// rather than aggregations of it
func (g *GrafanaTimeScaleReader) Past5minTime() time.Time {
	return time.Now().Add(-DUR_1_WEEK * 2).Truncate(time.Hour).Add(time.Hour).UTC()
}

func CreateGrafanaTimeScaleReader(waterReader WaterReader) (*GrafanaTimeScaleReader, error) {
	var e error
	if waterReader == nil {
		return nil, logError("CreateGrafanaTimeScaleReaderWithConn: waterReader is nil")
	}

	dynamo, e := DynamoSingleton()
	if e != nil {
		return nil, e
	}

	g := GrafanaTimeScaleReader{
		ts:          waterReader.TSDB(), // TODO: change to call TBD singleton factory
		waterReader: waterReader,
		dynamodb:    dynamo,
	}
	g._ctx, g._ctxCancel = context.WithCancel(context.Background())
	g._semTs = semaphore.NewWeighted(4)
	return &g, nil
}

func (g *GrafanaTimeScaleReader) Close() {
	if g == nil {
		return
	}
	g._ctxCancel() //don't wait just kill
	if g.ts != nil {
		g.ts.Close()
	}
}

func (g *GrafanaTimeScaleReader) GetRange(deviceId string, start time.Time, end time.Time) ([]TelemetryData, error) {
	if g == nil {
		return nil, logError("GrafanaS3FileReader.GetRange: gs is nil")
	}
	if end.Sub(start) > DUR_1_DAY*21 { //beyond 21 days range, just use hourly to save RAM
		return g.queryHourlyThenArchive(deviceId, start, end)
	}

	cut5min := g.Past5minTime()
	pastHourlyTime := g.waterReader.GetCachedFirstRowTime().UTC()
	if pastHourlyTime.After(cut5min) {
		cut5min = pastHourlyTime
	}
	if start.Before(cut5min) {
		if end.Before(cut5min) { //entire query in hourly + archive
			return g.queryHourlyThenArchive(deviceId, start, end)
		} else { //second .5 query in hour + archive
			res, e := g.queryHourlyThenArchive(deviceId, start, cut5min)
			if e == nil {
				var part2 []TelemetryData
				part2, e = g.query5min(deviceId, cut5min, end)
				if e == nil {
					res = append(res, part2...)
				}
			}
			return res, e
		}
	} else { //entire query in 5min
		return g.query5min(deviceId, start, end)
	}
}

func (g *GrafanaTimeScaleReader) queryHourlyThenArchive(deviceId string, start time.Time, end time.Time) ([]TelemetryData, error) {
	pastHourlyTime := g.waterReader.GetCachedFirstRowTime().UTC()
	if start.Before(pastHourlyTime) {
		bucketsEst := int(math.Max(math.Ceil(end.Sub(start).Hours()), 0))
		res := make([]TelemetryData, 0, bucketsEst)
		var e error
		firstPassEnd := pastHourlyTime
		if end.Before(firstPassEnd) {
			firstPassEnd = end
		}
		res, e = g.queryArchive(deviceId, start, firstPassEnd)
		if end.After(pastHourlyTime) {
			part2, ex := g.queryHourly(deviceId, pastHourlyTime, end)
			if ex != nil {
				e = ex
			} else {
				res = append(res, part2...)
			}
		}
		return res, e
	}
	return g.queryHourly(deviceId, start, end)
}

func sortAscTelemetryData(arr []TelemetryData) []TelemetryData {
	if len(arr) > 0 {
		sort.Slice(arr, func(i, j int) bool {
			return arr[i].Timestamp < arr[j].Timestamp
		})
	}
	return arr
}

func (g *GrafanaTimeScaleReader) queryHourly(deviceId string, start time.Time, end time.Time) ([]TelemetryData, error) {
	res, e := g.query(
		"queryHourly",
		func(rows *sql.Rows) (d TelemetryData, e error) {
			d = TelemetryData{MacAddress: deviceId}
			var dt time.Time
			e = rows.Scan(&dt, &d.UseGallons, &d.GPM, &d.PSI, &d.TempF)
			d.Timestamp = dt.Unix() * 1000
			return d, e
		},
		`select bucket, total_gallon, gpm_avg, psi_avg, temp_avg 
			from water_hourly where device_id = $1 and (bucket >= $2 and bucket < $3);`,
		deviceId, start, end,
	)
	return sortAscTelemetryData(res), e
}

func (g *GrafanaTimeScaleReader) query5min(deviceId string, start time.Time, end time.Time) ([]TelemetryData, error) {
	res, e := g.query(
		"query5min",
		func(rows *sql.Rows) (d TelemetryData, e error) {
			d = TelemetryData{MacAddress: deviceId}
			var dt time.Time
			e = rows.Scan(&dt, &d.UseGallons, &d.GPM, &d.PSI, &d.TempF)
			d.Timestamp = dt.Unix() * 1000
			return d, e
		},
		`select bk, total_gallon, 
			case
				when seconds_flo = 0 then 0
				else gpm_sum / seconds_flo 
			end as gpm_avg,
			case
				when seconds = 0 then 0
				else psi_sum / seconds 
			end as psi_avg,
			case
				when seconds = 0 then 0
				else temp_sum / seconds 
			end as temp_avg
		from water_5min where device_id = $1 and (bk >= $2 and bk < $3);`,
		deviceId, start, end,
	)
	return sortAscTelemetryData(res), e
}

func (g *GrafanaTimeScaleReader) queryArchive(deviceId string, start time.Time, end time.Time) ([]TelemetryData, error) {
	wd, err := g.waterReader.GetWaterHourlyFromArchive(deviceId, start, end)
	if err != nil {
		return nil, err
	}

	res := make([]TelemetryData, len(wd))
	for i := 0; i < len(wd); i++ {
		res[i] = TelemetryData{
			MacAddress: deviceId,
			GPM:        float32(wd[i].FlowRate),
			PSI:        float32(wd[i].Pressure),
			TempF:      float32(wd[i].Temp),
			UseGallons: float32(wd[i].Consumption),
			Timestamp:  wd[i].Bucket.Unix() * 1000,
		}
	}
	return sortAscTelemetryData(res), nil
}

func (g *GrafanaTimeScaleReader) query(
	queryName string,
	readRow func(rows *sql.Rows) (TelemetryData, error),
	sql string,
	params ...interface{}) ([]TelemetryData, error) {

	rows, e := g.ts.Connection.Query(sql, params...)
	if e != nil {
		return nil, logWarn("GrafanaTimeScaleReader.query: send %v %v => %v", queryName, params, e.Error())
	}
	defer rows.Close()

	res := make([]TelemetryData, 0)
	var re error
	var i int64 = 0
	for rows.Next() {
		var d TelemetryData
		d, e = readRow(rows)
		if e != nil {
			re = logWarn("GrafanaTimeScaleReader.query: readRow %v %v => %v", queryName, params, e.Error())
			continue
		}
		res = append(res, d)
		i++
	}
	if e = rows.Close(); e != nil {
		re = logWarn("GrafanaTimeScaleReader.query: close %v %v => %v", queryName, params, e.Error())
	}
	return res, re
}
