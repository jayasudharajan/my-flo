package main

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/stretchr/testify/assert"
)

func initTestReg() *registry {
	reg := registry{
		DefaultLogger(),
		CreateServiceLocator(),
		func() { os.Exit(1) },
	}
	reg.Stores()
	return reg.Utils().Services()
}

func mockAccountMap(iss string) AccountMap {
	return AccountMap{
		MoenId:        uuid.New().String(),
		FloId:         uuid.New().String(),
		Issuer:        iss,
		MoenAccountId: uuid.New().String(),
		FloAccountId:  uuid.New().String(),
	}
}

var ctx = context.Background()

func TestAccountSyncCRUD(t *testing.T) {
	var (
		reg  = initTestReg()
		sync = reg.sl.LocateName("SyncStore").(SyncStore)
		acc  = mockAccountMap("https://cognito-idp.us-west-2.amazonaws.com/us-west-2")
	)
	found, err := sync.Check(ctx, acc.MoenId, "")
	assert.Nil(t, err)
	assert.False(t, found)

	found, err = sync.Check(ctx, "", acc.FloId)
	assert.Nil(t, err)
	assert.False(t, found)

	err = sync.Save(ctx, &acc)
	assert.Nil(t, err)
	time.Sleep(time.Second)

	found, err = sync.Check(ctx, acc.MoenId, "")
	assert.Nil(t, err)
	assert.True(t, found)

	found, err = sync.Check(ctx, "", acc.FloId)
	assert.Nil(t, err)
	assert.True(t, found)
}

func TestAccountSyncGetMap(t *testing.T) {
	var (
		reg  = initTestReg()
		sync = reg.sl.LocateName("SyncStore").(SyncStore)
		acc  = mockAccountMap("https://cognito-idp.us-west-2.amazonaws.com/us-west-2")
	)
	accountMap, err := sync.GetMap(ctx, acc.MoenId, "", "")
	assert.NoError(t, err)
	assert.Nil(t, accountMap)

	accountMap, err = sync.GetMap(ctx, "", acc.FloId, "")
	assert.NoError(t, err)
	assert.Nil(t, accountMap)

	err = sync.Save(ctx, &acc)
	assert.NoError(t, err)
	time.Sleep(time.Second)

	accountMap, err = sync.GetMap(ctx, acc.MoenId, "", acc.Issuer)
	assert.NoError(t, err)
	accMapSame(t, &acc, accountMap)

	accountMap, err = sync.GetMap(ctx, "", acc.FloId, "")
	assert.NoError(t, err)
	accMapSame(t, &acc, accountMap)
}

func accMapSame(t *testing.T, a, b *AccountMap) {
	if a == nil {
		assert.Nil(t, b)
	} else {
		assert.NotNil(t, b)
		assert.Equal(t, a.FloId, b.FloId)
		assert.Equal(t, a.FloAccountId, b.FloAccountId)
		assert.Equal(t, a.MoenId, b.MoenId)
		assert.Equal(t, a.MoenAccountId, b.MoenAccountId)
		assert.Equal(t, a.Issuer, b.Issuer)
	}
}

func TestAccountSyncFetchDeep(t *testing.T) {
	var (
		reg  = initTestReg()
		sync = reg.sl.LocateName("SyncStore").(*syncStore)
		acc  = mockAccountMap("")
	)
	err := sync.Save(ctx, &acc)
	assert.Nil(t, err)
	time.Sleep(time.Second)

	match := func(ac *AccountMap, get func(ctx context.Context, check *AccountMap) (*AccountMap, error)) {
		r, e := get(ctx, ac)
		assert.Nil(t, e)
		assert.NotNil(t, r)
		accMapSame(t, &acc, r)
	}
	match(&AccountMap{MoenId: acc.MoenId}, sync.getPg)
	match(&AccountMap{FloId: acc.FloId}, sync.getPg)
	match(&AccountMap{MoenId: acc.MoenId}, sync.getRedis)
	match(&AccountMap{FloId: acc.FloId}, sync.getRedis)
}

func TestAccountSyncFetchIssuerDeep(t *testing.T) {
	var (
		reg  = initTestReg()
		sync = reg.sl.LocateName("SyncStore").(*syncStore)
		acc  = mockAccountMap("https://cognito-idp.us-west-2.amazonaws.com/us-west-2")
	)
	err := sync.Save(ctx, &acc)
	assert.Nil(t, err)
	time.Sleep(time.Second)

	match := func(ac *AccountMap, get func(ctx context.Context, check *AccountMap) (*AccountMap, error)) {
		r, e := get(ctx, ac)
		assert.Nil(t, e)
		assert.NotNil(t, r)
		accMapSame(t, &acc, r)
	}
	match(&AccountMap{MoenId: acc.MoenId, Issuer: acc.Issuer}, sync.getPg)
	match(&AccountMap{FloId: acc.FloId, Issuer: acc.Issuer}, sync.getPg)
	match(&AccountMap{MoenId: acc.MoenId, Issuer: acc.Issuer}, sync.getRedis)
	match(&AccountMap{FloId: acc.FloId, Issuer: acc.Issuer}, sync.getRedis)
}
