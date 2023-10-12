package main

import (
	"sync/atomic"
	"time"

	"github.com/gorhill/cronexpr"
	"github.com/pkg/errors"
)

const schedulerLockKey = "task-scheduler.lock"
const maxCloseWaitSecs = 10

type Scheduler interface {
	Open()
	Close()

	NewTask(taskDefinition *TaskDefinition) error
	CancelTask(taskId string) (bool, error)
}

type SchedulerKafkaConfig struct {
	kafkaConnection *KafkaConnection
	topic           string
}

type scheduler struct {
	log               *Logger
	kafkaConfig       *SchedulerKafkaConfig
	kafkaSubscription *KafkaSubscription
	taskRepository    TaskRepository
	redis             *RedisConnection
	pollIntervalSecs  int
	isOpen            int32
	isRunning         int32
}

func CreateScheduler(log *Logger, pollIntervalSecs int, kafkaConfig *SchedulerKafkaConfig, taskRepository TaskRepository, redis *RedisConnection) Scheduler {
	return &scheduler{
		log:              log.CloneAsChild("scheduler"),
		pollIntervalSecs: pollIntervalSecs,
		kafkaConfig:      kafkaConfig,
		taskRepository:   taskRepository,
		redis:            redis,
	}
}

func (s *scheduler) Open() {
	if atomic.CompareAndSwapInt32(&s.isOpen, 0, 1) {
		s.log.Debug("Open: begin")
		go s.runScheduler()
	} else {
		s.log.Warn("Open: already opened")
	}
}

func (s *scheduler) Close() {
	if atomic.CompareAndSwapInt32(&s.isOpen, 1, 0) {
		n := maxCloseWaitSecs
		for atomic.LoadInt32(&s.isRunning) == 1 && n > 0 {
			n--
			time.Sleep(1 * time.Second)
		}

		if atomic.LoadInt32(&s.isRunning) == 1 {
			s.log.Warn("Close: scheduler is still running.")
			return
		}

		s.log.Info("Close: OK")
	} else {
		s.log.Warn("Close: already closed")
	}
}

func (s *scheduler) NewTask(taskDef *TaskDefinition) error {
	var err error
	nextExecution, err := s.nextExecutionTime(taskDef)

	if err != nil {
		return errors.Wrapf(err, "NewTask: error calculating next execution time for task %s", taskDef.Id)
	}

	task := &Task{
		Id:                taskDef.Id,
		Definition:        taskDef,
		Status:            TS_Pending,
		NextExecutionTime: nextExecution,
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
	}

	retryIfError(
		func() error {
			err = s.taskRepository.InsertTask(task)
			if err == UniqueConstraintFailed {
				return nil
			}
			return err
		},
		1*time.Second,
		3,
		s.log,
	)

	return err
}

func (s *scheduler) CancelTask(taskId string) (bool, error) {
	var (
		taskCanceled bool
		err          error
	)
	err = retryIfError(
		func() error {
			taskCanceled, err = s.taskRepository.CancelTask(taskId)
			if err != nil {
				return err
			}
			return nil
		},
		1*time.Second,
		3,
		s.log,
	)
	if err != nil {
		return false, err
	}
	return taskCanceled, nil
}

func (s *scheduler) runScheduler() {
	defer panicRecover(s.log, "runScheduler: %p", s)

	atomic.StoreInt32(&s.isRunning, 1)
	for atomic.LoadInt32(&s.isOpen) == 1 {
		s.log.Info("runScheduler: scheduling due tasks")
		go s.scheduleTasks()
		s.log.Info("runScheduler: sleeping for %d seconds", s.pollIntervalSecs)
		time.Sleep(time.Duration(s.pollIntervalSecs) * time.Second)
	}
	atomic.StoreInt32(&s.isRunning, 0)
}

