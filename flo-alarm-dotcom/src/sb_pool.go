package main

import (
	"strings"
	"sync"
)

type SbPool interface {
	Get() *strings.Builder
	Put(s *strings.Builder)
}

func CreateSbPool() SbPool {
	return new(sbPool).Init()
}

type sbPool struct {
	pool *sync.Pool
	mx   sync.Mutex
}

func (p *sbPool) Init() *sbPool {
	if p != nil {
		if p.pool == nil { //lazy double check locking
			p.mx.Lock()
			defer p.mx.Unlock()
			if p.pool == nil {
				p.pool = &sync.Pool{
					New: func() interface{} {
						return new(strings.Builder)
					},
				}
			}
		}
	}
	return p
}

func (p *sbPool) Get() *strings.Builder {
	if p == nil || p.pool == nil {
		return &strings.Builder{} //why not
	}
	var sb *strings.Builder
	if o := p.pool.Get(); o != nil { //pull 1 from the pool
		sb = o.(*strings.Builder)
		sb.Reset()
	} else { //just make one
		sb = &strings.Builder{}
	}
	return sb
}

func (p *sbPool) Put(s *strings.Builder) {
	if s != nil && p != nil && p.pool != nil {
		p.pool.Put(s)
	}
}
