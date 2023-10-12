package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"golang.org/x/sync/semaphore"
)

const ENVVAR_TIMESCALE_READ_DB_CN = "FLO_TIMESCALE_READ_DB_CN"
const ENVVAR_TIMESCALE_DEBUG = "FLO_LOCAL_DEBUG"
const ENVVAR_TIMESCALE_READ_THREADS = "FLO_TIMESCALE_READ_THREADS" //max concurrent read threads for the semaphores
const DEFAULT_TIMESCALE_READ_THREADS = 5
const ENVVAR_TIMESCALE_LIVEDATA_CUTOFF_HRS = "FLO_TIMESCALE_LIVEDATA_CUTOFF_HRS"

type WaterReader interface {
	MustOpen() WaterReader
	Open() error
	Close() error
	GetPinger(svc string) func() error
	TSDB() *PgSqlDb
	Stats() *WaterReaderStats

	GetCachedFirstRowTimeArchive() time.Time
	GetCachedFirstRowTime() time.Time

	GetWaterHourlyWithSem(did string, start time.Time, end time.Time, liveRequest bool) (res []*WaterData, e error)
	GetWaterHourly(did string, start time.Time, end time.Time, liveRequest bool) (res []*WaterData, e error)
	GetWaterHourlyFromArchiveWithSem(did string, start time.Time, end time.Time) ([]*WaterData, error)
	GetWaterHourlyFromArchive(did string, start time.Time, end time.Time) ([]*WaterData, error)

	GetDeviceFirstDataCached(noCache bool, deviceIds ...string) map[string]time.Time
	GetDeviceFirstData(rMap map[string]time.Time) map[string]time.Time

	GetArchiveStartTime() (time.Time, error)
	GetArchiveEndTime() (time.Time, error)
	GetLiveDataStartTime() (time.Time, error)

	GetArchiveableRows(startTime time.Time, endTime time.Time, offset, limit int) WaterArchiveData
}

// waterReader logic to mainly read aggregate data from TSDB
type waterReader struct {
	ts               *PgSqlDb
	TimescaleConnStr string // TimeScaleDB connection string
	redis            *RedisConnection
	dynamodb         *dynamoDBSession
	RedisConnStr     string
	state            int32               // 0 == unknown, 1 == started, 2 == stopped
	FirstWrite       func() time.Time    // when TS data starts
	FirstArchive     func() time.Time    // when TS archive data starts
	_tsDebug         bool                // if true, will switch on debug mode, meant for local use only
	ctx              context.Context     // use for weighted semaphore
	ctxCancel        context.CancelFunc  // cancel handle for quitting
	liveMax          int64               // how many concurrent live request can we support, by default 1/2 of the bg requests
	semLive          *semaphore.Weighted // high priority query lock bucket, used for live presence channels
	bgMax            int64               // how many concurrent background request can we support
	semBg            *semaphore.Weighted // lower priority query lock bucket, used for constant scheduled regeneration
	mux              sync.Mutex
	stats            *WaterReaderStats // the rolled up stats before a summary print
	liveDataCutoffHr int64             // how many hours into the past before we allow data from hourly table
}

