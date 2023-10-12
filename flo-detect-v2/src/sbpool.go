package main

import (
	"strings"
	"sync"
)

type sbPool struct {
	pool *sync.Pool
	lock sync.Mutex
}

var _sbPoolInstance *sbPool
var _onceSbPool sync.Once

func SbPoolInstance() *sbPool {
	_onceSbPool.Do(func() {
		_sbPoolInstance = &sbPool{
			lock: sync.Mutex{},
			pool: &sync.Pool{
				New: func() interface{} {
					return new(strings.Builder)
				},
			},
		}
	})
	return _sbPoolInstance
}

func (sbp *sbPool) StashStringBuilder(sb *strings.Builder) {
	if sb != nil {
		sbp.pool.Put(sb)
	}
}
func (sbp *sbPool) GetStringBuilder() *strings.Builder {
	if o := sbp.pool.Get(); o != nil {
		sb := o.(*strings.Builder)
		sb.Reset()
		return sb
	}
	return &strings.Builder{} //just make 1 as this func can't fail
}
