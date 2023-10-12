// +build unit

package main

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"strings"
	"testing"
)

func TestInitializeRedis(t *testing.T) {
	assert := assert.New(t)
	setup()

	t.Run("unit=InitializeRedisTest", func(t *testing.T) {
		r, err := InitializeRedis()
		assert.Nil(err)
		assert.NotNil(r)
	})

	// set presence, should see 3 records for the device Id
	// curl -v -d '{"userId":"ced46c02-d9a8-4599-a6b1-fce6d7ecd173"}' -H "Content-Type: application/json" -X POST https://flo-core-service-dev.flocloud.co/presence?userId=ced46c02-d9a8-4599-a6b1-fce6d7ecd173
	t.Run("unit=TestRedisGetPresence", func(t *testing.T) {
		for i := 0; i < 60; i++ {
			key := fmt.Sprintf("devices:presence:%d", i)
			result, err := RedisClient.SMembers(key).Result()
			assert.Nil(err)
			//if len(result) > 0 {
			println(fmt.Sprintf("for key %s, value is %s", key, strings.Join(result, ",")))
			//}
		}
	})

	t.Run("unit=TestRedisGetDeviceCache", func(t *testing.T) {
		devDevices := []string{"606405c0ea31", "38d269deb0b7", "606405c0d2db", "606405c10f25", "606405c10f25",
			"74e1821171a2", "74e182118881", "74e182167461", "74e1821697cc", "f045da2cc1ed", "f87aef010146"}
		for _, deviceId := range devDevices {
			result, err := RedisClient.HGetAll(fmt.Sprintf("deviceCache:%s", deviceId)).Result()
			assert.Nil(err)
			for k, v := range result {
				if k == "macAddress" {
					println(fmt.Sprintf("key deviceCache:%s is present", v))
				}
			}
		}
	})

	t.Run("unit=TestRedisMap", func(t *testing.T) {
        println("redis map")
		result, err := RedisClient.HGetAll(fmt.Sprintf("deviceCache:%s", "1")).Result()
		println(fmt.Sprintf("size of map with unknown key is %d", len(result)))
		println(fmt.Sprintf("value of map with unknown key is %v", result))
		assert.Nil(err)

	})

	t.Run("unit=TestRedisMap", func(t *testing.T) {
		println("redis map")
		result, err := RedisClient.HGetAll(fmt.Sprintf("deviceCache:%s", "1")).Result()
		println(fmt.Sprintf("size of map with unknown key is %d", len(result)))
		println(fmt.Sprintf("value of map with unknown key is %v", result))
		assert.Nil(err)

	})

	t.Run("unit=TestRedisMap", func(t *testing.T) {
		println("redis map")
		result, err := RedisClient.HGetAll(fmt.Sprintf("deviceCache:%s", "f4844c5f7531")).Result()
		println(fmt.Sprintf("size of map with potentially unknown key is %d", len(result)))
		println(fmt.Sprintf("value of map with potentially unknown key is %v", result))
		assert.Nil(err)

	})

}
