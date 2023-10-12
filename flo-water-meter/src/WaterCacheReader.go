package main

import (
	"bytes"
	"compress/gzip"
	"io/ioutil"
	"math"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis"
)

type WaterCacheReader interface {
	Get(mac string, from, to time.Time) ([]*WaterUsage, error)
}

// logic to read cached water data from redis
type waterCacheReader struct {
	log *Logger
	red *RedisConnection
	h2o WaterReader
}

func CreateWaterCacheReader(log *Logger, red *RedisConnection, h2o WaterReader) WaterCacheReader {
	return &waterCacheReader{log.CloneAsChild("WaterRead$"), red, h2o}
}

func (c *waterCacheReader) Get(mac string, from, to time.Time) ([]*WaterUsage, error) {
	// Data is retrieved in daily buckets based on UTC timezone
	var (
		dataUtcFrom = from.UTC().Truncate(24 * time.Hour).Add(-24 * time.Hour)
		dataUtcTo   = to.UTC().Truncate(24 * time.Hour).Add(24 * time.Hour)
		res, err    = c.getData(mac, dataUtcFrom, dataUtcTo)
	)
	if len(res) != 0 { //trim response to request portions
		res = c.filterDataByDate(res, from, to)
	}
	return res, err
}

var FLO_REPORT_FROM_ARCHIVE_MONTHS = -3

func init() {
	//feature is enable if value is a negative number (months from current in which data will be pulled from dynamo. SEE: SNTY-494)
	if m, e := strconv.Atoi(getEnvOrDefault("FLO_REPORT_FROM_ARCHIVE_MONTHS", "")); e == nil && m <= 0 {
		FLO_REPORT_FROM_ARCHIVE_MONTHS = m
	}
	logNotice("FLO_REPORT_FROM_ARCHIVE_MONTHS=%v", FLO_REPORT_FROM_ARCHIVE_MONTHS)
}

func redisReadStart() time.Time {
	// if current day is June 22, "-3" value will cache data will start on April 1st, days before that will be fetched from archived (dynamo data)
	// -1 means truncate to the start of the current month, -3 means, truncate to the start of the month then minus 2 more months
	// :. April 1st if current date is May 22nd
	var (
		now                          = time.Now().UTC()
		currentYear, currentMonth, _ = now.Date()
		dtLoc                        = now.Location()
		firstOfMonth                 = time.Date(currentYear, currentMonth, 1, 0, 0, 0, 0, dtLoc)
	)
	return firstOfMonth.AddDate(0, FLO_REPORT_FROM_ARCHIVE_MONTHS+1, 0)
}

func (c *waterCacheReader) cacheReadAfter() time.Time {
	if FLO_REPORT_FROM_ARCHIVE_MONTHS < 0 {
		return redisReadStart()
	} else {
		return c.h2o.GetCachedFirstRowTime() //old logic or if reading from archive is not configured for newer data
	}
}

func (c *waterCacheReader) getData(mac string, from, to time.Time) ([]*WaterUsage, error) {
	if liveStart := c.cacheReadAfter(); !liveStart.After(from) { //entire thing is in redis
		return c.getLiveData(mac, from, to)
	} else if !to.After(liveStart) { //entire thing is in archive
		return c.getArchiveData(mac, from, to)
	} else { // some of it is in both
		res, e := c.getArchiveData(mac, from, liveStart)
		if rl := len(res); e == nil && rl > 0 {
			var live []*WaterUsage
			if live, e = c.getLiveData(mac, liveStart, to); e == nil {
				if ll := len(live); ll > 0 {
					if lastArchive, firstLive := res[rl-1], live[0]; firstLive.Date == lastArchive.Date { //overlap
						if firstLive.Missing && !lastArchive.Missing { //use archive
							live = live[1:]
						} else { //use live data
							res = res[:rl-1]
						}
					}
					res = append(res, live...)
				}
			}
		}
		return res, e
	}
}

func (c *waterCacheReader) getArchiveData(mac string, from, to time.Time) ([]*WaterUsage, error) {
	if raw, e := c.h2o.GetWaterHourlyFromArchive(mac, from, to); e != nil {
		return nil, e
	} else {
		return c.toWaterUsage(raw), nil
	}
}

func (c *waterCacheReader) toWaterUsage(raw []*WaterData) []*WaterUsage {
	if raw == nil {
		return nil
	}
	res := make([]*WaterUsage, 0, len(raw))
	for _, r := range raw {
		u := r.ToWaterUsage()
		if !u.Missing {
			u.PSI = round64(u.PSI, 3)
			u.Used = round64(u.Used, 3)
			u.Rate = round64(u.Rate, 3)
			u.Temp = round64(u.Temp, 3)
		}
		res = append(res, u)
	}
	return res
}

func (c *waterCacheReader) getLiveData(mac string, from, to time.Time) ([]*WaterUsage, error) {
	if redisData, err := c.getDataFromRedis(mac, from, to); err != nil { //over fetch data by day buckets
		return nil, err
	} else {
		res := c.parseDataFromRedis(from, to, redisData) //always do this
		return res, nil
	}
}

