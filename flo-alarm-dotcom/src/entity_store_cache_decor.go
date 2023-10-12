package main

import (
	"encoding/json"
	"fmt"
	"github.com/go-redis/redis"
	"strconv"
	"strings"
)

// CreateEntityStoreCache return a decorated repo interface with redis read through cache applied
func CreateEntityStoreCache(base EntityStore, red RedisConnection, log Log) EntityStore {
	sec, _ := strconv.ParseInt(getEnvOrDefault("FLO_ENTITY_REDIS_TTLS", "3600"), 10, 64)
	return &entityCache{base, red, log, int(ClampInt64(sec, 60, 86_400))} //1day max
}

type entityCache struct {
	base EntityStore
	red  RedisConnection
	log  Log
	ttls int
}

func (ec *entityCache) Ping() (e error) {
	if e = ec.red.Ping(); e == nil {
		e = ec.base.Ping()
	}
	ec.log.IfErrorF(e, "Ping")
	return
}

func (ec *entityCache) key(usrId string) string {
	return fmt.Sprintf("adc:ur:{%v}", strings.ToLower(usrId))
}

func (ec *entityCache) popCache(usrId string) {
	panicRecover(ec.log, "popCache uid=%v", usrId)
	key := ec.key(usrId)
	if n, e := ec.red.Delete(key); e != nil {
		ec.log.IfWarnF(e, "popCache: %q", key)
	} else {
		ec.log.Trace("popCache: %q OK n=%v", key, n)
	}
}

func (ec *entityCache) Save(usr *LinkedUser) (bool, error) {
	if usr != nil && usr.UserId != "" {
		go ec.popCache(usr.UserId) //always pop cache, no harm in it even if save fail
	}
	return ec.base.Save(usr)
}

func (ec *entityCache) Get(usrId string, sync bool) (res *LinkedUser, e error) {
	var key string
	if usrId != "" && !sync {
		key = ec.key(usrId)
		var js string
		if js, e = ec.red.Get(key); e == nil {
			if jl := len(js); jl >= 2 && js[0] == '{' && js[jl-1] == '}' {
				lnk := LinkedUser{}
				if e = json.Unmarshal([]byte(js), &lnk); e == nil && strings.EqualFold(lnk.UserId, usrId) {
					ec.log.Trace("Get: %q FROM_CACHE", key)
					return &lnk, nil
				}
			}
		}
		if e != nil && e != redis.Nil {
			ec.log.IfErrorF(e, "Get: %q", key)
			return
		}
	}
	if res, e = ec.base.Get(usrId, sync); e == nil {
		if res != nil && strings.EqualFold(res.UserId, usrId) {
			go ec.pushCache(res) //async write for quicker response
		}
	}
	return
}

func (ec *entityCache) pushCache(res *LinkedUser) {
	panicRecover(ec.log, "pushCache %v", res)
	key := ec.key(res.UserId)
	if js, er := json.Marshal(res); er != nil {
		ec.log.IfWarnF(er, "pushCache: %q marshal", key)
	} else if _, er = ec.red.Set(key, string(js), ec.ttls); er != nil {
		ec.log.IfWarnF(er, "pushCache: %q redis set", key)
	} else {
		ec.log.Trace("pushCache: %q OK | %v", key, res)
	}
}

func (ec *entityCache) Delete(usrId string) (bool, error) {
	if usrId != "" { //always pop cache, no harm in it even if delete fail
		go ec.popCache(usrId)
	}
	return ec.base.Delete(usrId)
}
