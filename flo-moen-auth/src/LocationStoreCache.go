package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/go-redis/redis/v8"
)

// locStoreCache decorates LocationStore with centralized redis read-through cache
type locStoreCache struct {
	inner LocationStore
	red   *RedisConnection
	log   *Logger
	ttl   time.Duration
}

func CreateLocationStoreCache(inner LocationStore, red *RedisConnection, log *Logger) LocationStore {
	ttl := time.Hour
	if d, _ := time.ParseDuration(getEnvOrDefault("FLO_LOC_REPO_CACHE_TTL", "")); d >= time.Minute && d <= time.Hour*24 {
		ttl = d
	}
	return &locStoreCache{inner, red, log.CloneAsChild("LocRepo$"), ttl}
}

func (lc *locStoreCache) convLocMatches(loc *SyncLoc) (res []*getLocMatch) {
	if loc != nil {
		if loc.FloId != "" {
			res = append(res, &getLocMatch{FloId: loc.FloId})
		}
		if loc.MoenId != "" {
			res = append(res, &getLocMatch{MoenId: loc.MoenId})
		}
		if loc.FloAccId != "" {
			res = append(res, &getLocMatch{FloAccId: loc.FloAccId})
		}
	}
	return
}

type printable interface {
	String() string
}

func (lc *locStoreCache) cacheKey(item printable) (k string) {
	if item == nil {
		k = "=="
	} else {
		k = strings.ReplaceAll(strings.ToLower(item.String()), "-", "")
	}
	if lc.log.isDebug {
		k += "_"
	}
	return fmt.Sprintf("fma:l:%v", k)
}

func (lc *locStoreCache) GetList(ctx context.Context, match *getLocMatch, page *skipLimPage) (res []*SyncLoc, e error) {
	var (
		matchKey = lc.cacheKey(match)
		pageKey  = lc.cacheKey(page)
	)
	if !page.SyncRead {
		//res will be empty array if read from cache, an acceptable cache value
		if res, e = lc.cacheGet(ctx, matchKey, pageKey); e == nil && res != nil {
			return //cache hit!
		} else if e != nil {
			e = nil //should already be logged, treat as warning & attempt pull from source
		} //if res is nil, it is a cache miss
	}
	if res, e = lc.inner.GetList(ctx, match, page); e == nil { //cache miss, pull data from PG
		go lc.cachePut(ctx, matchKey, pageKey, res) //write to cache on side thread
	}
	return
}

func (lc *locStoreCache) cacheGet(ctx context.Context, matchKey string, pageKey string) (res []*SyncLoc, e error) {
	defer panicRecover(lc.log, "cacheGet: %v - %v", matchKey, matchKey)
	var (
		cmd = lc.red._client.HGet(ctx, matchKey, pageKey)
		js  string
	)
	if js, e = cmd.Result(); e != nil {
		if e != redis.Nil {
			lc.log.IfWarnF(e, "cacheGet: hGET %v - %v", matchKey, pageKey)
		} //else, nil case :. found nothing, return as is
	} else if js == "[]" { //shortcut to save on deserialization cpu
		res = make([]*SyncLoc, 0)
	} else if len(js) > 2 {
		arr := make([]*SyncLoc, 0)
		if e = json.Unmarshal([]byte(js), &arr); e != nil {
			lc.log.IfWarnF(e, "cacheGet: unmarshal %v - %v | %s", matchKey, pageKey, js)
		} else {
			lc.log.Trace("cacheGet: HIT %v %v", matchKey, pageKey)
			res = arr
		}
	}
	return
}

func (lc *locStoreCache) cachePut(ctx context.Context, matchKey string, pageKey string, res []*SyncLoc) {
	defer panicRecover(lc.log, "cachePut: %v - %v", matchKey, pageKey)
	ttl := lc.ttl
	if res == nil {
		res = make([]*SyncLoc, 0)
	}
	if len(res) == 0 {
		ttl = ttl / 4 //shorter ttl for empty or nil
	}
	if buf, e := json.Marshal(res); e != nil {
		lc.log.IfWarnF(e, "cachePut: marshal %v", res)
	} else {
		var (
			jm = map[string]interface{}{
				pageKey: string(buf),
			}
			ok   bool
			ttls = int(ttl.Seconds())
		)
		if ok, e = lc.red.HMSet(ctx, matchKey, jm, ttls); e != nil && e != redis.Nil {
			lc.log.IfWarnF(e, "cachePut: HMSet %v | %v", matchKey, jm)
		} else {
			lc.log.Debug("cachePut: OK=%v %v %v", ok, matchKey, pageKey)
		}
	}
}

func (lc *locStoreCache) cachePop(ctx context.Context, matches ...*getLocMatch) {
	if len(matches) == 0 {
		return
	}
	defer panicRecover(lc.log, "cachePop: %v", matches)
	var (
		keys = make(map[string]bool) //ensure unique keys
		oks  = make([]string, 0)
	)
	for _, match := range matches {
		if match == nil {
			continue
		}
		matchKey := lc.cacheKey(match)
		keys[matchKey] = true
	}
	for matchKey, _ := range keys { //ensure we don't waste network resources on duplicated keys
		if n, e := lc.red.Delete(ctx, matchKey); e != nil && e != redis.Nil {
			lc.log.IfWarnF(e, "cachePop: %v", matchKey)
		} else if n > 0 {
			oks = append(oks, matchKey)
		}
	}
	lc.log.Debug("cachePop: OK %v | %v", len(oks), oks)
}

func (lc *locStoreCache) Save(ctx context.Context, loc *SyncLoc) (e error) {
	if e = lc.inner.Save(ctx, loc); e == nil { //save success, pop cache
		matches := lc.convLocMatches(loc)
		go lc.cachePop(ctx, matches...) //side thread cache pop
	}
	return
}

func (lc *locStoreCache) Remove(ctx context.Context, match *getLocMatch) (rems []*SyncLoc, e error) {
	pops := make([]*getLocMatch, 0) //expand all possibilities
	pops = append(pops, match)
	if rems, e = lc.inner.Remove(ctx, match); e == nil { //removed ok, pop all related caches
		for _, r := range rems {
			pops = append(pops, lc.convLocMatches(r)...)
		}
	}
	go lc.cachePop(ctx, pops...) //don't worry, we deduplicate in func. Side thread exec
	return
}
