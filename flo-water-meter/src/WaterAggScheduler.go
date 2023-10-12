package main

import (
	"fmt"
	"sync/atomic"
	"time"
)

type WaterAggScheduler interface {
	Open()
	Close()
}

const (
	FLO_AGG_OFFSET_START = "FLO_AGG_OFFSET_START"
	FLO_AGG_OFFSET_END   = "FLO_AGG_OFFSET_END"
	FLO_AGG_COMPUTE_DUR  = "FLO_AGG_COMPUTE_DUR"
	FLO_AGG_FREQUENCY    = "FLO_AGG_FREQUENCY"
)

func envDurMin(key string, min, def time.Duration) time.Duration {
	if dur, e := time.ParseDuration(getEnvOrDefault(key, "")); e == nil && dur >= min {
		return dur
	}
	return def
}

func NewWaterAggScheduler(red *RedisConnection, writer WaterWriter, log *Logger) WaterAggScheduler {
	wa := waterAggScheduler{
		offsetStart: envDurMin(FLO_AGG_OFFSET_START, time.Hour, 32*24*time.Hour), //32 days
		offsetEnd:   envDurMin(FLO_AGG_OFFSET_END, time.Minute*5, time.Hour),
		computeDur:  envDurMin(FLO_AGG_COMPUTE_DUR, time.Hour, time.Hour*2),
		frequency:   envDurMin(FLO_AGG_FREQUENCY, time.Minute, time.Minute*10),

		log:    log.CloneAsChild("h20AggShdlr"),
		red:    red,
		writer: writer,
	}
	if wa.offsetEnd > wa.offsetStart {
		wa.offsetStart = wa.offsetEnd + time.Hour
	}
	wa.log.Notice(wa.String())
	return &wa
}

type waterAggScheduler struct {
	offsetStart time.Duration //when to start relative to now (into the past), older than end
	offsetEnd   time.Duration //where to end relative to now (into the past), newer than start
	computeDur  time.Duration //how much data to compute per request
	frequency   time.Duration //how often to run

	state  int32
	red    *RedisConnection
	writer WaterWriter
	log    *Logger
}

func (wa waterAggScheduler) String() string {
	return fmt.Sprintf("state=%v %v=%v %v=%v %v=%v %v=%v",
		wa.state,
		FLO_AGG_OFFSET_START, wa.offsetStart,
		FLO_AGG_OFFSET_END, wa.offsetEnd,
		FLO_AGG_COMPUTE_DUR, wa.computeDur,
		FLO_AGG_FREQUENCY, wa.frequency)
}

func (wa *waterAggScheduler) Open() {
	if atomic.CompareAndSwapInt32(&wa.state, 0, 1) {
		wa.log.Info("Open")
		go func() {
			if wa.log.isDebug {
				time.Sleep(time.Second * 5)
			} else {
				time.Sleep(time.Minute / 2)
			}
			if !wa.writer.IsOpen() {
				wa.writer.Open()
			}
			wa.job()
		}()
	} else {
		wa.log.Trace("Already Opened")
	}
}

func (wa *waterAggScheduler) Close() {
	if atomic.CompareAndSwapInt32(&wa.state, 1, 0) {
		wa.log.Info("Close")
	} else {
		wa.log.Trace("Already Closed")
	}
}

func (wa *waterAggScheduler) redKey(sh string) string {
	k := fmt.Sprintf("wm:ts:agg:{%s}", sh)
	if wa.log.isDebug {
		k += "_"
	}
	return k
}

func (wa *waterAggScheduler) redTtlS() int {
	ttl := int(wa.frequency.Seconds() - 30)
	if wa.log.isDebug {
		ttl = 15
	}
	return ttl
}

func (wa *waterAggScheduler) canStart(now time.Time) bool {
	var (
		jrk = wa.redKey(_hostName)
		ttl = wa.redTtlS()
	)
	if ok, e := wa.red.SetNX(jrk, fmt.Sprint(now.Unix()), ttl); e != nil {
		wa.log.IfErrorF(e, "canStart: SetNX %v", jrk)
		return false
	} else if !ok {
		wa.log.Debug("canStart: Skipping, already tried %v within %v", jrk, wa.frequency)
		return false
	} else {
		wa.log.Trace("canStart: OK %v", jrk)
		return true
	}
}

type waterAggStat struct {
	attempts int32
	success  int32
	errors   int32
}

func (ws *waterAggStat) Skips() int32 {
	return ws.attempts - ws.success - ws.errors
}

func (ws waterAggStat) String() string {
	return fmt.Sprintf("Stats: attempts=%v success=%v errors=%v skips=%v", ws.attempts, ws.success, ws.errors, ws.Skips())
}

func (wa *waterAggScheduler) job() {
	if wa == nil || atomic.LoadInt32(&wa.state) == 0 {
		return
	}
	now := time.Now()
	defer wa.scheduleNext()
	defer recoverPanic(wa.log, "job")
	wa.log.PushScope("job")
	defer wa.log.PopScope()
	if !wa.canStart(now) {
		return
	}

	var (
		start = now.UTC().Truncate(time.Hour).Add(-wa.offsetStart)
		end   = now.UTC().Add(-wa.offsetEnd).Truncate(wa.frequency)
		stats = waterAggStat{}
		cur   = start
	)
	wa.log.Info("Starting: %v to %v | chunk=%v | %v", start.Format(FMT_RED_MAP_LASTDT), end.Format(FMT_RED_MAP_LASTDT), wa.computeDur, _hostName)
	defer func(when *time.Time, st *waterAggStat) {
		wa.log.Info("Completed. Took: %v | %v | %v", time.Since(*when), st, _hostName)
	}(&now, &stats)

	for !cur.After(end) {
		stats.attempts++
		next := cur.Add(wa.computeDur)
		if ok, e := wa.computeAgg(cur, next); e != nil {
			stats.errors++
		} else if ok {
			stats.success++
		}
		cur = next
		if atomic.LoadInt32(&wa.state) == 0 {
			wa.log.Trace("Loop: exit")
			break
		}
	}
}

func (wa *waterAggScheduler) scheduleNext() {
	if wa == nil || atomic.LoadInt32(&wa.state) == 0 {
		return
	}
	go func() {
		wait := wa.frequency
		if wa.log.isDebug {
			wait = time.Minute / 2
		}
		wa.log.Debug("scheduleNext: in %v", wait)
		time.Sleep(wait)
		wa.job()
	}()
}

func (wa *waterAggScheduler) computeAgg(cur, next time.Time) (bool, error) {
	defer recoverPanic(wa.log, "computeAgg: %v - %v", cur, next)
	var (
		start = time.Now()
		rk    = wa.redKey(cur.Format("060102T1504"))
		ttl   = wa.redTtlS()
		ok, e = wa.red.SetNX(rk, fmt.Sprint(next.Unix()), ttl)
	)
	if ok {
		if e = wa.writer.RefreshHourlyAggregates(cur, next); e == nil {
			var (
				took = time.Since(start)
				ll   = LL_DEBUG
			)
			if took < time.Millisecond*200 {
				ll = LL_TRACE
			}
			wa.log.Log(ll, "computeAgg: %v OK | took=%v", rk, took)
		} else {
			ok = false
		}
	}
	wa.log.IfErrorF(e, "computeAgg: %v to %v", rk, next)
	return ok, e
}
