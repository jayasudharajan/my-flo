package main

import (
	"bytes"
	"compress/gzip"
	"context"
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"golang.org/x/sync/semaphore"
)

const DEFAULT_MUTEX_TIMEOUT int = 15
const INFLUX_MISSING_DATA_VALUE float64 = -1000

type DeviceData struct {
	Consumption float64
	FlowRate    float64
	Pressure    float64
	Temp        float64
}

func ensure24HoursData(startDt time.Time, rawData []*WaterData) []*WaterData {
	if len(rawData) == 24 {
		return rawData
	}
	dMap := make(map[int64]*WaterData)
	for _, v := range rawData {
		k := v.Bucket.UTC().Unix()
		dMap[k] = v
	}

	res := make([]*WaterData, 24)
	dt := startDt.Unix()
	for i := 0; i < 24; i++ {
		if v, ok := dMap[dt]; ok {
			res[i] = v
		} else {
			res[i] = &WaterData{Bucket: time.Unix(dt, 0).UTC()}
		}
		dt += SEC_IN_HR
	}
	return res
}

func convWaterDataToUsage(data []*WaterData) []DeviceData {
	res := make([]DeviceData, 0, len(data))
	for _, v := range data {
		o := DeviceData{}
		o.Consumption = v.Consumption
		o.FlowRate = v.FlowRate
		o.Pressure = v.Pressure
		o.Temp = v.Temp
		res = append(res, o)
	}
	return res
}

var _semCache = semaphore.NewWeighted(10) //reduce bottle necks on redis
var _ctxCache = context.Background()
var _semTs = semaphore.NewWeighted(2) //reduce bottle necks on ts
var _ctxTs = context.Background()
var _mxExistsCounter int64 = 0
var _qSize int64 = 0

func cacheDurCalc(utcDate time.Time) int {
	expiration := DEFAULT_MUTEX_TIMEOUT
	if durDiff := time.Now().UTC().Sub(utcDate); durDiff >= DUR_31_DAYS {
		expiration = SEC_IN_HR * 3
	} else if durDiff >= DUR_1_WEEK {
		expiration = SEC_IN_5MIN * 3
	} else if durDiff >= DUR_1_DAY {
		expiration = SEC_IN_5MIN
	}
	return expiration
}

func cacheLockObtain(lockKey string, expirationS int) (bool, error) {
	_semCache.Acquire(_ctxCache, 1)
	defer _semCache.Release(1)
	return _cache.SetNX(lockKey, _hostName, expirationS)
}

func waterCacheLockKey(mac string, day time.Time) string {
	k := fmt.Sprintf("mutex:watermeter:{%v}:%v",
		strings.ToLower(strings.TrimSpace(mac)),
		day.UTC().Truncate(DUR_1_DAY).Format("2006-01-02"))
	if _log.isDebug && _noWrite {
		k += ":debug"
	}
	return k
}

