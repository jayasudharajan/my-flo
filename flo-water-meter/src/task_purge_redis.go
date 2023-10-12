package main

import (
	"github.com/go-redis/redis"
	"sync/atomic"
	"time"
)

type PurgeRedisTask struct {
	locker lockFunc
	cache  WaterCacheWriter
	red    *RedisConnection
	log    *Logger
	state  int32
}

func (t *PurgeRedisTask) CronExpression() string {
	return getEnvOrDefault("FLO_PURGE_REDIS_CRON_SCHEDULE", "")
}

func NewPurgeRedisTask(cache WaterCacheWriter, red *RedisConnection, locker lockFunc) *PurgeRedisTask {
	return &PurgeRedisTask{
		locker,
		cache,
		red,
		_log.CloneAsChild("rmRedis"),
		0,
	}
}

func (t *PurgeRedisTask) Name() string {
	return t.log.GetName()
}

func (t *PurgeRedisTask) Spawn() (ICloser, error) {
	if ok, err := t.locker("PurgeREDIS", DUR_TASK_LOCK); !ok {
		t.log.IfWarnF(err, "could not get lock to run task")
		return nil, err
	}
	cp := *t //shallow copy
	cp.log = t.log.CloneAsChild("cp")
	return &cp, nil //shallow copy
}

func (t *PurgeRedisTask) Open() {
	if atomic.CompareAndSwapInt32(&t.state, 0, 1) {
		t.log.Debug("Opening")
		go t.run()
	}
}

func (t *PurgeRedisTask) Close() {
	if atomic.CompareAndSwapInt32(&t.state, 1, 0) {
		t.log.Debug("Closing")
	}
}

func (t *PurgeRedisTask) redisKey() string {
	k := "h2o.redis.purge"
	if t.log.isDebug {
		k += "_"
	}
	return k
}

func (t *PurgeRedisTask) getLastRm() time.Time {
	k := t.redisKey()
	if str, e := t.red.Get(k); e != nil {
		if e != redis.Nil {
			t.log.IfWarnF(e, "getLastRm failed")
		}
	} else {
		var dt time.Time
		if dt, e = time.Parse(FMT_DAY_ONLY, str); e != nil {
			t.log.IfWarnF(e, "getLastRm parse error: %v", str)
		} else if dt.Year() >= 2010 {
			t.log.Debug("getLastRm found: %v=%v", k, str)
			return dt
		}
	}
	if t.log.isDebug {
		return time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC)
	}
	return lastYear(false).AddDate(0, -1, 0) //cover an additional month
}

func lastYear(resetMonth bool) time.Time {
	var (
		now            = time.Now().UTC()
		year, month, _ = now.Date()
	)
	if resetMonth {
		month = 1
	}
	return time.Date(year-1, month, 1, 0, 0, 0, 0, now.Location())
}

func (t *PurgeRedisTask) setLastRm(dt time.Time) error {
	var (
		dts = dt.Format(FMT_DAY_ONLY)
		ttl = 60 * 60 * 24 * 31
		k   = t.redisKey()
	)
	if _, e := t.red.Set(k, dts, ttl); e != nil {
		t.log.IfErrorF(e, "setLastRM Failed %v", dt.Format(FMT_DAY_ONLY))
		return e
	} else {
		t.log.Debug("setLastRm OK to %v=%v", k, dts)
		return nil
	}
}

func (t *PurgeRedisTask) run() {
	t.log.Debug("run Started")
	var (
		enter    = time.Now()
		cur      = t.getLastRm()
		stop     = redisReadStart()
		totalRem = 0
	)
	for cur.Before(stop) {
		var (
			exp = cur.Format("2006-01") + "-*"
			rem = t.cache.RemoveOldCache(exp)
		)
		totalRem += rem
		t.log.Debug("run RemoveOldCache BATCH OK. Deleted %v", rem)
		t.setLastRm(cur)
		cur = cur.AddDate(0, 1, 0)
	}
	t.log.Notice("run RemoveOldCache OK. Deleted %v, took %v", totalRem, time.Since(enter))
}
