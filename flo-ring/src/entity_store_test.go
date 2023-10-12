package main

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/go-redis/redis"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

// white box test
func TestUserIdCrud(t *testing.T) {
	ctx := context.Background()
	var (
		repo       = initTestRepo(t)
		uid        = strings.ToUpper(uuid.New().String())
		found, err = repo.userExistsPg(uid)
	)
	assert.Nil(t, err)
	assert.False(t, found)

	found, err = repo.userExistsRedis(ctx, uid)
	assert.Equal(t, redis.Nil, err)
	assert.False(t, found)

	found, err = repo.userExistsPg(uid)
	assert.Nil(t, err)
	assert.False(t, found)

	found, err = repo.UserExists(ctx, uid)
	assert.Nil(t, err)
	assert.False(t, found)
	time.Sleep(time.Second / 2) //wait for redis write

	found, err = repo.userExistsRedis(ctx, uid)
	assert.Nil(t, err)
	assert.False(t, found)

	assert.Nil(t, repo.StoreUser(ctx, uid))
	time.Sleep(time.Second / 2) //wait for redis write

	found, err = repo.UserExists(ctx, uid)
	assert.Nil(t, err)
	assert.True(t, found)
	found, err = repo.UserExists(ctx, strings.ToLower(uid))
	assert.Nil(t, err)
	assert.True(t, found)

	found, err = repo.userExistsRedis(ctx, uid)
	assert.Nil(t, err)
	assert.True(t, found)
	found, err = repo.userExistsRedis(ctx, strings.ToLower(uid))
	assert.Nil(t, err)
	assert.True(t, found)

	found, err = repo.userExistsPg(uid)
	assert.Nil(t, err)
	assert.True(t, found)
	found, err = repo.userExistsPg(strings.ToLower(uid))
	assert.Nil(t, err)
	assert.True(t, found)
}

func initTestRepo(t *testing.T) *entityStore {
	ctx := context.Background()
	redis, redisErr := CreateRedisConnection(getEnvOrExit("FLO_REDIS_CN"))
	assert.Nil(t, redisErr)
	assert.Nil(t, redis.Ping(ctx))

	pg, pgErr := CreatePgSqlDb(getEnvOrExit("FLO_PGDB_CN"))
	assert.Nil(t, pgErr)
	assert.Nil(t, pg.Ping(context.Background()))

	repo := CreateEntityStore(_log, redis, pg)
	assert.NotNil(t, repo)
	res := repo.(*entityStore)
	assert.NotNil(t, res)

	_entityStoreKeyDur.Reset() //reset duration check
	return res
}

func TestDeviceIdMacCrud(t *testing.T) {
	ctx := context.Background()
	var (
		repo       = initTestRepo(t)
		ogDid      = strings.ToUpper(uuid.New().String())
		ogMac      = strings.ReplaceAll(ogDid, "-", "")[:12]
		dev        = Device{Id: ogDid, MacAddress: ogMac}
		found, err = repo.DeviceExists(ctx, ogDid, ogMac)
		mac, did   string
		count      int64
	)
	assert.Nil(t, err)
	assert.False(t, found)

	notFound := func() {
		mac, err = repo.getDeviceMacPg(ogDid)
		assert.Nil(t, err)
		assert.Empty(t, mac)
		mac, err = repo.GetDeviceMacById(ctx, ogDid)
		assert.Nil(t, err)
		assert.Empty(t, mac)

		did, err = repo.getDeviceIdPg(ogMac)
		assert.Nil(t, err)
		assert.Empty(t, did)
		did, err = repo.GetDeviceIdByMac(ctx, ogMac)
		assert.Nil(t, err)
		assert.Empty(t, did)

		found, err = repo.DeviceExists(ctx, ogDid, ogMac)
		assert.Nil(t, err)
		assert.False(t, found)
		found, err = repo.DeviceExists(ctx, ogDid, "")
		assert.Nil(t, err)
		assert.False(t, found)
		found, err = repo.DeviceExists(ctx, "", ogMac)
		assert.Nil(t, err)
		assert.False(t, found)
	}
	notFound() //ensure device not found

	assert.Nil(t, repo.StoreDevices(ctx, &dev)) //save
	time.Sleep(time.Second / 2)

	mac, err = repo.getDeviceMacPg(ogDid) //ensure found
	assert.Nil(t, err)
	assert.True(t, strings.EqualFold(ogMac, mac))
	mac, err = repo.GetDeviceMacById(ctx, ogDid)
	assert.Nil(t, err)
	assert.True(t, strings.EqualFold(ogMac, mac))

	did, err = repo.getDeviceIdPg(ogMac)
	assert.Nil(t, err)
	assert.True(t, strings.EqualFold(ogDid, did))
	did, err = repo.GetDeviceIdByMac(ctx, ogMac)
	assert.Nil(t, err)
	assert.True(t, strings.EqualFold(ogDid, did))

	found, err = repo.DeviceExists(ctx, ogDid, ogMac)
	assert.Nil(t, err)
	assert.True(t, found)
	found, err = repo.DeviceExists(ctx, ogDid, "")
	assert.Nil(t, err)
	assert.True(t, found)
	found, err = repo.DeviceExists(ctx, "", ogMac)
	assert.Nil(t, err)
	assert.True(t, found)

	count, err = repo.DeleteDevices(ctx, &dev) //remove
	assert.Nil(t, err)
	assert.Equal(t, int64(1), count)
	time.Sleep(time.Second / 2)

	notFound() //ensure not found
}
