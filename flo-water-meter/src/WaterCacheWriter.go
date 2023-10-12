package main

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/go-redis/redis"
)

type WaterCacheWriter interface {
	Remove(rq *RemoveDataReq) (int, error)
	RemoveOldCache(dateExp string) int
	//TODO: move the redis write ops from cacheDeviceConsumption.go here to cleanup caching code
}

type waterCacheWriter struct {
	red *RedisConnection
	log *Logger
}

func CreateWaterCacheWriter(red *RedisConnection, log *Logger) WaterCacheWriter {
	return &waterCacheWriter{
		red,
		log.CloneAsChild("H2o$Write"),
	}
}

func (cw *waterCacheWriter) RemoveOldCache(dateExp string) int {
	defer recoverPanic(cw.log, "RemoveOldCache: %v", dateExp)
	cw.log.PushScope("RmOld$")
	defer cw.log.PopScope()

	if dateExp == "" {
		dateExp = "2020-*"
	}
	var (
		started        = time.Now()
		dup            = make(map[string]bool)
		fetches int64  = 0
		rems    int64  = 0
		cursor  uint64 = 0
		match          = "watermeter:{????????????}:" + dateExp
	)
	cw.log.Notice("BEGIN_RM %v", match)
	defer func(st time.Time, m string, f, r *int64) {
		cw.log.Notice("ALL_DONE %v fetches:%v removed:%v took:%v", m, *f, *r, time.Since(st).String())
	}(started, match, &fetches, &rems)

	for fetches == 0 || cursor != 0 {
		fetches++
		cmd := cw.red._client.Scan(cursor, match, 200)

		if keys, cur, e := cmd.Result(); e != nil && e != redis.Nil {
			cw.log.IfErrorF(e, "scan: %v %q %v", cursor, match, 100)
			break
		} else {
			cursor = cur
			for _, k := range keys {
				if s, _ := mh3Bytes([]byte(k)); s != "" {
					if _, found := dup[s]; found {
						continue //duplicated
					}
					dup[s] = true
				}
				rmCmd := cw.red._client.Del(k)
				if n, re := rmCmd.Result(); re != nil {
					cw.log.IfErrorF(e, "del %q", k)
				} else {
					rems += n
				}
			}
		}
		if fetches%100 == 0 {
			cw.log.Info("PROGRESS fetches:%v removed:%v", fetches, rems)
		}
	}
	return int(rems)
}

func (cw *waterCacheWriter) Remove(rq *RemoveDataReq) (int, error) {
	if cw == nil {
		return 0, cw.log.Error("Remove: ref is nil")
	} else if rq == nil {
		return 0, cw.log.Warn("Remove: rq is nil")
	}

	const lockTTL = 60 * 60 * 3 //lock cache write for these devices until hourly data rolls up is 100% done
	var (
		rems   = 0
		ops    = 0
		rmKeys = rq.buildCacheRmKeys()
		es     = make([]error, 0)
		rmv    = "RM-" + time.Now().UTC().Format(time.RFC3339)
	)
	for _, rs := range rmKeys {
		rmOK := false
		rems += len(rs.days)
		ops++
		if rs.fullMonth { //rm entire month hashmap
			if rq.DryRun {
				cw.log.Info("Remove: dry run %v | _cache.Delete(`%v`)", rq.MacAddr, rs.key)
			} else if _, e := _cache.Delete(rs.key); e != nil && e != redis.Nil {
				es = append(es, cw.log.IfWarnF(e, "cache '%v' rm failed", rs.key))
				rems -= len(rs.days)
			} else {
				rmOK = true
			}
		} else { //rm individual key within month
			if rq.DryRun {
				cw.log.Info("Remove: dry run %v | _cache.HDelete(`%v`, %v)", rq.MacAddr, rs.key, rs.days)
			} else if e := _cache.HDelete(rs.key, rs.days...); e != nil && e != redis.Nil {
				es = append(es, cw.log.IfWarnF(e, "cache '%v' rm failed for keys %v", rs.key, rs.days))
				rems -= len(rs.days)
			} else {
				rmOK = true
			}
		}
		if rmOK { //ensure pre-cache for this bucket doesn't build in the next 2hrs until hourly rollup is done
			for i, _ := range rs.days {
				var (
					dt = rs.Day(i)
					lk = waterCacheLockKey(rq.MacAddr, dt)
				)
				if _, e := _cache.Set(lk, rmv, lockTTL); e != nil { //prevent cache rebuild until hourly rollup happens
					cw.log.IfWarnF(e, "Remove: lockTTL %s", lk)
				}
			}
		}
	}
	if ops > 0 {
		if pct := float64(len(es)) / float64(ops); pct > 0.3 { //30% err pct
			if e := wrapErrors(es); e != nil {
				return rems, cw.log.IfErrorF(e, "Remove: failed | %v percent error", pct*100)
			}
		}
	}
	if !rq.DryRun {
		cw.log.Info("Remove: %v items OK %v | %v -> %v", rems, rq.MacAddr, rq.StartDate, rq.EndDate)
	}
	return rems, nil
}

