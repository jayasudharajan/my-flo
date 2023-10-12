package main

import (
	"time"
)

const DUR_TASK_LOCK = time.Hour * 2

func setupTasks(redis *RedisConnection, reader WaterReader, cacheWriter WaterCacheWriter) ([]ITask, error) {
	writer := CreateArchiveWaterWriter()
	if err := writer.Open(); err != nil {
		return nil, err
	}
	return []ITask{
		NewArchiveTsdTask(reader, writer, acquireLock(redis)),
		NewPurgeTsdTask(reader, writer, acquireLock(redis)),
		NewPurgeRedisTask(cacheWriter, redis, acquireLock(redis)),
	}, nil
}

func acquireLock(redis *RedisConnection) lockFunc {
	return func(key string, ttl time.Duration) (bool, error) {
		if _log.isDebug {
			return true, nil
		}
		defer recoverPanic(_log, "acquireLock")
		lockKey := "mutex:waterMeter:task:" + key
		return redis.SetNX(lockKey, "locked", int(ttl.Seconds()))
	}
}