// logic that writes water data to redis
func cacheDeviceConsumption(macAddress string, utcDate time.Time, source string, note string) error {
	if atomic.LoadInt32(&cancel) > 0 {
		return nil
	}
	callDt := time.Now()
	defer recoverPanic(_log, "cacheDeviceConsumption: %v %v via %v | %v", macAddress, utcDate.Format(time.RFC3339), source, note)
	if !isValidMacAddress(macAddress) {
		return logError("cacheDeviceConsumption: macAddress arg invalid. %v q=%v. src=%v note=%v", macAddress, atomic.AddInt64(&_qSize, -1), source, note)
	} else if utcDate.Year() < 2017 || utcDate.Year() > 2038 {
		return logError("cacheDeviceConsumption: utcDate arg invalid. %v q=%v", utcDate, atomic.AddInt64(&_qSize, -1))
	}

	if len(source) == 0 {
		source = "default"
	}
	utcDate = utcDate.Truncate(DUR_1_DAY)
	var (
		cleanMac   = strings.ToLower(strings.TrimSpace(macAddress)) // Clean input
		lockKey    = waterCacheLockKey(cleanMac, utcDate)
		expiration = cacheDurCalc(utcDate)
		ok, err    = cacheLockObtain(lockKey, expiration)
	)
	if !ok { // Prevent multiple requests to the same device and same day. Grab an exclusive lock for 10 seconds
		mc := atomic.AddInt64(&_mxExistsCounter, 1)
		if mc%100 == 0 {
			logDebug("cacheDeviceConsumption: Mutex Exists: %v q=%v _mxExistsCounter=%v", lockKey, atomic.AddInt64(&_qSize, -1), mc)
		} else {
			logTrace("cacheDeviceConsumption: Mutex Exists: %v q=%v _mxExistsCounter=%v", lockKey, atomic.AddInt64(&_qSize, -1), mc)
		}
		return nil
	}

	var (
		waterUse   []DeviceData
		dbUsed     string
		actualRows = 0
		endDt      = utcDate.Add(time.Hour * 24).UTC()
		rawData    []*WaterData
	)
	tsWaterReader.Stats().IncrAttempts()
	if utcDate.Unix() < tsWaterReader.GetCachedFirstRowTime().Unix() { //archived data
		dbUsed = "TSA"
		rawData, err = tsWaterReader.GetWaterHourlyFromArchiveWithSem(cleanMac, utcDate, endDt)
		actualRows = len(rawData)
	} else { // live or semi-live data
		dbUsed = "TS"
		rawData, err = tsWaterReader.GetWaterHourlyWithSem(cleanMac, utcDate, endDt, source == SOURCE_PRESENCE_NAME)
		actualRows = len(rawData)
	}
	if err == nil {
		patchedData := ensure24HoursData(utcDate, rawData)
		waterUse = convWaterDataToUsage(patchedData)
		if dbUsed == "TSA" {
			tsWaterReader.Stats().IncrTsACount()
		} else {
			tsWaterReader.Stats().IncrTsCount()
		}
	}
	if err != nil {
		return logError("cacheDeviceConsumption: did %v on %v. q=%v Stats DB Error => %v",
			macAddress, utcDate.Format("2006-01-02"), atomic.AddInt64(&_qSize, -1), err.Error())
	} else if len(waterUse) != 24 {
		return logWarn("cacheDeviceConsumption: did %v on %v. Hour array contains <24 items. q=%v wlen=%v",
			macAddress, utcDate.Format("2006-01-02"), atomic.AddInt64(&_qSize, -1), len(waterUse))
	}

	m := buildRedisMap(utcDate, source, waterUse)
	err = writeRedisMap(cleanMac, utcDate, m)
	if err != nil {
		return logError("cacheDeviceConsumption: %v did %v on %v. q=%v Error => %v",
			dbUsed, macAddress, utcDate.Format("2006-01-02"), atomic.AddInt64(&_qSize, -1), err.Error())
	}
	logDebug("cacheDeviceConsumption: did %v %vms Cached %v. q=%v rr=%v src:%v %v",
		dbUsed, time.Since(callDt).Milliseconds(), macAddress, atomic.AddInt64(&_qSize, -1), actualRows, source, note)
	return nil
}

func writeRedisMap(mac string, utcDate time.Time, m map[string]interface{}) error {
	if _log.isDebug && _noWrite {
		return nil
	}
	key := genRedisKey(mac, utcDate)
	if e := _semCache.Acquire(_ctxCache, 1); e != nil {
		_log.IfWarnF(e, "writeRedisMap: can't obtain lock for %v %v", mac, utcDate)
		time.Sleep(time.Millisecond * 33)
	} else {
		defer _semCache.Release(1)
	}
	ttl := 60 * 60 * 24 * 366 //1 year by default
	_, err := _cache.HMSet(key, m, ttl)
	return err
}

const FMT_RED_MAP_LASTDT = "2006-01-02T15:04:05Z"

func buildRedisMap(utcDate time.Time, source string, waterUse []DeviceData) map[string]interface{} {
	val := buildRedisMapValue(waterUse)
	return map[string]interface{}{
		"latestUpdate":               time.Now().UTC().Format(FMT_RED_MAP_LASTDT),
		"latestSource":               "flo-water-meter:" + source,
		utcDate.Format("2006-01-02"): val,
	}
}

func buildRedisMapValue(waterUse []DeviceData) interface{} {
	// Clean the data
	delta := make([]string, 96)
	for i, v := range waterUse {
		delta[i] = getCsvEntry(v.Consumption, 3)
		delta[i+24] = getCsvEntry(v.FlowRate, 4)
		delta[i+48] = getCsvEntry(v.Pressure, 1)
		delta[i+72] = getCsvEntry(v.Temp, 1)
	}
	s := strings.Join(delta, ",")

	buf := &bytes.Buffer{}
	zw := gzip.NewWriter(buf)
	_, e := zw.Write([]byte(s))
	if e != nil {
		zw.Close()
		return s //return the regular string
	}
	e = zw.Close()
	if e != nil {
		return s
	}
	return buf.String() //return gz buffer. Testing shows 55% space reduction in raw bytes & 40% reduction if base64 is used
}

func getCsvEntry(val float64, decimalCount int) string {
	if val == INFLUX_MISSING_DATA_VALUE {
		return ""
	} else if val <= 0.001 {
		return "0"
	} else {
		return fmt.Sprintf("%."+strconv.Itoa(decimalCount)+"f", val)
	}
}

func genRedisKey(macAddress string, firstOfMonth time.Time) string {
	macAddress = strings.ToLower(macAddress)
	k := fmt.Sprintf("watermeter:{%v}:%v-01", macAddress, firstOfMonth.Format("2006-01"))
	if _log.isDebug && _noWrite {
		if getEnvOrDefault("FLO_DISABLE_BG_SERVICES", "") != "true" {
			k = strings.Replace(k, "watermeter:", "watermeter:debug:", 1)
		}
	}
	return k
}
