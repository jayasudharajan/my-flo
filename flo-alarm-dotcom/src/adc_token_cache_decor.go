package main

import (
	"sync"
	"time"
)

var (
	_atkCacheMap = make(map[string]*OAuthResponse) //simple in-memory singleton cache of valid token
	_atkLok      = sync.RWMutex{}
)

type atkCache struct {
	base AdcTokenManager
	log  Log
}

func CreateAdcTokenManagerCache(base AdcTokenManager, log Log) AdcTokenManager {
	return &atkCache{base, log}
}

func (a *atkCache) Env() AdcEnv {
	return a.base.Env()
}

func (a *atkCache) PublicRawPem(floO2Cli string) ([]byte, error) {
	return a.base.PublicRawPem(floO2Cli)
}

func (a *atkCache) PublicJWK(floO2Cli string) (interface{}, error) {
	return a.base.PublicJWK(floO2Cli)
}

func (a *atkCache) CustomToken(floO2Cli string) (*AdcCustomTk, error) {
	return a.base.CustomToken(floO2Cli)
}

func (a *atkCache) tokenOK(tk *OAuthResponse) bool {
	return tk != nil && tk.AccessToken != "" && tk.ExpDt().After(time.Now().Add(time.Minute))
}

func (a *atkCache) PushToken(floO2Cli string, sync bool) (*OAuthResponse, error) {
	a.log.PushScope("PushTk")
	defer a.log.PopScope()
	if floO2Cli == "" {
		return nil, a.log.Warn("floO2Cli is blank")
	}

	if !sync { //cache get
		if tk := a.cacheGet(floO2Cli); tk != nil {
			return tk, nil
		}
	}
	res, e := a.base.PushToken(floO2Cli, sync) //compute from scratch
	if e == nil && a.tokenOK(res) {            //cache put
		a.cachePut(floO2Cli, res)
	}
	return res, e
}

func (a *atkCache) cacheGet(key string) *OAuthResponse {
	_atkLok.RLock()
	defer _atkLok.RUnlock()
	if tk, ok := _atkCacheMap[key]; ok && tk != nil && tk.ExpDt().After(time.Now().Add(time.Minute)) {
		cp := *tk //copy
		a.log.Trace("cacheGet: %v HIT", key)
		return &cp //return copy ref
	} else {
		a.log.Trace("cacheGet: %v MISSED", key)
	}
	return nil
}

func (a *atkCache) cachePut(key string, tk *OAuthResponse) {
	cp := *tk //make copy
	_atkLok.Lock()
	defer _atkLok.Unlock()

	_atkCacheMap[key] = &cp //save copy to cache
	a.log.Trace("cachePut: %v OK!", key)
}

func (a *atkCache) CacheFlush() {
	_atkLok.Lock()
	defer _atkLok.Unlock()

	_atkCacheMap = make(map[string]*OAuthResponse) //assign new ref to flush
}
