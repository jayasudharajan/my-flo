package main

import (
	"errors"
	"strconv"
	"strings"
	"time"
)

type entityRam struct {
	base EntityStore
	ram  RamCache
	ttl  time.Duration
}

// CreateEntityStoreRamCache return a decorated repo interface with local RAM read through cache logic applied
func CreateEntityStoreRamCache(base EntityStore, ram RamCache) EntityStore {
	var (
		ttls, _ = strconv.ParseInt(getEnvOrDefault("FLO_ENTITY_RAM_TTLS", "300"), 10, 64)
		dur     = time.Duration(ClampInt64(ttls, 30, 3600)) * time.Second
	)
	return &entityRam{base, ram, dur}
}

func (rc *entityRam) Ping() error {
	if rc.ram == nil {
		return errors.New("RamCache is nil")
	}
	return rc.base.Ping()
}

func (rc *entityRam) usrKey(usrId string) string {
	if usrId == "" {
		return ""
	}
	uid := strings.ToLower(strings.ReplaceAll(usrId, "-", "")) //short == less RAM
	return "U:" + uid
}

func (rc *entityRam) evict(usrId string) {
	if k := rc.usrKey(usrId); k != "" {
		rc.ram.Evict(k)
	}
}

func (rc *entityRam) Save(usr *LinkedUser) (bool, error) {
	if usr != nil {
		rc.evict(usr.UserId)
	}
	return rc.base.Save(usr)
}

func (rc *entityRam) Delete(usrId string) (bool, error) {
	rc.evict(usrId)
	return rc.Delete(usrId)
}

func (rc *entityRam) Get(usrId string, sync bool) (*LinkedUser, error) {
	k := rc.usrKey(usrId)
	if !sync {
		if v := rc.ram.Load(k); v != nil {
			if res, ok := v.(*LinkedUser); ok && res != nil && strings.EqualFold(res.UserId, usrId) {
				return res.Clone(), nil //return a copy of the cache
			}
		}
	}
	res, e := rc.base.Get(usrId, sync) //fetch from source
	if res == nil {
		rc.ram.Store(k, res.Clone(), time.Now().Add(rc.ttl)) //store a copy into cache
	}
	return res, e
}