func (c *waterCacheReader) filterDataByDate(
	parsedData []*WaterUsage, reqFromDate time.Time, reqToDate time.Time) []*WaterUsage {

	rowEst := int(math.Max(math.Ceil(reqToDate.Sub(reqFromDate).Hours()), 0))
	rv := make([]*WaterUsage, 0, rowEst)
	for _, data := range parsedData {
		if data.Date.Before(reqFromDate.UTC()) {
			continue
		} else if data.Date.After(reqToDate.UTC()) || data.Date.Equal(reqToDate.UTC()) {
			continue
		}
		rv = append(rv, data)
	}
	return rv
}

func (c *waterCacheReader) getMonthNumbers(from time.Time, to time.Time) []time.Time {
	var (
		delta = make(map[time.Time]bool, 0)
		cur   = from.UTC().Truncate(time.Hour * 24)
	)
	for cur.Before(to) {
		x := time.Date(cur.Year(), cur.Month(), 1, 0, 0, 0, 0, time.UTC)
		delta[x] = true
		cur = cur.Add(time.Hour * 24)
	}

	rv := make([]time.Time, 0)
	for k, _ := range delta {
		rv = append(rv, k)
	}
	sort.Slice(rv, func(i, j int) bool { return rv[i].Before(rv[j]) })
	return rv
}

func (c *waterCacheReader) getDataFromRedis(macAddress string, from time.Time, to time.Time) (map[string]string, error) {
	var (
		coveredMonths = c.getMonthNumbers(from.UTC(), to.UTC())
		combined      = make(map[string]string)
		zz            *gzip.Reader
		es            = make([]error, 0)
	)
	for _, mo := range coveredMonths {
		redisKey := genRedisKey(macAddress, mo)
		data, err := c.red.HGetAll(redisKey)
		if err != nil && err != redis.Nil {
			es = append(es, c.log.IfErrorF(err, "getDataFromRedis: Redis Key: %v (month)", redisKey))
			continue
		}
		if len(data) == 0 {
			c.log.Notice("getDataFromRedis: Empty dataset for %v (month)", redisKey)
			continue
		}
		_, zz, err = c.processRedisMap(zz, data, combined)
		if err != nil {
			es = append(es, c.log.IfErrorF(err, "getDataFromRedis: processRedisMap: %v (month)", redisKey))
			continue
		}
	}
	if zz != nil {
		defer zz.Close()
	}
	return combined, wrapErrors(es)
}

func (c *waterCacheReader) processRedisMap(zr *gzip.Reader, data map[string]string, combined map[string]string) (rowsOK int, nzr *gzip.Reader, lastError error) {
	for k, v := range data {
		if len(k) >= 2 && k[0:2] == "20" { //date key
			var s string
			var e error
			s, zr, e = c.tryUnzipData(zr, v)
			if e != nil {
				lastError = e
			} else {
				combined[k] = s
				rowsOK++
			}
		} else {
			combined[k] = v
		}
	}
	return rowsOK, zr, lastError
}

func (c *waterCacheReader) tryUnzipData(zr *gzip.Reader, v string) (string, *gzip.Reader, error) {
	buf := bytes.NewBufferString(v)
	var e error
	if zr == nil {
		zr, e = gzip.NewReader(buf)
	} else {
		zr.Close()
		e = zr.Reset(buf) //saves file handles
	}
	if e == nil {
		arr, e := ioutil.ReadAll(zr)
		if e == nil {
			return string(arr), zr, nil
		} else { // probably already csv
			zr = nil
		}
	} // probably already csv
	return v, zr, e
}

func (c *waterCacheReader) parseDataFromRedis(from time.Time, to time.Time, redisData map[string]string) []*WaterUsage {
	curr := from
	rowEst := int(math.Max(math.Ceil(to.Sub(curr).Hours()), 0))
	delta := make([]*WaterUsage, 0, rowEst)

	for curr.Before(to) {
		data := redisData[curr.Format("2006-01-02")]
		if len(data) == 0 {
			hour := curr
			for x := 0; x < 24; x++ {
				delta = append(delta, &WaterUsage{Date: hour, Missing: true})
				hour = hour.Add(time.Hour)
			}
		} else {
			csvArray := strings.Split(data, ",")
			hour := curr
			dataCount := 0

			for h := 0; h < 24; h++ {
				deltaHourly := new(WaterUsage)
				deltaHourly.Date = hour
				csvValue := csvArray[h]

				if len(csvArray) < 96 || csvValue == "" {
					deltaHourly.Missing = true
				} else {
					used, _ := strconv.ParseFloat(csvArray[h], 64)
					rate, _ := strconv.ParseFloat(csvArray[h+24], 64)
					psi, _ := strconv.ParseFloat(csvArray[h+48], 64)
					temp, _ := strconv.ParseFloat(csvArray[h+72], 64)

					if used+rate+psi+temp == 0 {
						deltaHourly.Missing = true
					} else {
						deltaHourly.Used = cleanFloat(used)
						deltaHourly.Rate = cleanFloat(rate)
						deltaHourly.PSI = cleanFloat(psi)
						deltaHourly.Temp = cleanFloat(temp)

						dataCount++
					}
				}
				delta = append(delta, deltaHourly)
				hour = hour.Add(time.Hour)
			}
		}
		curr = curr.Add(time.Hour * 24)
	}
	return delta
}
