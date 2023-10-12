package main

import (
	"context"
	"strings"
	"time"
)

// syncStoreRam is SynStore decorator that use singleton RamCache to cache AccountMap data locally
// logic pop cache by listening to user linked, unlinked & deleted event in kafka
type syncStoreRam struct {
	inner SyncStore
	cache RamCache
	ttl   time.Duration
}

func CreateSyncStoreRam(inner SyncStore, cache RamCache, ttl time.Duration) SyncStore {
	if minDur := time.Duration(5) * time.Second; ttl < minDur {
		ttl = minDur
	}
	if maxDur := time.Duration(24) * time.Hour; ttl > maxDur {
		ttl = maxDur
	}
	return &syncStoreRam{inner, cache, ttl}
}

func (sr *syncStoreRam) Check(ctx context.Context, moenId, floId string) (bool, error) {
	if mk := sr.getMoenKey(moenId); mk != "" {
		if w := sr.getCache(mk); w != nil {
			return w.value != nil, nil //cache hit
		}
	}
	if fk := sr.getFloKey(floId); fk != "" {
		if w := sr.getCache(fk); w != nil {
			return w.value != nil, nil //cache hit
		}
	}
	return sr.inner.Check(ctx, moenId, floId) //cache miss
}

func (sr *syncStoreRam) GetByAccount(ctx context.Context, moeAccId, floAccId string, orPredicate bool) (res []*AccountMap, e error) {
	if res, e = sr.inner.GetByAccount(ctx, moeAccId, floAccId, orPredicate); e == nil {
		for _, ac := range res { //still populate local cache to help other ops
			sr.putCache(ac.MoenId, ac.FloId, ac, sr.ttl)
		}
	}
	return
}

func (sr *syncStoreRam) GetMap(ctx context.Context, moenId, floId, issuer string) (ac *AccountMap, e error) {
	if mk := sr.getMoenKey(moenId); mk != "" {
		if w := sr.getCache(mk); w != nil {
			return w.value.Clone(), nil //cache hit
		}
	}
	if fk := sr.getFloKey(floId); fk != "" {
		if w := sr.getCache(fk); w != nil {
			return w.value.Clone(), nil //cache hit
		}
	}
	if ac, e = sr.inner.GetMap(ctx, moenId, floId, issuer); e == nil { //cache miss
		ttl := sr.ttl
		if ac == nil { //shorter ttl for nils
			ttl = sr.ttl / 10
		}
		sr.putCache(moenId, floId, ac, ttl)
	}
	return
}

func (sr *syncStoreRam) getMoenKey(moeId string) string {
	if moeId == "" {
		return ""
	}
	return "m:" + strings.ToLower(strings.ReplaceAll(moeId, "-", ""))
}

func (sr *syncStoreRam) getFloKey(floId string) string {
	if floId == "" {
		return ""
	}
	return "f:" + strings.ToLower(strings.ReplaceAll(floId, "-", ""))
}

func (sr *syncStoreRam) getKeys(am *AccountMap) (moe, flo string) {
	moe = sr.getMoenKey(am.MoenId)
	flo = sr.getFloKey(am.FloId)
	return
}

type accCacheWrap struct {
	value *AccountMap
}

func (sr *syncStoreRam) getCache(key string) *accCacheWrap {
	if v := sr.cache.Load(key); v != nil {
		if wrap, ok := v.(*accCacheWrap); ok && wrap != nil {
			return wrap
		}
	}
	return nil
}

func (sr *syncStoreRam) putCache(moeId, floId string, am *AccountMap, ttl time.Duration) {
	var (
		wrap = &accCacheWrap{}
		exp  = time.Now().UTC().Add(ttl)
	)
	if am != nil {
		wrap.value = am.Clone() //assign copy pointer
		if moeId == "" {
			moeId = am.MoenId
		}
		if floId == "" {
			floId = am.FloId
		}
	}
	if mk := sr.getMoenKey(moeId); mk != "" {
		sr.cache.Store(mk, wrap, exp)
	}
	if fk := sr.getFloKey(floId); fk != "" {
		sr.cache.Store(fk, wrap, exp)
	}
}

func (sr *syncStoreRam) Save(ctx context.Context, am *AccountMap) (e error) {
	if e = sr.inner.Save(ctx, am); e == nil && am != nil {
		sr.putCache(am.MoenId, am.FloId, am, sr.ttl)
	}
	return
}

func (sr *syncStoreRam) Remove(ctx context.Context, moenId, floId string) (e error) {
	if e = sr.inner.Remove(ctx, moenId, floId); e == nil {
		sr.cachePop(moenId, floId)
	}
	return
}

func (sr *syncStoreRam) cachePop(moenId, floId string) {
	if mk := sr.getMoenKey(moenId); mk != "" {
		sr.cache.Evict(mk)
	}
	if fk := sr.getFloKey(floId); fk != "" {
		sr.cache.Evict(fk)
	}
}

func (sr *syncStoreRam) Invalidate(moenId, floId string) {
	var wrap *accCacheWrap
	if mk := sr.getMoenKey(moenId); mk != "" {
		wrap = sr.getCache(mk)
	}
	if wrap == nil {
		if fk := sr.getFloKey(floId); fk != "" {
			wrap = sr.getCache(fk)
		}
	}
	if wrap != nil && wrap.value != nil {
		sr.cachePop(wrap.value.MoenId, wrap.value.FloId)
	}
	sr.cachePop(moenId, floId)
}
