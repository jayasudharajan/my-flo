package main

import (
	"encoding/json"
	"fmt"
	"github.com/go-redis/redis"
	"strconv"
	"strings"
	"time"
)

type deviceCache struct {
	base DeviceStore
	red  RedisConnection
	log  Log
	ttls int
}

// CreateDeviceStoreCache return a decorator Device store that read & write through redis for mac/did ops,
// for userId op, it falls back to the underlining impl (source)
func CreateDeviceStoreCache(base DeviceStore, red RedisConnection, log Log) DeviceStore {
	sec, _ := strconv.ParseInt(getEnvOrDefault("FLO_DEVICE_REDIS_TTLS", "1800"), 10, 64)
	return &deviceCache{base, red, log, int(ClampInt64(sec, 30, 10_800))} //3h max
}

func (dc *deviceCache) Ping() (e error) {
	if e = dc.red.Ping(); e == nil {
		e = dc.base.Ping()
	}
	return
}

func (dc *deviceCache) cachePull(key string) *LinkedDevice {
	if js, er := dc.red.Get(key); er != nil {
		if er != redis.Nil {
			dc.log.IfWarnF(er, "red.Get: %v", key)
		}
	} else {
		cache := LinkedDevice{}
		if er = json.Unmarshal([]byte(js), &cache); er != nil {
			dc.log.IfWarnF(er, "unmarshal: %v | %s", key, js)
		} else {
			return &cache //cache hit
		}
	}
	return nil
}

func (dc *deviceCache) GetById(deviceId string, sync bool) (lnk *LinkedDevice, e error) {
	dc.log.PushScope("Get_did")
	defer dc.log.PopScope()

	if !sync && deviceId != "" { //attempt cache pull
		if cache := dc.cachePull(dc.didKey(deviceId)); cache != nil {
			return cache, nil
		}
	}
	if lnk, e = dc.base.GetById(deviceId, sync); e == nil && lnk != nil { //cache put on success
		go dc.cachePut(lnk)
	}
	return
}

func (dc *deviceCache) GetByMac(mac string, sync bool) (lnk *LinkedDevice, e error) {
	dc.log.PushScope("Get_mac")
	defer dc.log.PopScope()

	if !sync && mac != "" { //attempt cache pull
		if cache := dc.cachePull(dc.macKey(mac)); cache != nil {
			return cache, nil
		}
	}
	if lnk, e = dc.base.GetByMac(mac, sync); e == nil && lnk != nil { //cache put on success
		go dc.cachePut(lnk)
	}
	return
}

func (dc *deviceCache) GetByUserId(userId string, sync bool) ([]*LinkedDevice, error) {
	return dc.base.GetByUserId(userId, sync) //left as slow pass-through on purpose
}

func (dc *deviceCache) didKey(deviceId string) string {
	if deviceId == "" {
		return ""
	}
	k := strings.ToLower(strings.ReplaceAll(deviceId, "-", ""))
	return fmt.Sprintf("adc:dev:did:{%v}", k)
}

func (dc *deviceCache) macKey(mac string) string {
	if mac == "" {
		return ""
	}
	k := strings.ToLower(mac)
	return fmt.Sprintf("adc:dev:mac:{%v}", k)
}

func (dc *deviceCache) uidKey(userId string) string {
	if userId == "" {
		return ""
	}
	k := strings.ToLower(strings.ReplaceAll(userId, "-", ""))
	return fmt.Sprintf("adc:dev:uid:{%v}", k)
}

func (dc *deviceCache) cachePut(d *LinkedDevice) {
	if d == nil {
		return
	}
	defer panicRecover(dc.log, "cachePut: %v", d)
	dc.log.PushScope("$put")
	defer dc.log.PopScope()
	var (
		start = time.Now()
		did   = dc.didKey(d.Id)
		mac   = dc.macKey(d.Mac)
	)
	if buf, e := json.Marshal(d); e != nil {
		dc.log.IfWarnF(e, "marshal: %v", d)
	} else if did != "" && mac != "" { //we duplicate the cache, it's faster this way but uses more RAM to save network io
		ec := 0
		if _, e = dc.red.Set(mac, buf, dc.ttls); e != nil {
			ec++
			dc.log.IfErrorF(e, "red.Set: %v", mac)
		} //mac is saved first on purpose so that it would expire first before the did cache
		if _, e = dc.red.Set(did, buf, dc.ttls); e != nil {
			ec++
			dc.log.IfErrorF(e, "red.Set: %v", did)
		}
		if ec == 0 {
			dc.log.Debug("Set: OK %v took=%v", d, time.Since(start))
		}
	}
}

func (dc *deviceCache) cachePutBatch(devices ...*LinkedDevice) {
	for _, d := range devices {
		dc.cachePut(d)
	} //bc of key sharding, we can't use lower level batch, not worth the effort to do parallel here
}

func (dc *deviceCache) Save(devices ...*LinkedDevice) (e error) {
	dc.log.PushScope("Save")
	defer dc.log.PopScope()
	if e = dc.base.Save(devices...); e != nil {
		go dc.cachePutBatch(devices...) //batch on a thread
	}
	return
}

func (dc *deviceCache) cachePop(d *LinkedDevice) {
	if d == nil {
		return
	}
	defer panicRecover(dc.log, "cachePop: %v", d)
	dc.log.PushScope("$pop")
	defer dc.log.PopScope()
	var (
		start = time.Now()
		ec    = 0
	)
	if did := dc.didKey(d.Id); did != "" {
		if _, e := dc.red.Delete(did); e != nil && e != redis.Nil {
			ec++
			dc.log.IfWarnF(e, "red.Delete: %v", did)
		}
	}
	if mac := dc.macKey(d.Mac); mac != "" {
		if _, e := dc.red.Delete(mac); e != nil && e != redis.Nil {
			ec++
			dc.log.IfWarnF(e, "red.Delete: %v", mac)
		}
	}
	if ec == 0 {
		dc.log.Debug("Delete: OK %v took=%v", d, time.Since(start))
	}
}

func (dc *deviceCache) cachePopByDid(deviceId string) {
	defer panicRecover(dc.log, "cachePopByDid: %v", deviceId)
	dc.log.PushScope("$pop_did")
	defer dc.log.PopScope()

	if did := dc.didKey(deviceId); did != "" {
		if cache := dc.cachePull(did); cache != nil {
			dc.cachePop(cache)
		} else {
			dc.red.Delete(did) //pop the single key anyway
		}
	}
}

func (dc *deviceCache) DeleteById(deviceId string) (e error) {
	dc.log.PushScope("Delete_did")
	if e = dc.base.DeleteById(deviceId); e == nil {
		go dc.cachePopByDid(deviceId) //side thread
	} //only delete if src rm is OK, bc it maybe costly to pop cache this way
	return
}

func (dc *deviceCache) DeleteByUserId(userId string) error {
	return dc.base.DeleteByUserId(userId) //left as slow pass-through on purpose
}
