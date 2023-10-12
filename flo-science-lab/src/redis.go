package main

// Redis wrapper for a CLUSTERED redis connection.

import (
	"errors"
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

func newRedisConnection(cnString string) (*RedisConnection, error) {

	client := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs: []string{cnString},
	})

	pong, err := client.Ping().Result()

	if err != nil {
		return nil, err
	}

	if len(pong) == 0 {
		return nil, errors.New("redis ping/pong failed")
	}

	rv := new(RedisConnection)
	rv._valid = true
	rv._cnString = cnString
	rv._client = client

	return rv, nil
}

func (obj *RedisConnection) Set(key string, value interface{}, expireSeconds int) (string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return "", errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.Set(key, value, time.Duration(expireSeconds)*time.Second)
	return result.Result()
}

func (obj *RedisConnection) Get(key string) (string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return "", errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.Get(key)
	return result.Result()
}

func (obj *RedisConnection) Delete(key string) (int64, error) {
	if obj == nil || obj._client == nil || key == "" {
		return 0, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.Del(key)

	return result.Result()
}

func (obj *RedisConnection) Expire(key string, seconds int) (bool, error) {
	if obj == nil || obj._client == nil || key == "" {
		return false, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.Expire(key, time.Duration(seconds)*time.Second)

	return result.Result()
}

func (obj *RedisConnection) SetNX(key string, value interface{}, expireSeconds int) (bool, error) {
	if obj == nil || obj._client == nil || key == "" {
		return false, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SetNX(key, value, time.Duration(expireSeconds)*time.Second)

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

func (obj *RedisConnection) HMSet(key string, propMap map[string]interface{}, expireSeconds int) (ok bool, err error) {
	if obj == nil || obj._client == nil || key == "" || len(propMap) == 0 {
		return false, errors.New("Redis Connection or KeyValue is empty")
	}

	result := obj._client.HMSet(key, propMap)

	if result.Err() != nil {
		return false, result.Err()
	}

	if expireSeconds > 0 {
		expResult := obj._client.Expire(key, time.Duration(expireSeconds)*time.Second)

		if expResult.Err() != nil {
			return false, expResult.Err()
		}
	}

	return true, nil
}

func (obj *RedisConnection) HDelete(key string, properties ...string) error {
	if obj == nil || obj._client == nil || key == "" {
		return errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.HDel(key, properties...)

	if result.Err() != nil {
		return result.Err()
	}

	return nil
}

func (obj *RedisConnection) HGetAll(key string) (items map[string]string, err error) {
	if obj == nil || obj._client == nil || key == "" {
		return nil, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.HGetAll(key)

	if result.Err() != nil {
		return nil, result.Err()
	}

	items, err = result.Result()

	if err != nil {
		return nil, err
	}

	return items, nil
}
