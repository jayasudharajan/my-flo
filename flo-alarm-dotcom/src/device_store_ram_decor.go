package main

import (
	"errors"
	"strconv"
	"strings"
	"time"
)

// deviceRam decorates DeviceStore with a relational read-through cache for max performance
// because Kafka partition will deliver the same shard of data (same userId or deviceId) to the same container/service instance
// it makes sense to use local relational cache for max performance with Kafka stream processing where the client do all filtering
type deviceRam struct {
	base DeviceStore
	ram  RamCache
	ttl  time.Duration
}

func CreateDeviceStoreRam(base DeviceStore, ram RamCache) DeviceStore {
	var (
		ttls, _ = strconv.ParseInt(getEnvOrDefault("FLO_DEVICE_RAM_TTLS", "300"), 10, 64)
		dur     = time.Duration(ClampInt64(ttls, 30, 3600)) * time.Second
	)
	return &deviceRam{base, ram, dur}
}

func (dr *deviceRam) Ping() error {
	if dr.ram == nil {
		return errors.New("RamCache is nil")
	}
	return dr.base.Ping()
}

func (dr *deviceRam) GetById(deviceId string, sync bool) (res *LinkedDevice, e error) {
	k := dr.didKey(deviceId) //simple key -> value cache, value is *LinkedDevice
	if !sync && k != "" {
		if raw := dr.ram.Load(k); raw != nil {
			var ok bool
			if res, ok = raw.(*LinkedDevice); ok && res != nil {
				return res.Clone(), nil //clone the cache before returning
			}
		}
	}
	if res, e = dr.base.GetById(deviceId, sync); k != "" && e == nil && res != nil { //fetch from source of truth
		dr.cacheDeep(res)
	}
	return
}

func (dr *deviceRam) GetByMac(mac string, sync bool) (res *LinkedDevice, e error) {
	k := dr.macKey(mac) //simple key -> value, value is deviceId string
	if !sync && k != "" {
		if rawDid := dr.ram.Load(k); rawDid != nil {
			if did, ok := rawDid.(string); ok && did != "" {
				if rawDev := dr.ram.Load(dr.didKey(did)); rawDev != nil {
					if res, ok = rawDev.(*LinkedDevice); ok && res != nil {
						return res.Clone(), nil //return a copy from cache
					}
				}
			}
			dr.ram.Evict(k) //evict asap to save other threads work
		}
	}
	if res, e = dr.base.GetByMac(mac, sync); k != "" && e == nil && res != nil {
		dr.cacheDeep(res)
	}
	return
}

func (dr *deviceRam) GetByUserId(userId string, sync bool) (res []*LinkedDevice, e error) {
	k := dr.uidKey(userId) //key -> value cache, value is array of deviceIds
	if !sync && k != "" {
		if raw := dr.ram.Load(k); raw != nil {
			if didArr, ok := raw.([]string); ok && didArr != nil {
				res = make([]*LinkedDevice, 0) //init blank arr
				for _, did := range didArr {
					if rawDevice := dr.ram.Load(dr.didKey(did)); rawDevice != nil {
						if device, good := rawDevice.(*LinkedDevice); good && device != nil {
							res = append(res, device.Clone()) //collect a copy of the cached data
						}
					}
				}
				if len(didArr) == len(res) {
					return //found everything, return from cache (even if array is empty
				} else {
					res = nil //clear partial result, will fetch from source
				}
			}
			dr.ram.Evict(k) //evict asap to save other threads work
		}
	}
	if res, e = dr.base.GetByUserId(userId, sync); k != "" && e == nil && res != nil {
		didArr := make([]string, 0)
		for _, d := range res {
			if d == nil || d.Id == "" {
				continue
			}
			dr.cacheDeep(d)
			didArr = append(didArr, d.Id) //build userId array
		}
		dr.ram.Store(dr.uidKey(userId), didArr, time.Now().Add(dr.ttl)) //store in ram cache usrId -> array of device Ids
	}
	return
}

func (dr *deviceRam) Save(devices ...*LinkedDevice) error {
	for _, d := range devices {
		dr.evictDeep(d)
	}
	return dr.base.Save(devices...)
}

func (dr *deviceRam) didKey(deviceId string) string {
	if deviceId == "" {
		return ""
	}
	return "did:" + strings.ToLower(strings.ReplaceAll(deviceId, "-", ""))
}

func (dr *deviceRam) macKey(mac string) string {
	if mac == "" {
		return ""
	}
	return "mac:" + strings.ToLower(mac)
}

func (dr *deviceRam) uidKey(usrId string) string {
	if usrId == "" {
		return ""
	}
	return "uid:" + strings.ToLower(strings.ReplaceAll(usrId, "-", ""))
}

func (dr *deviceRam) cacheDeep(d *LinkedDevice) {
	if d == nil || d.Id == "" {
		return //ignore bad input
	}
	defer panicRecover(_log, "deviceRam.cacheDeep: %v", d)
	exp := time.Now().Add(dr.ttl)
	dr.ram.Store(dr.didKey(d.Id), d.Clone(), exp)
	dr.ram.Store(dr.macKey(d.Mac), d.Id, exp)
	//NOTE: we are not storing userId cache here, we don't know the missing id b/c maybe only 1 item is load & not all belonging to same user!
	//since did & mac maps 1-1, it's safe to also cache related item too.  evictDeep takes care of nuking both
}

func (dr *deviceRam) evictDeep(d *LinkedDevice) {
	if d == nil || d.Id == "" {
		return //do nothing, bad input
	}
	defer panicRecover(_log, "deviceRam.evictDeep: %v", d)
	keys := []string{
		dr.didKey(d.Id),
		dr.macKey(d.Mac),
		dr.uidKey(d.UserId),
	}
	for _, k := range keys {
		if k == "" {
			continue
		}
		dr.ram.Evict(k)
	}
}

func (dr *deviceRam) DeleteById(deviceId string) error {
	if k := dr.didKey(deviceId); k != "" { //simple key -> value cache, value is *LinkedDevice
		if raw := dr.ram.Load(k); raw != nil { //if we can't find a copy in cache, it's probably already evicted
			if dev, ok := raw.(*LinkedDevice); ok && dev != nil {
				dr.evictDeep(dev)
			} else {
				dr.ram.Evict(k) //not sure why it won't cast, evict anyway
			}
		}
	}
	return dr.base.DeleteById(deviceId)
}

func (dr *deviceRam) DeleteByUserId(userId string) error {
	if k := dr.uidKey(userId); k != "" { //key -> value cache, value is array of deviceIds
		dr.ram.Evict(k) //evict this pointer key now
		if rawArr := dr.ram.Load(k); rawArr != nil {
			if didArr, ok := rawArr.([]string); ok && didArr != nil {
				for _, did := range didArr {
					if didKey := dr.didKey(did); didKey != "" {
						if rawDev := dr.ram.Load(didKey); rawDev != nil {
							if device, good := rawDev.(*LinkedDevice); good && device != nil {
								dr.evictDeep(device) //deep eviction
							} else {
								dr.ram.Evict(didKey) //shallow eviction due to casting issues
							}
						}
					}
				}
			}
		}
	}
	return dr.base.DeleteByUserId(userId)
}
