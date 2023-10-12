package main

import (
	"sync/atomic"
	"time"
)

const (
	ENVVAR_PURGE_CRON_SCHEDULE = "FLO_PURGE_TASK_CRON_SCHEDULE"
)

type PurgeTsdTask struct { //cleanup old TSDB data
	locker      lockFunc
	waterReader WaterReader
	waterWriter WaterWriter
	log         *Logger
}

func NewPurgeTsdTask(waterReader WaterReader, waterWriter WaterWriter, locker lockFunc) *PurgeTsdTask {
	ret := PurgeTsdTask{
		locker:      locker,
		waterReader: waterReader,
		waterWriter: waterWriter,
		log:         _log.CloneAsChild("rmTSDB"),
	}
	return &ret
}
func (task *PurgeTsdTask) Spawn() (ICloser, error) {
	if ok, err := task.locker("PurgeTSDB", DUR_TASK_LOCK); !ok {
		task.log.IfWarnF(err, "could not get lock to run task")
		return nil, err
	}
	return &PurgeTaskCtx{
		waterReader: task.waterReader,
		waterWriter: task.waterWriter,
		log:         task.log.CloneAsChild("cx"),
	}, nil
}

func (task *PurgeTsdTask) CronExpression() string {
	return getEnvOrDefault(ENVVAR_PURGE_CRON_SCHEDULE, "")
}

type PurgeTaskCtx struct {
	waterReader WaterReader
	waterWriter WaterWriter
	state       int32
	log         *Logger
}

func (task *PurgeTsdTask) Name() string {
	return task.log.GetName()
}

func (ctx *PurgeTaskCtx) Open() {
	if atomic.CompareAndSwapInt32(&ctx.state, 0, 1) {
		ctx.log.Debug("Opening")
		go ctx.run()
	}
}

func (ctx *PurgeTaskCtx) run() {
	liveStart, err := ctx.waterReader.GetLiveDataStartTime()
	if err != nil {
		ctx.log.IfErrorF(err, "run")
		return
	}
	var archiveEnd time.Time
	archiveEnd, err = ctx.waterReader.GetArchiveEndTime()
	if err != nil {
		ctx.log.IfErrorF(err, "run")
		return
	}

	// archive data went pass the live date somehow, wait until the archiver fixes the issue
	if liveStart.Before(archiveEnd) {
		ctx.log.Error("run refusing to purge data live starts (%v) before last archived date (%v)", liveStart, archiveEnd)
		return
	}

	logInfo("run Can purge until %v", archiveEnd)
	if _noWrite {
		ctx.log.Info("run Skipping purge (no_write is enabled)...")
		return
	}
	var count int
	count, err = ctx.waterWriter.DropHourlyAggregates(archiveEnd.Add(-time.Hour))
	ctx.log.IfErrorF(err, "run error purging records")
	ctx.log.Info("run purged %d chunks (before %v)", count, archiveEnd)
}

func (ctx *PurgeTaskCtx) Close() {
	if atomic.CompareAndSwapInt32(&ctx.state, 1, 0) {
		ctx.log.Debug("Closing")
	}
}
