package main

// Redis wrapper for a CLUSTERED redis connection.

import (
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis"
)

type RedisConnection struct {
	_valid    bool
	_client   *redis.ClusterClient
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

func CreateRedisConnection(cnString string) (*RedisConnection, error) {
	cfg, e := parseRedisCn(cnString)
	if e != nil {
		return nil, e
	}
	client := redis.NewClusterClient(cfg)

	if pong, err := client.Ping().Result(); err != nil {
		return nil, err
	} else if len(pong) == 0 {
		return nil, errors.New("redis ping/pong failed")
	}

	rv := new(RedisConnection)
	rv._valid = true
	rv._cnString = cnString
	rv._client = client
	return rv, nil
}

func (obj *RedisConnection) Close() error {
	if obj == nil || obj._client == nil {
		return errors.New("Redis Connection or Key is empty")
	}
	return obj._client.Close()
}

func (obj *RedisConnection) Delete(keys ...string) (int64, error) {
	if obj == nil || obj._client == nil || len(keys) == 0 {
		return 0, errors.New("Redis Connection or keys is empty")
	}

	result := obj._client.Del(keys...)

	return result.Result()
}

func (obj *RedisConnection) SAdd(key string, member ...interface{}) error {
	if obj == nil || obj._client == nil || key == "" {
		return errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SAdd(key, member...)

	if result.Err() != nil {
		return result.Err()
	}

	return nil
}

func (obj *RedisConnection) SMembers(key string) ([]string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return nil, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SMembers(key)

	if result.Err() != nil {
		return nil, result.Err()
	}

	return result.Val(), nil
}

func (obj *RedisConnection) SCard(key string) (int64, error) {
	if obj == nil || obj._client == nil || key == "" {
		return 0, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SCard(key)

	return result.Result()
}

func (obj *RedisConnection) SPop(key string) (string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return "", errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SPop(key)

	return result.Result()
}

func (obj *RedisConnection) SetNX(key string, value interface{}, expireSeconds int) (bool, error) {
	if obj == nil || obj._client == nil || key == "" {
		return false, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SetNX(key, value, time.Duration(expireSeconds)*time.Second)

	return result.Result()
}

func parseRedisCn(cn string) (*redis.ClusterOptions, error) {
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

	cfg := redis.ClusterOptions{Addrs: addr}
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
