package main

import (
	"github.com/gin-gonic/gin"
)

//svcLocLogCtx decorate locator logic with a cloned logger with proper context name
// base ServiceLocator has no knowledge of type registration, it's oblivious to service registrations
// this decorator has domain knowledge
type svcLocLogCtx struct {
	base ServiceLocator
}

func ServiceLocatorWithLogCtx(sl ServiceLocator) ServiceLocator {
	return &svcLocLogCtx{sl}
}

func (s svcLocLogCtx) RegisterName(name string, locator Locator) error {
	switch name {
	case "Logger":
		return s.base.RegisterName(name, locator)
	}
	log, ok := s.LocateName("Logger").(Logger)
	if !ok || log == nil {
		return s.base.RegisterName(name, locator)
	}
	return s.base.RegisterName(name, func(sl ServiceLocator) interface{} {
		sl = sl.Clone()
		sl.RegisterName("Logger", func(svc ServiceLocator) interface{} {
			return log.CloneAsChild(name)
		})
		return locator(sl)
	})
}

func (s svcLocLogCtx) AliasNames(source string, alias ...string) error {
	return s.base.AliasNames(source, alias...)
}

func (s svcLocLogCtx) LocateName(name string) interface{} {
	return s.base.LocateName(name)
}

func (s svcLocLogCtx) SingletonName(name string) interface{} {
	return s.base.SingletonName(name)
}

func (s svcLocLogCtx) Clone() ServiceLocator {
	if s.base == nil {
		return nil
	}
	return s.base.Clone()
}

func (s svcLocLogCtx) Context(c *gin.Context) ServiceLocator {
	return s.base.Context(c)
}

func (s svcLocLogCtx) Close() {
	s.base.Close()
}
