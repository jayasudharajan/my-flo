package main

import "sync"

// ConcurrentMap is the concurrent map
type ConcurrentMap struct {
	M map[string]interface{}
	L sync.RWMutex
}

// Get retrieves value per key from the locked map
func (cm *ConcurrentMap) Get(key string) (interface{}, bool) {
	cm.L.RLock()
	value, ok := cm.M[key]
	cm.L.RUnlock()
	return value, ok
}

// Set sets value per key from the locked map
func (cm *ConcurrentMap) Set(key string, value interface{}) {
	cm.L.Lock()
	cm.M[key] = value
	cm.L.Unlock()
}

// Delete deletes key/value pair from the locked map
func (cm *ConcurrentMap) Delete(key string) bool {
	cm.L.Lock()
	_, ok := cm.M[key]; if ok {
		delete(cm.M, key)
	}
	cm.L.Unlock()
	return ok
}

