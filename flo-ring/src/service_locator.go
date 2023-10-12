package main

import (
	"errors"
	"reflect"
	"strings"
	"sync"
)

type Locator func(s ServiceLocator) interface{}

type ServiceLocator interface {
	RegisterName(name string, locator Locator) error
	RegisterType(t reflect.Type, locator Locator) error

	LocateName(name string) interface{}
	LocateType(t reflect.Type) interface{}

	CopyName(name string, svc interface{}) (found bool)
	CopyType(t reflect.Type, svc interface{}) (found bool)

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

func CreateServiceLocator() ServiceLocator {
	return &serviceLocator{
		plan:       make(map[string]Locator),
		singletons: make(map[string]interface{}),
		loadOrder:  make([]string, 0),
		planMx:     sync.RWMutex{},
		singMx:     sync.RWMutex{},
	}
}

//safe cloning of locator w/o singleton closers
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

//close all closeable singletons
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

func (di *serviceLocator) CopyName(name string, svc interface{}) (found bool) {
	if di != nil && name != "" && svc != nil {
		if ref := di.LocateName(name); ref != nil {
			var (
				svcRv = reflect.ValueOf(svc)
				refRv = reflect.ValueOf(ref)
			)
			found = true
			if refRv.Type() != svcRv.Type() {
				return false
			} else if svcRv.CanSet() {
				svcRv.Set(refRv)
			} else if sEl := svcRv.Elem(); sEl.CanSet() {
				sEl.Set(reflect.Indirect(refRv))
			} else {
				svc = ref
			}
		}
	}
	return
}

func (di *serviceLocator) CopyType(t reflect.Type, svc interface{}) bool {
	if di == nil {
		return false
	}
	return di.CopyName(t.String(), svc)
}
