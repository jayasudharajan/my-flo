package main

import (
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"
	"time"
)

const (
	AUDIT_MUTEX_TIMEOUT_SEC int = 3600 //60 minutes
	//MAX_DAYS_REPORT int = 398 //~13 months
	//MAX_DAYS_REPORT int = 1130         //about 37 months rounded up
)

var MAX_DAYS_REPORT = 398 //~13 months

func init() {
	if days, _ := strconv.ParseInt(getEnvOrDefault("FLO_MAX_DAYS_REPORT", "398"), 10, 64); days > 0 {
		MAX_DAYS_REPORT = int(days)
	}
	_log.Notice("MAX_DAYS_REPORT=%v", MAX_DAYS_REPORT)
}

// auditDeviceCache ensures there is cache data, does not refresh data if cache already contains data
func auditDeviceCache(macAddress string, fromDate time.Time, toDate time.Time, source string, force bool) {
	logDebug("auditDeviceCache: Requested for %v from %v to %v source %v force %v",
		macAddress, fromDate.Format("2006-01-02"), toDate.Format("2006-01-02"), source, force)

	macAddress = strings.ToLower(macAddress)
	if !force { // Prevent multiple requests to the same device and same day. Grab an exclusive lock for 50 minutes
		lockKey := fmt.Sprintf("mutex:watermeter:audit:{%v}", macAddress)
		ok, _ := _cache.SetNX(lockKey, _hostName, AUDIT_MUTEX_TIMEOUT_SEC)
		if !ok {
			logTrace("auditDeviceCache: Mutex Exists: '%v'", lockKey)
			return
		} else {
			logTrace("auditDeviceCache: Mutex Acquired: '%v'", lockKey)
		}
	}

	current := fromDate
	for current.Before(toDate) {
		us := current.Format("01-02T15")
		if atomic.LoadInt32(&cancel) > 0 {
			return
		}
		redisKey := genRedisKey(macAddress, current)
		rdata, err := _cache.HGetAll(redisKey)

		if err != nil {
			logWarn("auditDeviceCache: %v %v", redisKey, err.Error())
		} else {
			found, ok := rdata[current.Format("2006-01-02")]
			isInvalid := !ok || len(found) < 90
			if isInvalid { // Not found or the data appears invalid
				atomic.AddInt64(&_qSize, 1)
				go cacheDeviceConsumption(macAddress, current, source, "auditDeviceCache: NotFound "+us)
			} else {
				items := strings.Split(found, ",")
				isPartial := len(items) < 96
				if isPartial { // Not enough records, partial result?
					atomic.AddInt64(&_qSize, 1)
					go cacheDeviceConsumption(macAddress, current, source, "auditDeviceCache: Incomplete "+us)
				}
			}
		}
		current = current.Add(time.Hour * 24)
		backOffHighQueue()
	}
	return
}

func backOffHighQueue() {
	q := atomic.LoadInt64(&_qSize)
	if q > 1000 {
		time.Sleep(time.Second)
	} else if q > 250 {
		time.Sleep(time.Millisecond * 100)
	} else if q > 100 {
		time.Sleep(time.Millisecond * 1)
	}
}

func auditDeviceLongTermCache(firstRec time.Time, macAddress string, source string, force bool) {
	if firstRec.Year() <= 2000 {
		totalDur := time.Duration(24*MAX_DAYS_REPORT*-1) * time.Hour
		earliestStart := time.Now().UTC().Add(totalDur)
		if firstRec.Year() < 2000 {
			firstRec = time.Now().UTC().Add(time.Hour * 24 * 31 * -1)
		}
		//cafr := tsWaterReader.GetCachedFirstRowTimeArchive()
		//if tsWaterReader != nil && firstRec.After(cafr) { //fall back to TS
		//	firstRec = cafr
		//}
		rrm := NewPurgeRedisTask(nil, _cache, nil)
		if lastRm := rrm.getLastRm(); firstRec.Before(lastRm) {
			firstRec = lastRm
		}
		if firstRec.Before(earliestStart) {
			firstRec = earliestStart
		}
	} else {
		firstRec = firstRec.UTC()
	}
	logDebug("auditDeviceLongTermCache: Audit device %v starting on %v", macAddress, firstRec.Format(time.RFC3339))
	auditDeviceCache(macAddress, firstRec, time.Now().UTC(), source, force)
}