func DefaultWaterReader() WaterReader {
	t, e := CreateWaterReader("", "", 0)
	if e != nil {
		os.Exit(10)
	}
	return t
}
func CreateWaterReader(tsConn, redisCn string, readThreads int64) (WaterReader, error) {
	if tsConn == "" {
		if tsConn = getEnvOrDefault(ENVVAR_TIMESCALE_READ_DB_CN, ""); tsConn == "" {
			if tsConn = getEnvOrDefault(ENVVAR_TIMESCALE_DB_CN, ""); tsConn == "" {
				return nil, logError("CreateWaterReader: tsConn or %v is required", ENVVAR_TIMESCALE_READ_DB_CN)
			} else {
				logNotice("CreateWaterReader: %v is missing, using %v instead", ENVVAR_TIMESCALE_READ_DB_CN, ENVVAR_TIMESCALE_DB_CN)
			}
		}
	}
	if redisCn == "" {
		if redisCn = getEnvOrDefault(ENVVAR_REDIS_CN, ""); redisCn == "" {
			return nil, logError("CreateWaterReader: redisCn or %v is required", ENVVAR_REDIS_CN)
		}
	}

	r := waterReader{}
	r.stats = CreateWaterReaderStats()
	if readThreads < 1 {
		tstr := getEnvOrDefault(ENVVAR_TIMESCALE_READ_THREADS, "")
		readThreads, _ = strconv.ParseInt(tstr, 10, 64)
		if readThreads < 1 {
			readThreads = DEFAULT_TIMESCALE_READ_THREADS
		}
	}
	if readThreads < 1 {
		readThreads = 1
	}
	r.liveMax = readThreads
	r.bgMax = readThreads
	r.semBg = semaphore.NewWeighted(r.bgMax)
	r.semLive = semaphore.NewWeighted(r.liveMax)

	r.TimescaleConnStr = tsConn
	r.RedisConnStr = redisCn
	r._tsDebug = strings.ToLower(getEnvOrDefault(ENVVAR_TIMESCALE_DEBUG, "")) == "true"

	if cutOffHrs, _ := strconv.ParseInt(getEnvOrDefault(ENVVAR_TIMESCALE_LIVEDATA_CUTOFF_HRS, ""), 10, 64); cutOffHrs <= 0 {
		r.liveDataCutoffHr = 4 //default is 4hrs
	} else {
		r.liveDataCutoffHr = cutOffHrs
	}

	r.FirstWrite = r.memoizeTimeQuery("FirstWrite", time.Date(2020, 03, 01, 0, 0, 0, 0, time.UTC), r.GetLiveDataStartTime)
	r.FirstArchive = r.memoizeTimeQuery("FirstArchive", time.Date(2017, 03, 02, 0, 0, 0, 0, time.UTC), r.GetArchiveStartTime)

	logNotice("CreateWaterReader: %v=%v.", ENVVAR_TIMESCALE_DEBUG, r._tsDebug)
	logNotice("CreateWaterReader: %v=%v.", ENVVAR_TIMESCALE_LIVEDATA_CUTOFF_HRS, r.liveDataCutoffHr)
	return &r, nil
}

func (t *waterReader) GetPinger(svc string) func() error {
	switch strings.ToLower(svc) {
	case "redis":
		return t.redis.Ping
	case "timescale":
		return t.ts.Ping
	case "dynamo":
		return t.ts.Ping
	default:
		return nil
	}
}

func (t *waterReader) Stats() *WaterReaderStats {
	return t.stats
}

func (t *waterReader) describeState() string {
	switch currentState := atomic.LoadInt32(&t.state); currentState {
	case 1:
		return "already opened"
	case 2:
		return "already closed"
	default: // includes default 0
		return "not yet opened"
	}
}

func (t *waterReader) MustOpen() WaterReader {
	if t != nil {
		if e := t.Open(); e != nil {
			os.Exit(10)
		}
	}
	return t
}

func (t *waterReader) Open() error {
	if t == nil {
		return errors.New("waterReader.Open: ref is nil")
	}
	if t.TimescaleConnStr == "" {
		return logError("waterReader.Open: TimescaleConnStr string is empty")
	}
	if t.RedisConnStr == "" {
		return logError("waterReader.Open: RedisConnStr string is empty")
	}
	if !atomic.CompareAndSwapInt32(&t.state, 0, 1) { //ops
		return errors.New(logNotice("waterReader.Open: reader %v", t.describeState()))
	}

	t.ctx, t.ctxCancel = context.WithCancel(context.Background())
	var e error
	if t.ts, e = OpenPgSqlDb(t.TimescaleConnStr); e == nil {
		if t.redis, e = CreateRedisConnection(t.RedisConnStr); e == nil {
			if !t._tsDebug {
				t.stats.StartPrintStatsInterval() //side thread
			}
		}
	}

	if t.dynamodb, e = DynamoSingleton(); e != nil {
		return logError("Error opening dynamo session %v", e)
	}
	return e
}

func (t *waterReader) TSDB() *PgSqlDb {
	return t.ts
}

func (t *waterReader) GetCachedFirstRowTimeArchive() time.Time {
	return t.FirstArchive()
}

func (t *waterReader) GetCachedFirstRowTime() time.Time {
	return t.FirstWrite()
}

func (t waterReader) memoizeTimeQuery(name string, fallback time.Time, memo func() (time.Time, error)) func() time.Time {
	value := fallback
	validUntil := time.Now()
	valid := func() bool {
		return time.Now().Before(validUntil)
	}
	return func() time.Time {
		if valid() {
			return value
		}
		t.mux.Lock()
		defer t.mux.Unlock()

		if valid() {
			return value
		}

		newValue, err := memo()
		if err == nil {
			value = newValue
			validUntil = time.Now().Add(time.Duration(SEC_IN_2MIN) * time.Second)
			logTrace("MemoizeTimeQuery: updated %s to %v until %v", name, value, validUntil.Format("01-02 15:04:05"))
		}
		return value
	}
}

