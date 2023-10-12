package main

import (
	"strings"
	"sync/atomic"
	"time"

	"github.com/pkg/errors"
	"github.com/robfig/cron/v3"
)

const (
	ENVVAR_CRON_ASAP = "FLO_TASKS_CRON_ASAP"
)

type Scheduler struct {
	logger  *Logger
	tasks   []ITask
	cronJob *cron.Cron
	redis   *RedisConnection
	state   int32 //0=closed, 1=open
	jobs    []ICloser
}
type schedulerLogger struct {
	logger *Logger
}

func CreateSchedulerLogger(
	log *Logger) *schedulerLogger {
	return &schedulerLogger{log}
}

func (l schedulerLogger) Info(msg string, keysAndValues ...interface{}) {
	l.logger.Info(msg, keysAndValues...)
}

func (l schedulerLogger) Error(err error, msg string, keysAndValues ...interface{}) {
	l.logger.IfErrorF(err, msg, keysAndValues...)
}

func CreateScheduler(
	tasks []ITask,
	redis *RedisConnection,
	log *Logger) *Scheduler {

	s := Scheduler{
		tasks:  tasks,
		redis:  redis,
		logger: log.CloneAsChild("Scheduler"),
		state:  0,
		jobs:   make([]ICloser, 0),
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
		c := cron.New(cron.WithLogger(CreateSchedulerLogger(thisScheduler.logger)))
		start := false
		for _, tsk := range thisScheduler.tasks {
			expr := tsk.CronExpression()
			if expr == "" {
				thisScheduler.logger.Notice("Open: %v cron expression is BLANK, will not schedule it", TypeName(tsk))
				continue
			}
			lTsk := tsk
			if cid, e := c.AddFunc(expr, func() { thisScheduler.cronRun(lTsk) }); e != nil {
				thisScheduler.logger.IfFatalF(e, "Open: cronJob bad expression %v=%v", TypeName(tsk), expr)
			} else {
				start = true
				thisScheduler.logger.Notice("Open: cronJob #%v | %v=%v", cid, TypeName(tsk), expr)
				thisScheduler.tryRunNow(tsk)
			}
		}
		if start {
			thisScheduler.cronJob = c
			thisScheduler.cronJob.Start()
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

func (thisScheduler *Scheduler) cronRun(task ITask) {
	if task == nil {
		return
	}
	defer recoverPanic(thisScheduler.logger, "cronRun: %v", task.Name())
	thisScheduler.logger.Notice("cronJob: Trying to run %v", TypeName(task))

	if e := thisScheduler.Run(task); e != nil {
		thisScheduler.logger.IfWarnF(e, "cronJob: Rejecting to run %v", TypeName(task))
	}
}

func (thisScheduler *Scheduler) Run(task ITask) error {
	thisScheduler.logger.PushScope("Run", task.Name())
	defer thisScheduler.logger.PopScope()
	he := thisScheduler.canRun()
	if he != nil {
		return he
	}

	job, he := task.Spawn()
	if job != nil {
		job.Open()
		thisScheduler.jobs = append(thisScheduler.jobs, job)
	}
	return he
}

func (thisScheduler Scheduler) canRun() error {
	if st := atomic.LoadInt32(&thisScheduler.state); st == 0 {
		return errors.New("service is not in Open state")
	}
	return nil
}

func (thisScheduler *Scheduler) tryRunNow(task ITask) {
	if thisScheduler.canCronASAP() {
		go func() {
			time.Sleep(time.Second)
			thisScheduler.cronRun(task)
		}()
	}
}

func (thisScheduler *Scheduler) flushJobs() {
	for i, j := range thisScheduler.jobs {
		tryClose(j, thisScheduler.logger, i)
	}
	thisScheduler.jobs = make([]ICloser, 0)
}
