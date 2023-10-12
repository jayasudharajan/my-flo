package main

import (
	"context"
	"strings"
	"sync/atomic"
	"time"

	"github.com/pkg/errors"
	"github.com/robfig/cron/v3"
)

const (
	ENVVAR_CRON_SCHEDULE = "FLO_TASKS_CRON_SCHEDULE"
	ENVVAR_CRON_ASAP     = "FLO_TASKS_CRON_ASAP"
)

type Scheduler struct {
	cleanup Cleanup
	logger  *Logger
	cronJob *cron.Cron
	redis   *RedisConnection
	state   int32 //0=closed, 1=open
	jobs    []ICloser
}

func CreateScheduler(
	cleanup Cleanup,
	redis *RedisConnection,
	log *Logger) *Scheduler {

	s := Scheduler{
		cleanup: cleanup,
		redis:   redis,
		logger:  log.CloneAsChild("Scheduler"),
		state:   0,
		jobs:    make([]ICloser, 0),
	}
	return &s
}

func (thisScheduler *Scheduler) canCronASAP() bool {
	return thisScheduler.logger.isDebug && strings.EqualFold(getEnvOrDefault(ENVVAR_CRON_ASAP, ""), "true")
}

func (thisScheduler *Scheduler) Open() {
	if thisScheduler == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&thisScheduler.state, 0, 1) {
		if cronExp := getEnvOrDefault(ENVVAR_CRON_SCHEDULE, ""); cronExp == "" {
			thisScheduler.logger.Notice("Open: %v is BLANK, will not schedule ring tasks", ENVVAR_CRON_SCHEDULE)
			thisScheduler.tryRunNow()
		} else {
			c := cron.New()
			if cid, e := c.AddFunc(cronExp, thisScheduler.cronRun); e != nil {
				thisScheduler.logger.IfFatalF(e, "Open: cronJob bad expression %v=%v", ENVVAR_CRON_SCHEDULE, cronExp)
				defer signalExit()
			} else {
				thisScheduler.cronJob = c
				thisScheduler.logger.Notice("Open: cronJob #%v | %v=%v", cid, ENVVAR_CRON_SCHEDULE, cronExp)
				thisScheduler.cronJob.Start()
				thisScheduler.tryRunNow()
			}
		}
	}
}

func (thisScheduler *Scheduler) Close() {
	if thisScheduler == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&thisScheduler.state, 1, 0) {
		if thisScheduler.cronJob != nil {
			thisScheduler.logger.Notice("Stop: terminating cronJob")
			thisScheduler.cronJob.Stop()
		} else {
			thisScheduler.logger.Notice("Stop: no cronJob scheduled")
		}

		thisScheduler.flushJobs()
	}
}

func (thisScheduler *Scheduler) cronRun() {
	thisScheduler.logger.Notice("cronJob: Trying to run scheduled jobs")

	if e := thisScheduler.Run(); e != nil {
		thisScheduler.logger.Notice("cronJob: Rejecting to run jobs, %v", e)
	}
}

func (thisScheduler *Scheduler) Run() error {
	he := thisScheduler.canRun()
	if he != nil {
		return he
	}
	thisScheduler.logger.PushScope("Run")
	defer thisScheduler.logger.PopScope()

	// stopping other jobs before running new ones
	thisScheduler.flushJobs()

	deviceJob := NewDeviceScheduleRunContext(thisScheduler.cleanup,
		thisScheduler.acquireLock,
		thisScheduler.logger)
	deviceJob.Open()
	thisScheduler.jobs = append(thisScheduler.jobs, deviceJob)

	return nil
}

func (thisScheduler Scheduler) canRun() error {
	thisScheduler.logger.PushScope("canRun")
	defer thisScheduler.logger.PopScope()

	if st := atomic.LoadInt32(&thisScheduler.state); st == 0 {
		return errors.New("service is not in Open state")
	}

	return nil
}

func (thisScheduler *Scheduler) tryRunNow() {
	if thisScheduler.canCronASAP() {
		go func() {
			time.Sleep(time.Second)
			thisScheduler.cronRun()
		}()
	}
}

func (thisScheduler *Scheduler) flushJobs() {
	for i, j := range thisScheduler.jobs {
		tryClose(j, thisScheduler.logger, i)
	}
	thisScheduler.jobs = make([]ICloser, 0)
}

func (thisScheduler *Scheduler) acquireLock(ctx context.Context, key string, ttl time.Duration) (bool, error) {
	ok, e := thisScheduler.redis.SetNX(ctx, key, "locked", int(ttl.Seconds()))
	return ok, e
}
