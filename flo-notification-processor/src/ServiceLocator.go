package main

import (
	"errors"
	"reflect"
	"strings"
	"sync"
)

type Locator func(s ServiceLocator) interface{}

// ServiceLocator SEE: https://en.wikipedia.org/wiki/Service_locator_pattern
type ServiceLocator interface {
	RegisterName(name string, locator Locator) error
	RegisterType(t reflect.Type, locator Locator) error

	LocateName(name string) interface{}
	LocateType(t reflect.Type) interface{}

	SingletonName(name string) interface{}
	SingletonType(t reflect.Type) interface{}

	Clone() ServiceLocator //safe cloning w/o closers
	Close()                //close all closable singletons
}

type Closer interface {
	Close()
}

type serviceLocator struct {
	plan       map[string]Locator
	singletons map[string]interface{}
	loadOrder  []string //singleton load ordering for cleanup
	planMx     sync.RWMutex
	singMx     sync.RWMutex
}

func NewServiceLocator() ServiceLocator {
	return &serviceLocator{
		plan:       make(map[string]Locator),
		singletons: make(map[string]interface{}),
		loadOrder:  make([]string, 0),
		planMx:     sync.RWMutex{},
		singMx:     sync.RWMutex{},
	}
}

// Clone safe cloning of locator w/o singleton closers
func (di *serviceLocator) Clone() ServiceLocator {
	if di == nil {
		return nil
	}
	di.planMx.RLock()
	defer di.planMx.RUnlock()

	cp := serviceLocator{
		plan:   make(map[string]Locator),
		planMx: sync.RWMutex{},
		singMx: sync.RWMutex{},
	}
	for k, v := range di.plan { //transfer plans
		cp.plan[k] = v
	}

	di.singMx.RLock()
	defer di.singMx.RUnlock()

	cp.singletons = di.singletons //ref copy
	cp.loadOrder = di.loadOrder   //ref copy
	return &cp
}

func (di *serviceLocator) RegisterName(name string, locator Locator) error {
	if di == nil {
		return errors.New("reference not bound")
	} else if locator == nil {
		return errors.New("input locator is nil")
	} else {
		di.planMx.Lock()
		defer di.planMx.Unlock()

		di.plan[strings.ToLower(name)] = locator
		return nil
	}
}

func (di *serviceLocator) RegisterType(t reflect.Type, locator Locator) error {
	if di == nil {
		return errors.New("reference not bound")
	}
	return di.RegisterName(t.String(), locator)
}

func (di *serviceLocator) LocateName(name string) interface{} {
	if di != nil && name != "" {
		di.planMx.RLock()
		defer di.planMx.RUnlock()

		if finder, found := di.plan[strings.ToLower(name)]; found {
			return finder(di)
		}
	}
	return nil
}

func (di *serviceLocator) LocateType(t reflect.Type) interface{} {
	if di == nil {
		return errors.New("reference not bound")
	}
	return di.LocateName(t.String())
}

func (di *serviceLocator) SingletonName(name string) (res interface{}) {
	if di != nil && name != "" {
		name = strings.ToLower(name)
		di.singMx.RLock()
		if ref, ok := di.singletons[name]; ok {
			di.singMx.RUnlock()
			res = ref
		} else {
			di.singMx.RUnlock()
			res = di.LocateName(name) //allow lock escape on purpose
			if res != nil {
				di.singMx.Lock() //lock sandwich, can't defer because recursive lock would suffer
				di.singletons[name] = res
				di.loadOrder = append(di.loadOrder, name)
				di.singMx.Unlock()
			}
		}
	}
	return
}

func (di *serviceLocator) SingletonType(t reflect.Type) interface{} {
	if di == nil {
		return errors.New("reference not bound")
	}
	return di.SingletonName(t.String())
}

// Close close all closeable singletons
func (di *serviceLocator) Close() {
	if di != nil && di.singletons != nil && len(di.singletons) != 0 {
		di.singMx.RLock()
		defer di.singMx.RUnlock()

		wg := sync.WaitGroup{}
		for i := len(di.loadOrder) - 1; i >= 0; i-- { //cleanup in reverse singleton load order
			name := di.loadOrder[i]
			svr := di.singletons[name]
			if crf, ok := svr.(Closer); ok && crf != nil {
				go func() {
					wg.Add(1)
					defer wg.Done()
					crf.Close()
				}()
			}
			delete(di.singletons, name)
		}
		wg.Wait()
		di.loadOrder = di.loadOrder[:0]
	}
}
