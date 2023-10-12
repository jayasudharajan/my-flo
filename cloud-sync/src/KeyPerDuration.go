package main

import (
	"sync"
	"time"
)

// KeyPerDuration provides a way to check if a named action has occurred within the elapsed duration
// sort of like an inmemory setNX (redis cmd)
type KeyPerDuration interface {
	Check(key string, elapsed time.Duration) bool
}

// CreateKeyPerDuration evict all keys older than flush duration periodically
func CreateKeyPerDuration(flush time.Duration) KeyPerDuration {
	if flush < time.Second {
		flush = time.Second
	}
	checker := keyPerDuration{
		lastMap:  make(map[string]int64),
		mux:      sync.Mutex{},
		flushDur: flush,
	}
	go checker.scrub()
	return &checker
}

type keyPerDuration struct {
	flushDur time.Duration
	lastMap  map[string]int64
	mux      sync.Mutex
	disposed bool
}

func (o *keyPerDuration) Close() {
	if o == nil {
		return
	}
	o.mux.Lock()
	defer o.mux.Unlock()
	o.disposed = true
}

// Check if true, key has not been used since elapsed, time is reset to NOW for key
func (o *keyPerDuration) Check(key string, elapsed time.Duration) bool {
	if o == nil {
		return false
	}
	o.mux.Lock()
	defer o.mux.Unlock()

	now := time.Now().Unix()
	if last, ok := o.lastMap[key]; ok {
		if float64(now-last) >= elapsed.Seconds() {
			o.lastMap[key] = now
			return true
		} else {
			return false
		}
	} else {
		o.lastMap[key] = now
		return true
	}
}

func (o *keyPerDuration) scrub() {
	if o == nil {
		return
	}
	time.Sleep(o.flushDur + time.Second)
	if o == nil {
		return
	}
	defer panicRecover(_log, "KeyPerDuration.scrub")
	o.mux.Lock()
	defer o.mux.Unlock()

	var (
		now    = time.Now().Unix()
		durSec = int64(o.flushDur.Seconds())
	)
	for key, last := range o.lastMap {
		if now-last >= durSec {
			delete(o.lastMap, key)
		}
	}
	if !o.disposed {
		go o.scrub()
	}
}
