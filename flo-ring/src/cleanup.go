package main

import (
	"context"
	"fmt"
	"strings"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis"
)

type Cleanup interface {
	MaxInterval() time.Duration
	AlreadyCleaned(ctx context.Context, rq *CleanReq) (string, bool)
	CleanDevices(ctx context.Context, rq *CleanReq)
	Open()
	Close()
}

type cleanup struct {
	log         *Logger
	store       EntityStore
	pubGW       PublicGateway
	ringQ       RingQueue
	disco       DeviceDiscovery
	red         *RedisConnection
	state       int32 //open=1, closed=0
	maxInterval time.Duration
}

const DEFAULT_MAX_CLEAN_DUR = time.Hour * 8

func NewCleanup(
	log *Logger,
	store EntityStore,
	pubGW PublicGateway,
	ringQ RingQueue,
	disco DeviceDiscovery,
	red *RedisConnection) Cleanup {

	maxDur, e := time.ParseDuration(getEnvOrDefault("FLO_MAX_CLEAN_DUR", DEFAULT_MAX_CLEAN_DUR.String()))
	if e != nil {
		maxDur = DEFAULT_MAX_CLEAN_DUR
	}
	return &cleanup{
		log.CloneAsChild("CLR"),
		store,
		pubGW,
		ringQ,
		disco,
		red,
		0,
		maxDur,
	}
}

func (cl *cleanup) MaxInterval() time.Duration {
	return cl.maxInterval
}

func (cl *cleanup) Open() {
	if cl != nil && atomic.CompareAndSwapInt32(&cl.state, 0, 1) {
		cl.log.Debug("Opening")
		defer cl.log.Notice("Opened")
	}
}

func (cl *cleanup) Close() {
	if cl != nil && atomic.CompareAndSwapInt32(&cl.state, 1, 0) {
		cl.log.Debug("Closing")
		defer cl.log.Notice("Closed")
	}
}

func (cl *cleanup) AlreadyCleaned(ctx context.Context, rq *CleanReq) (string, bool) {
	if rq.Force {
		return "", false
	}
	var (
		k    = cl.getKey(rq)
		s, e = cl.red.Get(ctx, k)
	)
	if e != nil && e != redis.Nil {
		cl.log.IfErrorF(e, "AlreadyCleaned: %v", rq)
	}
	return s, s != ""
}

func (cl *cleanup) getKey(rq *CleanReq) string {
	return fmt.Sprintf("flo-ring:cleanup:%v:%v", rq.MacStart, rq.Limit)
}

func (cl *cleanup) canClean(ctx context.Context, rq *CleanReq) bool {
	var (
		k = cl.getKey(rq)
		v = fmt.Sprintf("%v@%v", _hostName, time.Now().UTC().Format(time.RFC3339))
	)
	ok, e := cl.red.SetNX(ctx, k, v, int(cl.maxInterval.Seconds()))
	if e != nil {
		cl.log.IfErrorF(e, "canClean: REDIS_FAIL")
	} else if !ok {
		cl.log.Warn("canClean: RAN_RECENTLY within %v", cl.maxInterval.String())
	} else {
		cl.log.Debug("canClean: OK")
	}
	return ok
}

const SCAN_DEFAULT = 500

func (cl *cleanup) CleanDevices(ctx context.Context, rq *CleanReq) {
	defer panicRecover(cl.log, "CleanDevices: %v", rq)
	started := time.Now()
	cl.log.PushScope("CleanDevices").Notice("Started")
	var (
		ok   int32 = 0
		oops int32 = 0
		rms  int32 = 0
	)
	defer func(st time.Time, good, bad, rm *int32) {
		var (
			y = *good
			n = *bad
		)
		cl.log.Notice("TASK_DONE! Took %v. Processed:%v (OK:%v, ERR:%v, RM:%v)",
			time.Since(st).String(), y+n, y, n, *rm)
		cl.log.PopScope()
	}(started, &ok, &oops, &rms)

	if !rq.Force && !cl.canClean(ctx, rq) {
		return
	}
	if rq.Limit <= 0 {
		rq.Limit = SCAN_DEFAULT
	}

	var (
		arr      []*ScanDevice
		err      error
		hasNext  = true
		macStart = rq.MacStart
	)
	for hasNext && err == nil {
		if cl.state == 0 {
			break
		}
		batchStart := time.Now()
		arr, err = cl.store.ScanDevices(ctx, macStart, rq.Limit)
		if err != nil {
			cl.log.IfErrorF(err, "scan failed")
			break
		}
		hasNext = int32(len(arr)) >= rq.Limit

		for _, d := range arr {
			if cl.state == 0 {
				break
			}
			macStart = d.Mac
			if rm, e := cl.checkDevice(ctx, d); e != nil {
				oops++
			} else {
				if rm {
					rms++
				}
				ok++
			}
		}
		cl.log.Notice("BATCH_COMPLETE len=%v. Sums:%v (OK:%v, ERR:%v, RM:%v). Next %v, took: %v",
			len(arr), ok+oops, ok, oops, rms, macStart, time.Since(batchStart).String())
	}
}

func (cl *cleanup) checkDevice(ctx context.Context, sc *ScanDevice) (removed bool, err error) {
	cl.log.PushScope("chk")
	defer cl.log.PopScope()

	dc := deviceCriteria{Id: sc.Id}
	if _, e := cl.pubGW.GetDevice(&dc); e != nil {
		htErr, ok := e.(*HttpErr)
		if ok && htErr.Code == 404 && strings.EqualFold("Not found.", htErr.Message) { //device not found!
			var evt *EventMessage
			if evt, e = cl.buildRmReport(ctx, sc); e != nil {
				cl.log.IfWarnF(e, "SYNC_FAIL rmReport %v", sc)
			} else if e = cl.ringQ.Put(ctx, evt); e != nil {
				cl.log.IfWarnF(e, "SYNC_FAIL ringQ.Put %v", sc)
			} else { //cleanup OK
				removed = true
				cl.log.Info("SYNC_CLEAN %v", sc)
			}
		}
		return removed, e
	} else {
		cl.log.Trace("SYNC_OK %v", sc)
		return false, nil
	}
}

func (cl *cleanup) buildRmReport(ctx context.Context, sc *ScanDevice) (*EventMessage, error) {
	rmDev := Device{Id: sc.Id, MacAddress: sc.Mac}
	if evt, e := cl.disco.BuildDeleteReportForDevice(ctx, &rmDev); e != nil {
		cl.log.IfWarnF(e, "SYNC_FAIL rmReport %v", sc)
		return nil, e
	} else {
		go cl.store.LogDeviceCleaned(ctx, sc.Id, sc.Mac)
		return evt, nil
	}
}
