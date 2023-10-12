package main

// Redis wrapper for a CLUSTERED redis connection.

import (
	"context"
	"errors"
	"time"

	"github.com/go-redis/redis/v8"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
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

func newRedisConnection(ctx context.Context, cnString string) (*RedisConnection, error) {

	client := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs: []string{cnString},
	})
	tracing.WrapInstaredisClusterClient(client, tracing.Instana)

	pong, err := client.Ping(ctx).Result()

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

func (obj *RedisConnection) Set(ctx context.Context, key string, value interface{}, expireSeconds int) (string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return "", errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.Set(ctx, key, value, time.Duration(expireSeconds)*time.Second)
	return result.Result()
}

func (obj *RedisConnection) Get(ctx context.Context, key string) (string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return "", errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.Get(ctx, key)
	return result.Result()
}

func (obj *RedisConnection) Delete(ctx context.Context, key string) (int64, error) {
	if obj == nil || obj._client == nil || key == "" {
		return 0, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.Del(ctx, key)

	return result.Result()
}

func (obj *RedisConnection) Expire(ctx context.Context, key string, seconds int) (bool, error) {
	if obj == nil || obj._client == nil || key == "" {
		return false, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.Expire(ctx, key, time.Duration(seconds)*time.Second)

	return result.Result()
}

func (obj *RedisConnection) SetNX(ctx context.Context, key string, value interface{}, expireSeconds int) (bool, error) {
	if obj == nil || obj._client == nil || key == "" {
		return false, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SetNX(ctx, key, value, time.Duration(expireSeconds)*time.Second)

	return result.Result()
}

func (obj *RedisConnection) SAdd(ctx context.Context, key string, member ...interface{}) error {
	if obj == nil || obj._client == nil || key == "" {
		return errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SAdd(ctx, key, member...)

	if result.Err() != nil {
		return result.Err()
	}

	return nil
}

func (obj *RedisConnection) SMembers(ctx context.Context, key string) ([]string, error) {
	if obj == nil || obj._client == nil || key == "" {
		return nil, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.SMembers(ctx, key)

	if result.Err() != nil {
		return nil, result.Err()
	}

	return result.Val(), nil
}

func (obj *RedisConnection) HMSet(ctx context.Context, key string, propMap map[string]interface{}, expireSeconds int) (ok bool, err error) {
	if obj == nil || obj._client == nil || key == "" || len(propMap) == 0 {
		return false, errors.New("Redis Connection or KeyValue is empty")
	}

	result := obj._client.HMSet(ctx, key, propMap)

	if result.Err() != nil {
		return false, result.Err()
	}

	if expireSeconds > 0 {
		expResult := obj._client.Expire(ctx, key, time.Duration(expireSeconds)*time.Second)

		if expResult.Err() != nil {
			return false, expResult.Err()
		}
	}

	return true, nil
}

func (obj *RedisConnection) HDelete(ctx context.Context, key string, properties ...string) error {
	if obj == nil || obj._client == nil || key == "" {
		return errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.HDel(ctx, key, properties...)

	if result.Err() != nil {
		return result.Err()
	}

	return nil
}

func (obj *RedisConnection) HGetAll(ctx context.Context, key string) (items map[string]string, err error) {
	if obj == nil || obj._client == nil || key == "" {
		return nil, errors.New("Redis Connection or Key is empty")
	}

	result := obj._client.HGetAll(ctx, key)

	if result.Err() != nil {
		return nil, result.Err()
	}

	items, err = result.Result()

	if err != nil {
		return nil, err
	}

	return items, nil
}