type RemoveDataReq struct {
	MacAddr   string    `json:"-"`
	StartDate time.Time `json:"startDate,omitempty"`
	EndDate   time.Time `json:"endDate,omitempty"`
	DryRun    bool      `json:"dryRun"`
	ReCompute bool      `json:"reCompute"`
}

func (rq *RemoveDataReq) Validate() error {
	if rq == nil {
		return errors.New("ref is nil")
	} else if !isValidMacAddress(rq.MacAddr) {
		return &HttpErr{Code: 400, Message: "id is not a valid macAddr: " + rq.MacAddr}
	} else if !(rq.StartDate.Year() > 2000 || rq.EndDate.Year() > 2000) {
		return &HttpErr{Code: 400, Message: "a valid start or end date is required"}
	}
	return nil
}

func (rq *RemoveDataReq) Normalize() *RemoveDataReq {
	if rq != nil {
		if rq.StartDate.Year() < 2000 {
			rq.StartDate, _ = time.Parse(FMT_DAY_ONLY, "2015-01-01")
		}
		if rq.EndDate.Year() < 2000 {
			rq.EndDate = time.Now().UTC()
		}
	}
	return rq
}

func (rq *RemoveDataReq) String() string {
	return fmt.Sprintf("%s:%s|%s:%v", rq.MacAddr, rq.StartDate.Format(time.RFC3339), rq.EndDate.Format(time.RFC3339), rq.DryRun)
}

const FMT_DAY_ONLY = "2006-01-02"

type rmCacheSet struct {
	key       string
	days      []string
	fullMonth bool
}

func (rs *rmCacheSet) Day(i int) time.Time {
	if rs != nil && i >= 0 && i < len(rs.days) {
		d, _ := time.ParseInLocation(FMT_DAY_ONLY, rs.days[i], time.UTC)
		return d
	}
	return time.Time{}
}

func (rq *RemoveDataReq) buildCacheRmKeys() []*rmCacheSet {
	var (
		kMap   = make(map[string]*rmCacheSet) //collect array by month
		curDay = rq.StartDate.UTC().Truncate(DUR_1_DAY)
		endUx  = rq.EndDate.Unix()
	)
	if curDay.Unix() == endUx { //at least run for today
		endUx += 1
	}
	for curDay.Unix() < endUx {
		var (
			curMonth, _ = time.ParseInLocation(FMT_DAY_ONLY, curDay.Format("2006-01")+"-01", time.UTC)
			monthKey    = genRedisKey(rq.MacAddr, curMonth)
			dayStr      = curDay.Format(FMT_DAY_ONLY)
			daysInMonth = curMonth.AddDate(0, 1, -1).Day()
		)
		if rs, ok := kMap[monthKey]; ok {
			rs.days = append(rs.days, dayStr)
			if len(rs.days) == daysInMonth {
				rs.fullMonth = true //we have the full month, just nuke the whole key
			}
		} else {
			rs = &rmCacheSet{key: monthKey}
			rs.days = append(make([]string, 0, 31), dayStr)
			kMap[monthKey] = rs
		}
		curDay = curDay.AddDate(0, 0, 1)
	}
	res := make([]*rmCacheSet, 0, len(kMap)) //flatten results
	for _, r := range kMap {
		res = append(res, r)
	}
	sort.Slice(res, func(i, j int) bool {
		return strings.Compare(res[i].key, res[j].key) <= 0
	})
	return res
}