func (t *waterReader) Close() error {
	if t == nil {
		return errors.New("waterReader.Open: ref is nil")
	}
	if !atomic.CompareAndSwapInt32(&t.state, 1, 2) { //oopps
		return errors.New(logNotice("waterReader.Close: reader %v", t.describeState()))
	}

	defer t.ctxCancel()
	defer t.stats.StopPrintStatsInterval() //stop print thread
	if t.ts != nil {
		t.ts.Close()
		t.ts = nil
	}
	logInfo(t.stats.ResetSPrint())
	return nil
}

type WaterArchiveData map[string][]*WaterAggData

type WaterAggData struct {
	Bucket      time.Time
	Consumption float64
	Seconds     int32
	FlowSeconds int32
	Avg         WaterAggDataFunc
	Min         *WaterAggDataFunc
	Max         *WaterAggDataFunc
}

type WaterAggDataFunc struct {
	FlowRate float64
	Pressure float64
	Temp     float64
}

type WaterData struct {
	Bucket      time.Time // missing from DeviceData
	Consumption float64
	Seconds     int32 // missing from device data
	FlowSeconds int32 // missing from DeviceData
	FlowRate    float64
	Pressure    float64
	Temp        float64
}

func (w *WaterData) ToWaterUsage() *WaterUsage {
	if w == nil {
		return nil
	}
	o := WaterUsage{
		Date: w.Bucket.UTC(),
		Used: w.Consumption,
		Rate: w.FlowRate,
		PSI:  w.Pressure,
		Temp: w.Temp,
	}
	o.Missing = o.Temp == 0 && o.PSI == 0 && o.Rate == 0
	return &o
}

const SEC_IN_HR = 60 * 60
const SEC_IN_5MIN = 5 * 60
const SEC_IN_2MIN = 2 * 60

func (t *waterReader) GetWaterHourlyWithSem(did string, start time.Time, end time.Time, liveRequest bool) (res []*WaterData, e error) {
	if e = _semTs.Acquire(_ctxTs, 1); e != nil {
		_log.IfWarnF(e, "GetWaterHourlyWithSem: can't obtain lock for %v", did)
		time.Sleep(time.Millisecond * 66)
	} else {
		defer _semTs.Release(1)
	}
	return t.GetWaterHourly(did, start, end, liveRequest)
}

// GetWaterHourly combine live & semi-live data depending on date range
func (t *waterReader) GetWaterHourly(did string, start time.Time, end time.Time, liveRequest bool) (res []*WaterData, e error) {
	if t == nil {
		return nil, logError("waterReader.GetWaterHourly: is nil")
	}
	res = make([]*WaterData, 0)
	if !isValidMacAddress(did) {
		logInfo("waterReader.GetWaterHourly: bad mac address %v", did)
		return res, nil
	}
	start, end = start.UTC(), end.UTC()
	suu := timeBucketUnix(start.Unix(), SEC_IN_HR) //start utc unix
	euu := timeBucketUnix(end.Unix(), SEC_IN_HR)   //end utc unix
	if euu == suu {
		euu += SEC_IN_HR
		logNotice("waterReader.GetWaterHourly: end time %v equal start, adjusting to %v, swapping", start, time.Unix(euu, 0))
	} else if euu < suu {
		logNotice("waterReader.GetWaterHourly: end time %v is before start %v, swapping", end, start)
		end, start = start, end
	}

	//cutoff @ nearest -1hr + 5min (between 1-2hr). SEE: ../ts/hybrid.sql continuous aggregate schedule
	liveCut := timeBucketUnix(time.Now().UTC().Unix()-SEC_IN_5MIN, SEC_IN_HR) - (SEC_IN_HR * t.liveDataCutoffHr)
	_start := time.Unix(suu, 0).UTC()
	_end := time.Unix(euu, 0).UTC()
	_live := time.Unix(liveCut, 0).UTC()
	var w waterDataResult
	if suu < liveCut { //start is before cutoff
		if euu < liveCut { //end is before cutoff: everything is from hourly table
			w = t.getWaterHourlyAggregate(liveRequest, did, _start, _end)
			res = append(res, w.res...)
			e = w.er
		} else { //end is at or after cutoff
			hr := t.getWaterHourlyAggregate(liveRequest, did, _start, _live) //hourly data
			li := t.getWater5minAggregate(liveRequest, did, _live, _end)     //live aggregated live data, also in hourly
			liAgg := t.rollUpWater5minToHourly(li.res)
			res = append(res, hr.res...)
			res = append(res, liAgg...)
			if len(res) == 0 {
				sb := _log.sbPool.Get()
				defer _log.sbPool.Put(sb)

				if hr.er != nil {
					sb.WriteString(hr.er.Error())
					sb.WriteString(".\n")
				}
				if li.er != nil {
					sb.WriteString(li.er.Error())
					sb.WriteString(".\n")
				}
				if sb.Len() > 0 {
					e = errors.New(sb.String())
				}
			}
		}
	} else { //start is after or at cutoff: everything from 5min table
		w = t.getWater5minAggregate(liveRequest, did, _start, _end)
		res = t.rollUpWater5minToHourly(w.res)
		e = w.er
	}
	if e != nil {
		t.stats.IncrErrors()
	}
	return t.sortWaterData(res), e
}

