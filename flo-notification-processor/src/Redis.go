package main

// Redis wrapper for a CLUSTERED redis connection.

import (
	"context"
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/extra/redisotel/v9"
	"github.com/redis/go-redis/v9"
)

type RedisConnection struct {
	_valid    bool
	_client   redis.UniversalClient
	_cnString string
}

func (item *RedisConnection) IsValid() bool {
	if item == nil {
		return false
	}

	return item._valid
}

func (item *RedisConnection) ConnectionString() string {
	if item == nil {
		return ""
	}

	return item._cnString
}

func parseRedisCn(cn string) (*redis.UniversalOptions, error) {
	arr := strings.Split(cn, " ")
	addr := make([]string, 0)
	pwd := ""
	ts := 0
	for _, s := range arr {
		if strings.Contains(s, ":") {
			addr = append(addr, s)
		} else if ix := strings.Index(s, "password="); ix == 0 {
			pwd = s[9:]
		} else if ix := strings.Index(s, "timeout="); ix == 0 {
			ts, _ = strconv.Atoi(s[8:])
		}
	}
	if len(addr) == 0 {
		return nil, errors.New("redis cn missing address:port")
	}

	cfg := redis.UniversalOptions{
		Addrs:         addr,
		RouteRandomly: len(addr) > 1,
	}
	if pwd != "" {
		cfg.Password = pwd
	}
	if ts > 0 {
		dur := time.Duration(ts) * time.Second
		cfg.DialTimeout = dur
		cfg.ReadTimeout = dur
		cfg.WriteTimeout = dur
	}
	return &cfg, nil
}

func NewRedisConnection(cnString string) (*RedisConnection, error) {
	cfg, e := parseRedisCn(cnString)
	if e != nil {
		return nil, e
	}
	client := redis.NewUniversalClient(cfg)

	// enable otel tracing
	if err := redisotel.InstrumentTracing(client); err != nil {
		panic(err)
	}

	// Enable otel metrics
	if err := redisotel.InstrumentMetrics(client); err != nil {
		panic(err)
	}

	rv := new(RedisConnection)
	rv._valid = true
	rv._cnString = cnString
	rv._client = client

	return rv, nil
}

func (red *RedisConnection) Ping() error {
	if cmd := red._client.Ping(context.TODO()); cmd.Err() != nil {
		return cmd.Err()
	}
	return nil
}

func (obj *RedisConnection) Set(key string, value interface{}, expireSeconds int) (string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return "", errors.New("redis connection or key is empty")
	}

	result := obj._client.Set(context.TODO(), key, value, time.Duration(expireSeconds)*time.Second)
	return result.Result()
}

func (obj *RedisConnection) Exists(keys ...string) (int64, error) {
	if obj == nil || obj._client == nil || len(keys) == 0 {
		return 0, errors.New("redis connection or key is empty")
	}

	result := obj._client.Exists(context.TODO(), keys...)
	return result.Result()
}

func (obj *RedisConnection) Get(key string) (string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return "", errors.New("redis connection or key is empty")
	}

	result := obj._client.Get(context.TODO(), key)
	return result.Result()
}

func (obj *RedisConnection) Delete(keys ...string) (int64, error) {
	if obj == nil || obj._client == nil || len(keys) == 0 {
		return 0, errors.New("redis connection or keys is empty")
	}

	result := obj._client.Del(context.TODO(), keys...)

	return result.Result()
}

func (obj *RedisConnection) Expire(key string, seconds int) (bool, error) {
	if obj == nil || obj._client == nil || key == "" {
		return false, errors.New("redis connection or key is empty")
	}

	result := obj._client.Expire(context.TODO(), key, time.Duration(seconds)*time.Second)

	return result.Result()
}

func (obj *RedisConnection) SetNX(key string, value interface{}, expireSeconds int) (bool, error) {
	if obj == nil || obj._client == nil || key == "" {
		return false, errors.New("redis connection or key is empty")
	}

	result := obj._client.SetNX(context.TODO(), key, value, time.Duration(expireSeconds)*time.Second)

	return result.Result()
}

