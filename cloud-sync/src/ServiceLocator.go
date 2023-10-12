package main

import (
	"errors"
	"reflect"
	"strings"
	"sync"
)

type Locator func(s ServiceLocator) interface{}

//ServiceLocator return named instance of services
//SEE: https://en.wikipedia.org/wiki/Service_locator_pattern
type ServiceLocator interface {
	RegisterName(name string, locator Locator) error
	LocateName(name string) interface{}
	CopyName(name string, svc interface{}) (found bool)
	SingletonName(name string) interface{}

	Clone() ServiceLocator //safe cloning w/o closers
	Close()                //close all closable singletons
}

type Closer interface {
	Close()
}

type serviceLocator struct {
	plan       map[string]Locator
	singletons map[string]interface{}
	closers    []Closer
	planMx     sync.RWMutex
	singMx     sync.RWMutex
}

func CreateServiceLocator() ServiceLocator {
	return &serviceLocator{
		plan:       make(map[string]Locator),
		singletons: make(map[string]interface{}),
		closers:    make([]Closer, 0),
		planMx:     sync.RWMutex{},
		singMx:     sync.RWMutex{},
	}
}

// Clone return safe cloning of locator w/o singleton closers
func (di *serviceLocator) Clone() ServiceLocator {
	if di == nil {
		return nil
	}
	di.planMx.RLock()
	defer di.planMx.RUnlock()

	cp := serviceLocator{
		plan:    make(map[string]Locator),
		closers: nil, //don't clone closers, keep it nil
		planMx:  sync.RWMutex{},
		singMx:  sync.RWMutex{},
	}
	for k, v := range di.plan { //transfer plans
		cp.plan[k] = v
	}

	di.singMx.RLock()
	defer di.singMx.RUnlock()

	cp.singletons = di.singletons //ref copy
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

			di.singMx.Lock() //lock sandwich, can't defer because recursive lock would suffer
			di.singletons[name] = res
			di.singMx.Unlock()

			switch t := res.(type) {
			case Closer:
				di.closers = append(di.closers, t)
			}
		}
	}
	return
}

// Close all closeable singletons
func (di *serviceLocator) Close() {
	if di != nil && di.closers != nil {
		di.singMx.RLock()
		defer di.singMx.RUnlock()

		for _, clr := range di.closers {
			go clr.Close() //close everything
		}
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