func (t *waterReader) sortWaterData(res []*WaterData) []*WaterData {
	if len(res) != 0 {
		sort.Slice(res, func(i, j int) bool {
			return res[i].Bucket.Unix() < res[j].Bucket.Unix()
		})
	}
	return res
}

// do a floor of nearest time bucket based on bucket second size
func timeBucketUnix(unixTimeS int64, bucketS int64) int64 {
	return unixTimeS - (unixTimeS % bucketS)
}

// aggregate 5min chunks into hourly chunks
func (t *waterReader) rollUpWater5minToHourly(arr []*WaterData) []*WaterData {
	if len(arr) == 0 {
		return arr
	}
	hourly := make(map[int64][]*WaterData) // hourly bucketing
	for _, v := range arr {
		k := timeBucketUnix(v.Bucket.Unix(), SEC_IN_HR)
		hourly[k] = append(hourly[k], v)
	}

	res := make([]*WaterData, 0, len(hourly)) // compute aggregate
	for k, arr := range hourly {
		w := WaterData{}
		w.Bucket = time.Unix(k, 0)

		for _, o := range arr {
			w.Consumption += o.Consumption
			w.Seconds += o.Seconds
			w.FlowSeconds += o.FlowSeconds

			w.FlowRate += o.FlowRate * float64(o.FlowSeconds)
			w.Pressure += o.Pressure * float64(o.Seconds)
			w.Temp += o.Temp * float64(o.Seconds)
		}

		// still need to divide the sums to re-compute averages
		if w.FlowSeconds > 0 {
			w.FlowRate = w.FlowRate / float64(w.FlowSeconds)
		} else {
			w.FlowSeconds = 0
		}
		if fs := float64(w.Seconds); fs > 0 {
			w.Pressure = w.Pressure / fs
			w.Temp = w.Temp / fs
		} else {
			w.Pressure = 0
			w.Temp = 0
		}
		res = append(res, &w)
	}
	return res
}

func (t *waterReader) GetWaterHourlyFromArchiveWithSem(did string, start time.Time, end time.Time) ([]*WaterData, error) {
	if e := _semTs.Acquire(_ctxTs, 1); e != nil {
		_log.IfWarnF(e, "GetWaterHourlyFromArchiveWithSem: fail to obtain lock for %v", did)
		time.Sleep(time.Millisecond * 44)
	} else {
		defer _semTs.Release(1)
	}
	return t.GetWaterHourlyFromArchive(did, start, end)
}

// GetWaterHourlyFromArchive pull the archive data
func (t *waterReader) GetWaterHourlyFromArchive(did string, start time.Time, end time.Time) ([]*WaterData, error) {
	var resSlice []WaterArchiveDocumentRecord
	w := waterDataResult{}
	endNotInclusive := end.Add(-time.Second)

	w.er = t.dynamodb.GetByRange(ARCHIVE_TABLE_NAME,
		// id
		ARCHIVE_TABLE_HASH_FIELD, did,
		// range
		ARCHIVE_TABLE_RANGE_FIELD, start, endNotInclusive,
		//result
		&resSlice,
		// projections
		ARCHIVE_TABLE_RANGE_FIELD, "consumption", "seconds", "flow_seconds", "flow_rate", "pressure", "temp")
	for _, i := range resSlice {
		wd := WaterData{
			Bucket:      i.TimeBucket,
			Consumption: i.Consumption,
			FlowRate:    i.FlowRate,
			Seconds:     i.Seconds,
			FlowSeconds: i.FlowSeconds,
			Pressure:    i.Pressure,
			Temp:        i.Temp,
		}
		if wd.FlowSeconds < 0 {
			wd.FlowSeconds = 777 // data is missing and this value was chosen as fake value
		}
		w.res = append(w.res, &wd)
	}
	return t.sortWaterData(w.res), w.er
}

