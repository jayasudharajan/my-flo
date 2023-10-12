package main

import (
	"context"
	"encoding/json"
	"fmt"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis"
	"golang.org/x/sync/semaphore"
	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
)

const (
	ENVVAR_TELEMETRY_LATEST_TOPIC = "FLO_TELEMETRY_LATEST_TOPIC"
)

// LatestCacher logic to cache the last telemetry uploaded to redis so it can be pulled
type LatestCacher struct {
	counter  int64 //how many msg processed
	kafConn  *KafkaConnection
	kafSub   *KafkaSubscription
	kafTopic string
	kafGroup string
	redis    *RedisConnection
	log      *Logger
	ctx      context.Context
	sem      *semaphore.Weighted
	state    int32         //0 == not open, 1 == opened
	rmDur    time.Duration //telemetry older than now - rmDur will be discarded
}

func DefaultLatestCacher(redis *RedisConnection) *LatestCacher {
	var (
		lc = LatestCacher{
			kafGroup: getEnvOrExit(ENVVAR_KAFKA_GROUP_ID) + "_latest",
			kafTopic: getEnvOrDefault(ENVVAR_TELEMETRY_LATEST_TOPIC, ""),
			redis:    redis,
			ctx:      context.Background(),
			sem:      semaphore.NewWeighted(3), //limit redis concurrency
			log:      _log.CloneAsChild("latest$"),
			rmDur:    time.Hour + (time.Minute * 30), //1.5hrs
		}
		err error
	)
	if lc.kafTopic == "" {
		lc.log.Warn("DefaultLatestCacher: %v is not configured, Latest telemetry caching is DISABLED", ENVVAR_TELEMETRY_LATEST_TOPIC)
		return nil
	} else if lc.kafConn, err = OpenKafka(getEnvOrExit(ENVVAR_KAFKA_CN), nil); err != nil {
		lc.log.IfFatalF(err, "DefaultLatestCacher: can not open Kafka connection")
		return nil
	} else {
		lc.log.Notice("%v=%v", ENVVAR_TELEMETRY_LATEST_TOPIC, lc.kafTopic)
	}
	return &lc
}

func (lc *LatestCacher) Open() {
	if lc != nil && atomic.CompareAndSwapInt32(&lc.state, 0, 1) {
		lc.log.Info("Opening")

		if lc.kafSub != nil {
			lc.kafSub.Close()
			time.Sleep(time.Second)
		}

		var err error
		if lc.kafSub, err = lc.kafConn.Subscribe(lc.kafGroup, []string{lc.kafTopic}, lc.messageReceiver); err != nil {
			lc.log.IfFatalF(err, "DefaultLatestCacher: can not subscribe to %v - %v", lc.kafGroup, lc.kafTopic)
		} else {
			lc.log.Notice("Opened")
		}
	}
}

func (l *LatestCacher) Close() {
	if l != nil && atomic.CompareAndSwapInt32(&l.state, 1, 0) {
		l.log.Info("Closing")
		l.kafSub.Close()
	}
}

func (l *LatestCacher) Dispose() {
	if l == nil {
		return
	}
	l.Close()
	if atomic.CompareAndSwapInt32(&l.state, 0, -1) {
		l.log.Notice("Disposing")
		l.kafConn.Close()
	}
}

func (lc *LatestCacher) messageReceiver(item *kafka.Message) {
	defer recoverPanic(lc.log, "messageReceiver: %v", item.Key)
	if item == nil || len(item.Key) != 12 || len(item.Value) == 0 || item.Value[0] != '{' {
		return
	}

	t := TelemetryData{}
	if e := json.Unmarshal(item.Value, &t); e != nil {
		lc.log.IfWarnF(e, "messageReceiver: json err %v | %v", e, item.Value)
		return
	} else if !_allow.Found(t.MacAddress) {
		lc.log.Trace("messageReceiver: not allowed %v", t)
		return
	} else if !isValidMacAddress(t.MacAddress) {
		lc.log.Trace("messageReceiver: bad mac %v", t)
		return //ignore bad data
	} else {
		lc.ProcessTelemetry(&t)
	}
}

func (lc *LatestCacher) ProcessTelemetry(t *TelemetryData) {
	cutoff := time.Now().Add(-lc.rmDur).UTC()
	if ts := time.Unix(t.Timestamp/1000, 0); ts.Before(cutoff) {
		lc.log.Trace("ProcessTelemetry: %v too old", t)
		return //ts too old!
	} else {
		latest := LatestTelemetry{
			MacAddress: t.MacAddress,
			TimeStamp:  ts,
			GPS:        t.GPM / 60,
			PSI:        t.PSI,
			TempF:      t.TempF,
			ValveState: int32(t.ValveState),
			SystemMode: int32(t.SystemMode),
		}

		lc.sem.Acquire(lc.ctx, 1)
		defer lc.sem.Release(1)
		var (
			exp = 60
			key = latest.redisKey() + ":chk"
		)
		if lc.log.isDebug {
			exp = 5
		}
		if ok, _ := lc.redis.SetNX(key, latest.TimeStamp.Unix(), exp); ok {
			lc.log.Debug("ProcessTelemetry: ACCEPTED key %v OK for %v | %v", key, ts, latest)
			lc.writeLatest(&latest) //short lim, should not be a problem
		} else {
			lc.log.Debug("ProcessTelemetry: IGNORED key %v exist for %v | %v", key, ts, latest)
		}
	}
}

func (c *LatestCacher) writeLatest(last *LatestTelemetry) {
	js, err := json.Marshal(last)
	if err != nil {
		c.log.IfErrorF(err, "writeLatest: %v", last)
		return
	}
	var (
		rk     = last.redisKey()
		rw     = float64(last.TimeStamp.Unix())
		addCmd = _cache._client.ZAdd(rk, redis.Z{rw, js})
	)
	if n, e := addCmd.Result(); e != nil {
		c.log.IfErrorF(e, "writeLatest: %v @ %v score=%v", rk, last, rw)
	} else if n > 0 {
		if atomic.AddInt64(&c.counter, 1)%2 == 0 {
			c.rmOldData(last.MacAddress, last.TimeStamp)
		}
		c.log.Debug("writeLatest: OK %v @ %v", rk, last)
	}
}

func (c *LatestCacher) rmOldData(mac string, before time.Time) error {
	var (
		last     = LatestTelemetry{MacAddress: mac, TimeStamp: before}
		rk       = last.redisKey()
		bfWeight = fmt.Sprint(before.UTC().Unix() - 1)
		remCmd   = _cache._client.ZRemRangeByScore(rk, "-inf", bfWeight) //rm items from negative infinity to weight-1sec
	)
	if n, e := remCmd.Result(); e != nil && e != redis.Nil {
		c.log.IfWarnF(e, "rmOldData: %v @ %v weight=%v", rk, last, bfWeight)
		return e
	} else {
		c.log.Debug("rmOldData: OK %v @ %v weight=%v, removed=%v", rk, last, bfWeight, n)
		return nil
	}
}