func (s *scheduler) scheduleTasks() {
	defer panicRecover(s.log, "scheduleTasks: %p", s)

	s.log.Debug("scheduleTasks: acquiring lock")
	lockAcquired, err := s.redis.SetNX(schedulerLockKey, "", s.pollIntervalSecs)
	if err != nil {
		s.log.Warn("scheduleTasks: error acquiring lock - %v", err)
		return
	}

	if !lockAcquired {
		s.log.Trace("scheduleTask: lock was acquired by another instance")
		return
	}

	s.log.Debug("scheduleTasks: retrieving due tasks")
	tasks, err := s.taskRepository.GetDueTasks()
	if err != nil {
		s.log.Warn("scheduleTasks: error getting due tasks - %v", err)
		return
	}

	var taskIds []string
	for _, t := range tasks {
		taskIds = append(taskIds, t.Id)
	}

	s.log.Debug("scheduleTasks: retrieved %d tasks", len(taskIds))

	if len(taskIds) > 0 {
		s.log.Debug("scheduleTasks: updating task status to %d", TS_Scheduled)
		err = s.updateTaskStatus(taskIds, TS_Scheduled)
		if err != nil {
			s.log.Warn("scheduleTasks: error updating task status - %v", err)
		}
		s.log.Debug("scheduleTasks: updated task status to %d", TS_Scheduled)

		for _, t := range tasks {
			s.log.Debug("scheduleTasks: publishing task %s", t.Id)
			err = retryIfError(
				func() error {
					return s.kafkaConfig.kafkaConnection.Publish(s.kafkaConfig.topic, t, nil)
				},
				100*time.Millisecond,
				3,
				s.log,
			)

			if err == nil {
				s.log.Debug("scheduleTasks: published task %s", t.Id)
			} else {
				s.log.Error("scheduleTasks: error publishing task %s - %v", t.Id, err)
				// TODO: Shall we mark the task as TS_Failed instead?
				go func() {
					defer panicRecover(s.log, "scheduleTasks: %p", s)
					s.log.Debug("scheduleTasks: reverting task %s status", t.Id)
					err = s.updateTaskStatus([]string{t.Id}, TS_Pending)
					if err != nil {
						s.log.Error("scheduleTasks: error reverting task %s status - %v", t.Id, err)
					}
				}()
			}
		}
	}
	s.log.Info("scheduleTasks: finished processing %d tasks", len(taskIds))

	s.log.Debug("scheduleTasks: releasing lock")
	_, err = s.redis.Delete(schedulerLockKey)
	if err != nil {
		s.log.Warn("scheduleTasks: error releasing lock - %v", err)
	}
}

func (s *scheduler) updateTaskStatus(taskIds []string, status TaskStatus) error {
	return retryIfError(
		func() error {
			return s.taskRepository.UpdateTaskStatus(taskIds, status)
		},
		250*time.Millisecond,
		3,
		s.log,
	)
}

func (s *scheduler) nextExecutionTime(taskDef *TaskDefinition) (time.Time, error) {
	switch taskDef.Schedule.Type {
	case ST_Cron:
		var cronSchedule CronSchedule
		err := decode(taskDef.Schedule.Config, &cronSchedule)
		if err != nil {
			return time.Time{}, errors.Wrapf(err, "nextExecutionTime: error decoding cron schedule %v for task %s", taskDef.Schedule.Config, taskDef.Id)
		}
		next := cronexpr.MustParse(cronSchedule.Expression).Next(time.Now())
		return next, nil
	case ST_FixedDate:
		var fixedDateSchedule FixedDateSchedule
		err := decode(taskDef.Schedule.Config, &fixedDateSchedule)
		if err != nil {
			return time.Time{}, errors.Wrapf(err, "nextExecutionTime: error decoding fixedDate schedule %v for task %s", taskDef.Schedule.Config, taskDef.Id)
		}
		return fixedDateSchedule.Target, nil
	}

	// Schedule types should have been validated before.
	return time.Time{}, errors.Errorf("nextExecutionTime: unsupported schedule type %s", taskDef.Schedule.Type)
}