func (t *waterReader) GetDeviceFirstDataCached(noCache bool, deviceIds ...string) map[string]time.Time {
	rMap := t.getFirstDataMap(deviceIds)
	if !noCache {
		rMap = t.fetchDeviceFirstCache(rMap)
	}
	notCachedIds := t.getStringTimeMapKeys(rMap)
	if len(notCachedIds) > 0 {
		rMap = t.GetDeviceFirstData(rMap)
		notFoundIds := t.getStringTimeMapKeys(rMap)
		for _, id := range notFoundIds {
			delete(rMap, id)
		}
		go t.cacheDeviceFirstMisses(rMap, notCachedIds) //cache missed data
	}
	return rMap
}

func (t *waterReader) cacheDeviceFirstMisses(rMap map[string]time.Time, notCachedIds []string) {
	started := time.Now()
	nMap := t.makeFirstCacheKeyMap(notCachedIds)

	bc := 0
	saved := 0
	for k, arr := range nMap {
		c := batchLoop(arr, FD_CACHE_BATCH, func(ids []string) {
			vmap := make(map[string]interface{})
			for _, id := range ids {
				if dt, ok := rMap[id]; ok && dt.Year() > 2000 {
					vmap[id] = strconv.Itoa(int(dt.UTC().Unix()))
				}
			}
			if vl := len(vmap); vl > 0 {
				saved += vl
				cmd := t.redis._client.HMSet(k, vmap)
				if e := cmd.Err(); e != nil {
					logError("waterReader.cacheDeviceFirstMisses: %v", e.Error())
				}
			}
		})
		if c > 0 {
			bc += c
			//go t.redis._client.Expire(k, time.Hour*24*7)
		}
	}
	logDebug("waterReader.cacheDeviceFirstMisses: %vs for %v devices. %v batches", time.Since(started).Seconds(), saved, bc)
}

func (t *waterReader) firstDataCacheKey(did string) string {
	return fmt.Sprintf("watermeter:{%v}:map2:firstdata", did)
}

func batchLoop(keys []string, batchSize int, batchExec func(batch []string)) int {
	kl := len(keys)
	bn := int(math.Ceil(float64(kl) / float64(batchSize)))
	b := 0
	for ; b < bn; b++ {
		if atomic.LoadInt32(&cancel) > 0 {
			return b
		}
		tail := (b + 1) * batchSize
		if tail > kl {
			tail = kl
		}
		batch := keys[b*batchSize : tail]
		batchExec(batch)
	}
	return b
}

func (t *waterReader) makeFirstCacheKeyMap(deviceIds []string) map[string][]string {
	nMap := make(map[string][]string)
	for _, id := range deviceIds {
		n := t.firstDataCacheKey(id[0:2])
		arr := nMap[n]
		if len(arr) == 0 {
			nMap[n] = []string{id}
		} else {
			nMap[n] = append(arr, id)
		}
	}
	return nMap
}

const FD_CACHE_BATCH = 10

func (t *waterReader) fetchDeviceFirstCache(rMap map[string]time.Time) map[string]time.Time {
	if t == nil {
		return rMap
	}
	started := time.Now()
	deviceIds := t.getStringTimeMapKeys(rMap)
	nMap := t.makeFirstCacheKeyMap(deviceIds)

	bc := 0
	for k, arr := range nMap {
		bc += batchLoop(arr, FD_CACHE_BATCH, func(ids []string) {
			cmd := t.redis._client.HMGet(k, ids...)
			if pArr, e := cmd.Result(); e != nil { //device time pair array
				logError("waterReader.fetchDeviceFirstCache: %v -> %v => %v", k, ids, e.Error())
				return
			} else if len(pArr) > 0 {
				for i, v := range pArr {
					if v == nil {
						continue
					}
					vs := fmt.Sprint(v)
					if n, e := strconv.Atoi(vs); e == nil && n > 0 {
						if dt := time.Unix(int64(n), 0).UTC(); dt.Year() > 2000 {
							id := ids[i]
							rMap[id] = dt
						}
					}
				}
			}
		})
	}
	logDebug("waterReader.fetchDeviceFirstCache: %vs for %v devices. %v batches", time.Since(started).Seconds(), len(deviceIds), bc)
	return rMap
}

