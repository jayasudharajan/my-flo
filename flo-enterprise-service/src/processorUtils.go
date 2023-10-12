package main

import (
	"context"
	"sync/atomic"
	"time"
)

const maxCloseWaitSecs = 10

func updateTaskStatus(ctx context.Context, mudRepository MudTaskRepository, task *Task, status TaskStatus) error {
	task.Status = status
	_, err := mudRepository.UpdateTask(ctx, task)
	return err
}

func safelyCloseProcessor(openFlag, runningFlag *int32, log *Logger) {
	if atomic.CompareAndSwapInt32(openFlag, 1, 0) {
		n := maxCloseWaitSecs
		for atomic.LoadInt32(runningFlag) == 1 && n > 0 {
			n--
			time.Sleep(time.Second)
		}

		if atomic.LoadInt32(runningFlag) == 1 {
			log.Warn("Close: processor is still running.")
			return
		}

		log.Info("Close: OK")
	}
}

func autoResetScheduler(openFlag *int32, interval int, next func()) {

	nextRun := time.Now()
	for atomic.LoadInt32(openFlag) == 1 {
		if time.Now().Before(nextRun) {
			time.Sleep(time.Second)
			continue
		}
		next()
		nextRun = time.Now().Add(time.Duration(interval) * time.Second)
	}
}

func processorAcquireLock(redis *RedisConnection, key string, ttlSeconds int) (bool, error) {
	if redis.log.isDebug {
		return true, nil
	}
	return redis.SetNX(key, "", ttlSeconds)
}
