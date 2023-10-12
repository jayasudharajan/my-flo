package main

import (
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

// RamCache singleton worker with in RAM storage, auto cleanup of expired tokens
type RamCache interface {
	Store(key string, value interface{}, expiration time.Time)
	Load(key string) (value interface{})
	Evict(key string)
	EvictMatch(match string)
	Clean()
	Open()
	Close()
}

type ramCache struct {
	name  string
	mem   sync.Map //string -> *cacheVal
	state int32    //0=closed, 1=open
	log   Log
	clean time.Duration
}

func NewRamCache(name string, log Log, cleaning time.Duration) RamCache {
	sec := ClampInt64(int64(cleaning.Seconds()), 5, 120)
	log.Notice("NewRamCache: %v cleaning=%v", name, cleaning)
	return &ramCache{name, sync.Map{}, 0, log, time.Duration(sec) * time.Second}
}

// Open start self-cleaning
func (t *ramCache) Open() {
	if atomic.CompareAndSwapInt32(&t.state, 0, 1) {
		t.log.Info("Open")
		go func() {
			time.Sleep(t.clean) //sleep before first clean
			t.cleanSchedule()
		}()
	}
}

func (t *ramCache) cleanSchedule() {
	for atomic.LoadInt32(&t.state) == 1 {
		t.Clean()
		time.Sleep(t.clean) //repeat on interval
	}
}

// Close stop self-cleaning
func (t *ramCache) Close() {
	if atomic.CompareAndSwapInt32(&t.state, 1, 0) {
		t.log.Info("Close")
	}
}

// EvictMatch remove all matched keys
func (t *ramCache) EvictMatch(match string) {
	t.log.Trace("EvictMatch: start %q", match)
	match = strings.ToLower(match)
	t.mem.Range(func(key, value interface{}) bool {
		if strings.Contains(strings.ToLower(key.(string)), match) {
			t.mem.Delete(key)
		} else if cv := value.(*ramVal); cv.Expired() { //also delete expired keys
			t.mem.Delete(key)
		}
		return true
	})
	t.log.Debug("EvictMatch: done %q", match)
}

// Clean remove all expired keys
func (t *ramCache) Clean() {
	t.log.Trace("Clean: start")
	var (
		exp   = 0
		start = time.Now()
	)
	t.mem.Range(func(key, value interface{}) bool {
		if cv := value.(*ramVal); cv.Expired() {
			t.mem.Delete(key)
			exp++
		}
		return true
	})
	t.log.Log(IfLogLevel(exp > 0, LL_DEBUG, LL_TRACE), "Clean: done. Exp keys=%v took=%v", exp, time.Since(start))
}

// Store only store what isn't expired
func (t *ramCache) Store(key string, value interface{}, expiration time.Time) {
	if expiration.After(time.Now()) {
		t.mem.Store(key, &ramVal{value, expiration.Unix()})
	}
}

// Load will discard expired values
func (t *ramCache) Load(key string) (value interface{}) {
	if val, ok := t.mem.Load(key); ok && val != nil {
		if cv := val.(*ramVal); cv.Expired() {
			t.mem.Delete(key)
		} else {
			return cv.obj
		}
	}
	return nil
}

func (t *ramCache) Evict(key string) {
	t.mem.Delete(key)
}

type ramVal struct {
	obj interface{}
	exp int64
}

func (cv *ramVal) Expired() bool {
	return time.Now().After(time.Unix(cv.exp, 0))
}