func (t *waterReader) GetDeviceFirstData(rMap map[string]time.Time) map[string]time.Time {
	var (
		hourlyQuery = "select device_id,min(bucket) as bucket from water_hourly where device_id in ('%v') and bucket > '2017-03-02' group by device_id;"
	)
	if FD_QUERY_BATCH == 1 {
		hourlyQuery = "select min(h.bucket) as bucket from water_hourly h where h.device_id = '%v' and h.bucket > '2017-03-02';"
	}
	rMap = t.queryArchiveDeviceFirstData(rMap)
	rMap = t.queryDeviceFirstData("hourly", hourlyQuery, rMap) // TODO queryDeviceFirstData makes sense only for this function now, maybe merge them
	return rMap
}

func (t *waterReader) getFirstDataMap(deviceIds []string) map[string]time.Time {
	mm := make(map[string]time.Time)
	for _, id := range deviceIds {
		mm[id] = time.Unix(0, 0)
	}
	return mm
}

func (t *waterReader) getStringTimeMapKeys(mm map[string]time.Time) []string {
	var keys = make([]string, 0, len(mm))
	for k, v := range mm {
		if v.Year() <= 2000 {
			keys = append(keys, k)
		}
	}
	return keys
}

var FD_QUERY_BATCH = 5
var CLIENT_AGG = false

func init() {
	const (
		FLO_FD_QUERY_BATCH = "FLO_FD_QUERY_BATCH"
		FLO_CLIENT_AGG     = "FLO_CLIENT_AGG"
	)
	if n, _ := strconv.Atoi(getEnvOrDefault(FLO_FD_QUERY_BATCH, "")); n > 0 {
		FD_QUERY_BATCH = n
	}
	CLIENT_AGG = strings.EqualFold(getEnvOrDefault(FLO_CLIENT_AGG, ""), "true")
	_log.Notice("%s=%v", FLO_FD_QUERY_BATCH, FD_QUERY_BATCH)
	_log.Notice("%s=%v", FLO_CLIENT_AGG, CLIENT_AGG)
}

func (t *waterReader) semQueryNoArgs(q string) (*sql.Rows, error) {
	if e := t.semBg.Acquire(t.ctx, 1); e != nil {
		_log.IfWarnF(e, "semQueryNoArgs: failed to obtain lock for %v", q)
		time.Sleep(time.Millisecond * 44)
	} else {
		defer t.semBg.Release(1)
	}
	return t.ts.Connection.Query(q)
}

func (t *waterReader) queryArchiveDeviceFirstData(deviceMap map[string]time.Time) map[string]time.Time {

	if len(deviceMap) == 0 {
		return deviceMap
	}
	deviceIds := t.getStringTimeMapKeys(deviceMap)
	if len(deviceIds) == 0 {
		return deviceMap
	}

	for _, deviceId := range deviceIds {
		var res WaterArchiveDocumentRecord
		did := macAddressSimpleFormat(deviceId)
		err := t.dynamodb.GetFirst(ARCHIVE_TABLE_NAME, ARCHIVE_TABLE_HASH_FIELD, did, &res)

		if err != nil {
			if strings.Contains(err.Error(), "no item found") {
				logDebug("waterReader.queryArchiveDeviceFirstData: %v => %v", did, err.Error())
			} else {
				logWarn("waterReader.queryArchiveDeviceFirstData: %v => %v", did, err.Error())
			}
			continue
		}
		when := res.TimeBucket
		if _, ok := deviceMap[did]; ok && when.Year() > 2000 {
			deviceMap[did] = when.UTC()
		}
	}
	return deviceMap
}

