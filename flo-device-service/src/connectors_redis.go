package main

import (
	"context"

	"github.com/go-redis/redis/v8"
	"github.com/instana/go-sensor/instrumentation/instaredis"
)

var RedisClient *redis.ClusterClient

func InitializeRedis() (*redis.ClusterClient, error) {
	RedisClient = redis.NewClusterClient(&redis.ClusterOptions{
		Addrs: []string{RedisConnection},
	})

	// ref: https://pkg.go.dev/github.com/instana/go-sensor/instrumentation/instaredis#section-readme
	instaredis.WrapClusterClient(RedisClient, _instana)

	_, err := RedisClient.Ping(context.Background()).Result()
	if err != nil {
		return nil, err
	}
	return RedisClient, nil
}
