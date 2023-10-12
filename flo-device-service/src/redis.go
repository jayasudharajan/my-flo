package main

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/labstack/gommon/log"
	"github.com/pkg/errors"
)

const expirationInSecondsSadd = 60
const expirationInSecondsGetSet = 1800

var expSadd = time.Duration(expirationInSecondsSadd) * time.Second
var expGetSet = time.Duration(expirationInSecondsGetSet) * time.Second

// DeviceRepository is the device redis repository
type RedisDeviceRepository struct {
	Redis *redis.ClusterClient
}

// GetSetDeviceConnectivity returns true if the connectivityFlagStr which already been written to Redis has been overwritten
// by the connectivityFlagStr passed in
func (r *RedisDeviceRepository) GetSetDeviceConnectivity(ctx context.Context, deviceId string, connectivityFlag bool) (bool, error) {
	if r.Redis != nil {
		key := r.GetDeviceConnectivityKey(deviceId)
		log.Debugf("redis connectivity key is %s", key)
		connectivityFlagStr := strconv.FormatBool(connectivityFlag)

		strCmd := r.Redis.GetSet(ctx, key, connectivityFlagStr)
		if strCmd == nil {
			return false, fmt.Errorf("failed to execute GetSetDeviceConnectivity for deviceId_%s, redis strCmd is nil", deviceId)
		} else {
			returnedConnectivityFlagStr, err := strCmd.Result()
			if err != nil {
				if err.Error() == "redis: nil" {
					log.Debugf("initial getset redis call for the key %s", key)
					err = r.Redis.Expire(ctx, key, expGetSet).Err()
					if err != nil {
						log.Errorf("redis expire call failed, err: %v", err)
					}
					return true, nil
				}
				return false, fmt.Errorf("failed to execute GetSetDeviceConnectivity for deviceId_%s, err: %v", deviceId,
					err)
			}
			if returnedConnectivityFlagStr == connectivityFlagStr {
				return false, nil
			}
			err = r.Redis.Expire(ctx, key, expGetSet).Err()
			if err != nil {
				log.Errorf("redis expire call failed, err: %v", err)
			}
			return true, nil
		}
	}
	return false, fmt.Errorf("failed to execute GetSetDeviceConnectivity for deviceId_%s, redis repository is nil", deviceId)
}

func (r *RedisDeviceRepository) SaveDevicePresence(ctx context.Context, deviceIds []string) error {
	keys := r.GetDevicePresenceKeys()
	log.Debugf("redis presence keys are %, deviceIds are %s", strings.Join(keys, ","), strings.Join(deviceIds, ","))
	for _, key := range keys {
		err := r.Redis.SAdd(ctx, key, deviceIds).Err()
		if err != nil {
			return err
		}
		err = r.Redis.Expire(ctx, key, expSadd).Err()
		if err != nil {
			log.Errorf("redis expire call failed, err: %v", err)
		}
		log.Debugf("saved device ids %s to redis set with %s key, expiration %d nanoseconds",
			strings.Join(deviceIds, ","), key, expSadd)
	}
	return nil
}

// GetDevicesPresence retrieves the set of device ids which end-users have started interaction with client (web, mobile) applications
func (r *RedisDeviceRepository) GetDevicesPresence(ctx context.Context) ([]string, error) {
	var result []string
	setMap := make(map[string]bool)
	keys := r.GetDevicePresenceKeys()
	for _, key := range keys {
		deviceIds, err := r.Redis.SMembers(ctx, key).Result()
		if err != nil {
			return nil, err
		}
		for _, deviceId := range deviceIds {
			setMap[deviceId] = true
		}
	}

	for k := range setMap {
		result = append(result, k)
	}

	return result, nil
}

func (r *RedisDeviceRepository) DeleteKeys(ctx context.Context, keys []string) (int64, error) {
	c := r.Redis.Del(ctx, keys...)
	return c.Result()
}

func (r *RedisDeviceRepository) GetDeviceCachedData(ctx context.Context, deviceId string) (map[string]string, error) {
	key := r.GetDeviceCacheKey(deviceId)
	return r.Redis.HGetAll(ctx, key).Result()
}

func (r *RedisDeviceRepository) SetDeviceCachedData(ctx context.Context, deviceId string, propMap map[string]interface{}) (ok bool, err error) {
	if r == nil || r.Redis == nil || len(deviceId) != 12 || len(propMap) == 0 {
		return false, errors.New("Redis Connection or KeyValue is empty")
	}
	key := r.GetDeviceCacheKey(deviceId)

	result := r.Redis.HMSet(ctx, key, propMap)

	if result.Err() != nil {
		return false, result.Err()
	}

	return true, nil
}

func (r *RedisDeviceRepository) GetDeviceCacheKey(deviceId string) string {
	return fmt.Sprintf("deviceCache:%s", deviceId)
}

func (r *RedisDeviceRepository) GetDeviceConnectivityKey(deviceId string) string {
	return fmt.Sprintf("device:connectivity:%s", deviceId)
}

func (r *RedisDeviceRepository) GetRealTimeTelemetryExpirationKey(deviceId string) string {
	return fmt.Sprintf("device:telemetryExpiration:%s", deviceId)
}

func (r *RedisDeviceRepository) IsRealTimeTelemetryPeriodExpired(ctx context.Context, deviceId string) (bool, error) {
	result, err := r.Redis.SetNX(ctx, r.GetRealTimeTelemetryExpirationKey(deviceId), time.Now().UnixNano(), time.Duration(fwProperties_TelemetryRealtimeTimeoutSeconds/3)*time.Second).Result()
	if err != nil {
		return false, err
	}

	return result, nil
}

// GetDevicePresenceKeys is crucial function to compile the redis keys, it has to be the same as in device-service
func (r *RedisDeviceRepository) GetDevicePresenceKeys() []string {
	var result []string
	tNow := time.Now().Minute()
	tBefore := tNow - 1
	if tBefore == -1 {
		tBefore = 59
	}
	tAfter := tNow + 1
	if tAfter == 60 {
		tAfter = 0
	}

	keyTBefore := fmt.Sprintf("devices:presence:%d", tBefore)
	keyTNow := fmt.Sprintf("devices:presence:%d", tNow)
	keyTAfter := fmt.Sprintf("devices:presence:%d", tAfter)

	result = append(result, keyTBefore)
	result = append(result, keyTNow)
	result = append(result, keyTAfter)
	return result
}