func (t *waterReader) queryDeviceFirstData(name, query string, deviceMap map[string]time.Time) map[string]time.Time {
	if t == nil {
		return deviceMap
	}
	started := time.Now()
	if query == "" || len(deviceMap) == 0 {
		return deviceMap
	}
	deviceIds := t.getStringTimeMapKeys(deviceMap)
	if len(deviceIds) == 0 {
		return deviceMap
	}
	bc := batchLoop(deviceIds, FD_QUERY_BATCH, func(batch []string) {
		if t == nil {
			return
		}
		q := fmt.Sprintf(query, strings.Join(batch, "','"))
		rows, err := t.semQueryNoArgs(q)
		if err != nil {
			logWarn("waterReader.queryDeviceFirstData: %v query %v => %v", name, batch, err.Error())
			return
		}
		defer rows.Close()
		for rows.Next() {
			var (
				did  string
				when sql.NullTime
				e    error
			)
			if FD_QUERY_BATCH == 1 {
				did = batch[0]
				e = rows.Scan(&when)
			} else {
				e = rows.Scan(&did, &when)
			}
			if e != nil {
				logWarn("waterReader.queryDeviceFirstData: %v scan %v => %v", name, batch, e.Error())
				continue
			}
			did = macAddressSimpleFormat(did)
			if _, ok := deviceMap[did]; ok && when.Valid && when.Time.Year() > 2000 {
				deviceMap[did] = when.Time.UTC()
			}
		}
	})
	logDebug("waterReader.queryDeviceFirstData: %vms for %v devices, %v batches", time.Since(started).Milliseconds(), len(deviceIds), bc)
	return deviceMap
}

// GetFirstRowTimeArchive return earliest known row of archive data
func (t *waterReader) GetArchiveStartTime() (time.Time, error) {
	return t.getAttributeAsDate(WATER_METER_ATTRIBUTE_ARCHIVE_START)
}

// GetArchiveEndTime returns the time of when the archive stop (copying data to Dynamo from TSDB)
func (t *waterReader) GetArchiveEndTime() (time.Time, error) {
	return t.getAttributeAsDate(WATER_METER_ATTRIBUTE_ARCHIVE_END)
}

// GetLiveDataStartTime returns the date for when TSDB data should be used as the source of truth (from this date to now)
func (t *waterReader) GetLiveDataStartTime() (time.Time, error) {
	return t.getAttributeAsDate(WATER_METER_ATTRIBUTE_LIVE_START)
}

func (t *waterReader) getAttributeAsDate(attr string) (time.Time, error) {
	var res time.Time
	rows, err := t.ts.Connection.Query("select attr_val from water_meter_attr where attr_id = $1 limit 1", attr)
	if err != nil {
		return res, logWarn("getAttributeAsDate query failed, %v", err.Error())
	}
	defer rows.Close()
	for rows.Next() {
		var value string
		err = rows.Scan(&value)
		if err != nil {
			return time.Time{}, logWarn("getAttributeAsDate scan failed, %v", err.Error())
		}
		res, err = time.Parse(STD_DATE_LAYOUT, value)
		if err != nil {
			return time.Time{}, err
		}
	}
	return res, nil
}

// fetch hourly aggregated buckets (pre-computed data by TS)
func (t *waterReader) getWaterHourlyAggregate(live bool, args ...interface{}) waterDataResult {
	wr := t.queryWaterData(
		live,
		"hourly",
		t.parseWaterResultRow,
		`select bucket, total_gallon, seconds, seconds_flo, gpm_avg, psi_avg, temp_avg 
		from water_hourly where device_id = $1 and (bucket >= $2 and bucket < $3);`,
		args...)
	return wr
}

func (t *waterReader) parseWaterResultRow(rows *sql.Rows) (*WaterData, error) {
	d := WaterData{}
	e := rows.Scan(&d.Bucket, &d.Consumption, &d.Seconds, &d.FlowSeconds, &d.FlowRate, &d.Pressure, &d.Temp)
	return &d, e
}

func (t *waterReader) GetArchiveableRows(startTime time.Time, endTime time.Time, offset, limit int) WaterArchiveData {
	const query = `select device_id, bucket, total_gallon, seconds, seconds_flo, 
	gpm_avg, psi_avg, temp_avg, 
	gpm_min_flo, psi_min, temp_min, 
	gpm_max, psi_max, temp_max
	from water_hourly where (bucket between $1 and $2) order by bucket limit $3 offset $4;`

	rows, err := t.ts.Query(query, startTime, endTime, limit, offset)
	if err != nil {
		logError("waterReader: GetArchiveableRows failed query %v", err.Error())
		return nil
	}
	defer rows.Close()
	ret := make(map[string][]*WaterAggData)
	for rows.Next() {
		did, n, er := t.parseWaterArchiveResultRow(rows)
		if er != nil {
			logError("waterReader: GetArchiveableRows failed scan %v", err.Error())
			return nil
		}
		ret[did] = append(ret[did], n)
	}
	return ret
}

