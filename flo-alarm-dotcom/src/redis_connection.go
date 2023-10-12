package main

// Redis wrapper for a CLUSTERED redis connection.

import (
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis"
)

type RedisConnection interface {
	IsValid() bool
	ConnectionString() string
	Ping() error
	Client() redis.UniversalClient

	Set(key string, value interface{}, expireSeconds int) (string, error)
	Exists(keys ...string) (int64, error)
	Get(key string) (string, error)
	Delete(keys ...string) (int64, error)
	Expire(key string, seconds int) (bool, error)
	SetNX(key string, value interface{}, expireSeconds int) (bool, error)
	SAdd(key string, member ...interface{}) (int64, error)
	SMembers(key string) ([]string, error)
	HMSet(key string, propMap map[string]interface{}, expireSeconds int) (ok bool, err error)
	HDelete(key string, properties ...string) error
	HGetAll(key string) (items map[string]string, err error)
	ZAdd(key string, score float64, member interface{}) error
	ZRemRangeByScore(key string, minScore float64, maxScore float64) error
	ZRangeByScoreWithScores(key string, minScore *float64, maxScore *float64, count *int64, offset *int64) ([]redis.Z, error)
}

type redisConn struct {
	_valid    bool
	_client   redis.UniversalClient
	_cnString string
}

func parseRedisCn(cn string) (*redis.UniversalOptions, error) {
	var (
		arr  = strings.Split(cn, " ")
		addr = make([]string, 0)
		pwd  = ""
		ts   = 0
	)
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

	cfg := redis.UniversalOptions{Addrs: addr}
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

func CreateRedisConnection(cnString string) (RedisConnection, error) {
	cfg, e := parseRedisCn(cnString)
	if e != nil {
		return nil, e
	}
	client := redis.NewUniversalClient(cfg)

	rv := new(redisConn)
	rv._valid = true
	rv._cnString = cnString
	rv._client = client
	return rv, nil
}

func (rc *redisConn) IsValid() bool {
	if rc == nil {
		return false
	}
	return rc._valid
}

func (rc *redisConn) ConnectionString() string {
	if rc == nil {
		return ""
	}
	return rc._cnString
}

func (rc *redisConn) Client() redis.UniversalClient {
	if rc == nil {
		return nil
	}
	return rc._client
}

func (rc *redisConn) Ping() error {
	if pong, err := rc._client.Ping().Result(); err != nil {
		return err
	} else if len(pong) == 0 {
		return redis.Nil
	} else {
		return nil
	}
}

func (rc *redisConn) Set(key string, value interface{}, expireSeconds int) (string, error) {
	if rc == nil || rc._client == nil || key == "" {
		return "", errors.New("Redis Connection or Key is empty")
	}

	result := rc._client.Set(key, value, time.Duration(expireSeconds)*time.Second)
	return result.Result()
}

func (rc *redisConn) Exists(keys ...string) (int64, error) {
	if rc == nil || rc._client == nil || len(keys) == 0 {
		return 0, errors.New("Redis Connection or Key is empty")
	}

	result := rc._client.Exists(keys...)
	return result.Result()
}

func (rc *redisConn) Get(key string) (string, error) {
	if rc == nil || rc._client == nil || key == "" {
		return "", errors.New("Redis Connection or Key is empty")
	}

	result := rc._client.Get(key)
	return result.Result()
}

func (rc *redisConn) Delete(keys ...string) (int64, error) {
	if rc == nil || rc._client == nil || len(keys) == 0 {
		return 0, errors.New("Redis Connection or keys is empty")
	}

	result := rc._client.Del(keys...)
	return result.Result()
}

func (rc *redisConn) Expire(key string, seconds int) (bool, error) {
	if rc == nil || rc._client == nil || key == "" {
		return false, errors.New("Redis Connection or Key is empty")
	}

	result := rc._client.Expire(key, time.Duration(seconds)*time.Second)
	return result.Result()
}

func (rc *redisConn) SetNX(key string, value interface{}, expireSeconds int) (bool, error) {
	if rc == nil || rc._client == nil || key == "" {
		return false, errors.New("redis Connection or Key is empty")
	}

	result := rc._client.SetNX(key, value, time.Duration(expireSeconds)*time.Second)
	return result.Result()
}

func (rc *redisConn) SAdd(key string, member ...interface{}) (int64, error) {
	if rc == nil || rc._client == nil || key == "" {
		return 0, errors.New("redis Connection or Key is empty")
	}

	result := rc._client.SAdd(key, member...)
	return result.Result()
}

func (rc *redisConn) SMembers(key string) ([]string, error) {
	if rc == nil || rc._client == nil || key == "" {
		return nil, errors.New("Redis Connection or Key is empty")
	}

	result := rc._client.SMembers(key)
	if result.Err() != nil {
		return nil, result.Err()
	}
	return result.Val(), nil
}

func (rc *redisConn) HMSet(key string, propMap map[string]interface{}, expireSeconds int) (ok bool, err error) {
	if rc == nil || rc._client == nil || key == "" || len(propMap) == 0 {
		return false, errors.New("Redis Connection or KeyValue is empty")
	}

	result := rc._client.HMSet(key, propMap)
	if result.Err() != nil {
		return false, result.Err()
	}

	if expireSeconds > 0 {
		expResult := rc._client.Expire(key, time.Duration(expireSeconds)*time.Second)

		if expResult.Err() != nil {
			return false, expResult.Err()
		}
	}
	return true, nil
}

func (rc *redisConn) HDelete(key string, properties ...string) error {
	if rc == nil || rc._client == nil || key == "" {
		return errors.New("Redis Connection or Key is empty")
	}

	result := rc._client.HDel(key, properties...)
	if result.Err() != nil {
		return result.Err()
	}
	return nil
}

func (rc *redisConn) HGetAll(key string) (items map[string]string, err error) {
	if rc == nil || rc._client == nil || key == "" {
		return nil, errors.New("Redis Connection or Key is empty")
	}

	result := rc._client.HGetAll(key)
	if result.Err() != nil {
		return nil, result.Err()
	}

	items, err = result.Result()
	if err != nil {
		return nil, err
	}
	return items, nil
}

func (rc *redisConn) ZAdd(key string, score float64, member interface{}) error {
	if rc == nil || rc._client == nil || key == "" {
		return errors.New("Redis Connection or Key is empty")
	}

	result := rc._client.ZAdd(key, redis.Z{Score: score, Member: member})
	if result.Err() != nil {
		return result.Err()
	}
	return nil
}

func (rc *redisConn) ZRemRangeByScore(key string, minScore float64, maxScore float64) error {
	if rc == nil || rc._client == nil || key == "" {
		return errors.New("Redis Connection or Key is empty")
	}

	minScoreStr := strconv.FormatFloat(minScore, 'f', -1, 64)
	maxScoreStr := strconv.FormatFloat(maxScore, 'f', -1, 64)
	result := rc._client.ZRemRangeByScore(key, minScoreStr, maxScoreStr)

	if result.Err() != nil {
		return result.Err()
	}
	return nil
}

func (rc *redisConn) ZRangeByScoreWithScores(key string, minScore *float64, maxScore *float64, count *int64, offset *int64) ([]redis.Z, error) {
	if rc == nil || rc._client == nil || key == "" {
		return nil, errors.New("Redis Connection or Key is empty")
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

	result := rc._client.ZRangeByScoreWithScores(key, redis.ZRangeBy{
		Min:    minScoreStr,
		Max:    maxScoreStr,
		Count:  countParam,
		Offset: offsetParam,
	})
	if result.Err() != nil {
		return nil, result.Err()
	}
	return result.Result()
}