func (obj *RedisConnection) SAdd(key string, member ...interface{}) (int64, error) {
	if obj == nil || obj._client == nil || key == "" {
		return 0, errors.New("redis connection or key is empty")
	}

	result := obj._client.SAdd(context.TODO(), key, member...)
	return result.Result()
}

func (obj *RedisConnection) SMembers(key string) ([]string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return nil, errors.New("redis connection or key is empty")
	}

	result := obj._client.SMembers(context.TODO(), key)

	if result.Err() != nil {
		return nil, result.Err()
	}

	return result.Val(), nil
}

func (obj *RedisConnection) HMSet(key string, propMap map[string]interface{}, expireSeconds int) (ok bool, err error) {
	if obj == nil || obj._client == nil || key == "" || len(propMap) == 0 {
		return false, errors.New("redis connection or keyvalue is empty")
	}

	result := obj._client.HMSet(context.TODO(), key, propMap)

	if result.Err() != nil {
		return false, result.Err()
	}

	if expireSeconds > 0 {
		expResult := obj._client.Expire(context.TODO(), key, time.Duration(expireSeconds)*time.Second)

		if expResult.Err() != nil {
			return false, expResult.Err()
		}
	}

	return true, nil
}

func (obj *RedisConnection) HDelete(key string, properties ...string) error {
	if obj == nil || obj._client == nil || key == "" {
		return errors.New("redis connection or key is empty")
	}

	result := obj._client.HDel(context.TODO(), key, properties...)

	if result.Err() != nil {
		return result.Err()
	}

	return nil
}

func (obj *RedisConnection) HGetAll(key string) (items map[string]string, err error) {
	if obj == nil || obj._client == nil || key == "" {
		return nil, errors.New("redis connection or key is empty")
	}

	result := obj._client.HGetAll(context.TODO(), key)

	if result.Err() != nil {
		return nil, result.Err()
	}

	items, err = result.Result()

	if err != nil {
		return nil, err
	}

	return items, nil
}

func (obj *RedisConnection) ZAdd(key string, score float64, member interface{}) error {
	if obj == nil || obj._client == nil || key == "" {
		return errors.New("redis connection or key is empty")
	}

	result := obj._client.ZAdd(context.TODO(), key, redis.Z{Score: score, Member: member})

	if result.Err() != nil {
		return result.Err()
	}

	return nil
}

func (obj *RedisConnection) ZRemRangeByScore(key string, minScore float64, maxScore float64) error {
	if obj == nil || obj._client == nil || key == "" {
		return errors.New("redis connection or key is empty")
	}

	minScoreStr := strconv.FormatFloat(minScore, 'f', -1, 64)
	maxScoreStr := strconv.FormatFloat(maxScore, 'f', -1, 64)
	result := obj._client.ZRemRangeByScore(context.TODO(), key, minScoreStr, maxScoreStr)

	if result.Err() != nil {
		return result.Err()
	}

	return nil
}

func (obj *RedisConnection) ZRangeByScoreWithScores(key string, minScore *float64, maxScore *float64, count *int64, offset *int64) ([]redis.Z, error) {
	if obj == nil || obj._client == nil || key == "" {
		return nil, errors.New("redis connection or key is empty")
	}

	minScoreStr := "-inf"
	maxScoreStr := "+inf"
	var countParam int64
	var offsetParam int64

	if minScore != nil {
		minScoreStr = strconv.FormatFloat(*minScore, 'f', -1, 64)
	}
	if maxScore != nil {
		maxScoreStr = strconv.FormatFloat(*maxScore, 'f', -1, 64)
	}
	if count != nil {
		countParam = *count
	}
	if offset != nil {
		offsetParam = *offset
	}

	zr := redis.ZRangeBy{
		Min:    minScoreStr,
		Max:    maxScoreStr,
		Count:  countParam,
		Offset: offsetParam,
	}
	result := obj._client.ZRangeByScoreWithScores(context.TODO(), key, &zr)
	if result.Err() != nil {
		return nil, result.Err()
	}

	return result.Result()
}