func (t *waterReader) parseWaterArchiveResultRow(rows *sql.Rows) (string, *WaterAggData, error) {
	d := WaterAggData{}
	d.Min = &WaterAggDataFunc{}
	d.Max = &WaterAggDataFunc{}
	var deviceId string
	e := rows.Scan(&deviceId, &d.Bucket, &d.Consumption, &d.Seconds, &d.FlowSeconds,
		&d.Avg.FlowRate, &d.Avg.Pressure, &d.Avg.Temp,
		&d.Min.FlowRate, &d.Min.Pressure, &d.Min.Temp,
		&d.Max.FlowRate, &d.Max.Pressure, &d.Max.Temp,
	)
	return macAddressSimpleFormat(deviceId), &d, e
}

// fetch 5minutely aggregated buckets (semi-live data in TS)
func (t *waterReader) getWater5minAggregate(live bool, args ...interface{}) waterDataResult {
	var stmt = `select bk, total_gallon, seconds, seconds_flo,		
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
		from water_5min where device_id = $1 and (bk >= $2 and bk < $3);`
	if CLIENT_AGG {
		stmt = `select bk, total_gallon, seconds, seconds_flo, 
				gpm_sum, psi_sum, temp_sum
			from water_5min where device_id = $1 and (bk >= $2 and bk < $3);`
	}
	wr := t.queryWaterData(
		live,
		"5min",
		t.parseWaterResultRow,
		stmt,
		args...)
	if CLIENT_AGG && len(wr.res) != 0 {
		for _, r := range wr.res {
			if r.FlowSeconds > 0 {
				r.FlowRate /= float64(r.FlowSeconds)
			}
			if r.Seconds > 0 {
				sec := float64(r.Seconds)
				r.Pressure /= sec
				r.Temp /= sec
			}
		}
	}
	return wr
}

type waterDataResult struct {
	did    string
	res    []*WaterData
	er     error
	tookMs float32
}

// regular query ops, ensure sem is cleanup correctly everytime
func (t *waterReader) semQuery(liveRequest bool, query string, params ...interface{}) (*sql.Rows, error) {
	if liveRequest { //ensure proper limit of concurrent db read requests based on usage input
		if e := t.semLive.Acquire(t.ctx, 1); e != nil {
			_log.IfWarnF(e, "semQuery: fail to obtain lock for live=%v query: %v", liveRequest, query)
			time.Sleep(time.Millisecond * 50) //sleep a little
		} else {
			defer t.semLive.Release(1)
		}
	} else {
		if e := t.semBg.Acquire(t.ctx, 1); e != nil {
			_log.IfWarnF(e, "semQuery: fail to obtain lock for live=%v query: %v", liveRequest, query)
			time.Sleep(time.Millisecond * 100)
		} else {
			defer t.semBg.Release(1)
		}
	}
	return t.ts.Connection.Query(query, params...)
}

func (t *waterReader) queryWaterData(
	liveRequest bool,
	queryName string,
	readWaterData func(*sql.Rows) (*WaterData, error),
	query string,
	params ...interface{}) waterDataResult {
	if t == nil {
		return waterDataResult{}
	}
	w := waterDataResult{}
	if len(params) > 0 {
		w.did = strings.ToLower(fmt.Sprintf("%v", params[0])) // to string
	}

	t.stats.IncrQueries()
	started := time.Now()
	if atomic.LoadInt32(&cancel) > 0 || t == nil || t.ts == nil || t.ts.Connection == nil {
		return waterDataResult{}
	}
	rows, e := t.semQuery(liveRequest, query, params...)
	if e != nil {
		w.er = logWarn("waterReader.queryWaterData: %v %v => %v", queryName, params, e.Error())
		return w
	}
	defer rows.Close()

	w.res = nil
	var i int64 = 0
	for rows.Next() {
		var d *WaterData
		d, e = readWaterData(rows)
		if e != nil {
			w.er = logWarn("waterReader.queryWaterData: %v row read error: %v => %v", queryName, params, e.Error())
			continue
		}
		if w.res == nil {
			w.res = make([]*WaterData, 0, 24) //this is the size for most of the time for when there are data, it can expand if required
		}
		w.res = append(w.res, d)
		i++
	}
	w.tookMs = float32(time.Since(started).Milliseconds())
	t.stats.IncrRows(i)
	t.stats.IncrQueryDuration(float64(w.tookMs))

	e = rows.Err()
	if e != nil {
		w.er = logWarn("waterReader.queryWaterData: %v row loop error: %v => %v", queryName, params, e.Error())
	}
	if w.er != nil && len(w.res) > 0 {
		w.er = nil
	}
	logTrace("waterReader.queryWaterData: %v OK %vms %v => %v rows", queryName, w.tookMs, params, i)
	return w
}
