package main

import (
	"fmt"
	"reflect"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

type pubGWPingResp struct {
	App  string     `json:"app"`
	Date *PubGwTime `json:"date"`
}

// 2 levels deep locator
func TestInjectHttpUtil(t *testing.T) {
	var (
		loggerType = reflect.TypeOf(_log)
		sl         = CreateServiceLocator()
	)
	sl.RegisterType(loggerType, func(s ServiceLocator) interface{} {
		return DefaultLogger() //create new instance w/ default cfg
	})
	sl.RegisterName("httpUtil", func(s ServiceLocator) interface{} { //create new ref everytime
		var log = new(Logger)
		assert.True(t, sl.CopyType(loggerType, log)) //should create a new instance of the above logger
		assert.NotEmpty(t, log.prefix)
		assert.NotNil(t, log.stdOut)
		assert.NotNil(t, log.errOut)
		return CreateHttpUtil("", log, -1)
	})

	var (
		ht   httpUtil
		resp pubGWPingResp
		err  error
	)
	assert.True(t, sl.CopyName("httpUtil", &ht)) //create a new instance of this service
	assert.NotNil(t, ht.log)                     //NOTE: create method clone logger so ref will not match
	assert.NotNil(t, ht.hc)
	loggerCheck(t, false, _log, ht.log)
	assert.Equal(t, "httpU", ht.log.GetName())

	err = ht.Do("GET", "https://api-gw.meetflo.com/api/v2/ping", nil, nil, &resp) //ensure logic works!
	assert.Nil(t, err)
	assert.Equal(t, "flo-public-gateway", resp.App)
	assert.NotNil(t, resp.Date)
	assert.Greater(t, resp.Date.UTC().Year(), 2000)

	ll := new(Logger) //locate new instance logger
	assert.True(t, sl.CopyType(loggerType, ll))
	assert.Equal(t, "", ll.GetName())
	loggerCheck(t, false, ht.log, ll) //ensure instance doesn't match
}

func loggerCheck(t *testing.T, same bool, a, b *Logger) {
	assert.Equal(t, a.prefix, b.prefix)
	assert.Same(t, a.errOut, b.errOut) //logic requires this is the same, even as a copy
	assert.Same(t, a.stdOut, b.stdOut) //logic requires this is the same, even as a copy
	assert.Same(t, a.sbPool, b.sbPool)
	assert.Equal(t, a.childLevel, b.childLevel)
	assert.Equal(t, a.isDebug, b.isDebug)
	assert.Equal(t, a.Color, b.Color)
	assert.Equal(t, a.MinLevel, b.MinLevel)

	if same {
		assert.Same(t, a, b)
	} else { //NOTE: assert.NotSame(...) func in frame work has a bug!!
		assert.NotEqual(t, fmt.Sprintf("%p", a), fmt.Sprintf("%p", b))
		assert.NotEqual(t, fmt.Sprintf("%p", &a.scopeLock), fmt.Sprintf("%p", &b.scopeLock))
		assert.NotEqual(t, fmt.Sprintf("%p", &a.scopes), fmt.Sprintf("%p", b.scopes))
	}
}

type diTestStruct struct {
	Name   string
	Logger *Logger
}

// test built in singleton
func TestInjectBuiltinSingleton(t *testing.T) {
	sl := CreateServiceLocator()
	sl.RegisterName("*Logger", func(s ServiceLocator) interface{} {
		return DefaultLogger() //default instance of the logger
	})
	sl.RegisterName("*diTestStruct", func(s ServiceLocator) interface{} {
		log := sl.SingletonName("*Logger").(*Logger) //grab a singleton unique to the above sl
		assert.NotNil(t, log)
		assert.Equal(t, _log.prefix, log.prefix)
		return &diTestStruct{Logger: log}
	})

	ll := sl.SingletonName("*Logger").(*Logger)
	assert.NotNil(t, ll)
	loggerCheck(t, false, _log, ll) //private singleton, should not the the same as static _log ref

	ts2 := diTestStruct{}
	assert.True(t, sl.CopyName("*diTestStruct", &ts2))
	assert.NotNil(t, ts2.Logger)
	loggerCheck(t, true, ll, ts2.Logger) //same

	ts2a := new(diTestStruct)
	assert.True(t, sl.CopyName("*diTestStruct", ts2a))
	assert.NotNil(t, ts2a.Logger)
	loggerCheck(t, true, ll, ts2a.Logger)                                //same
	assert.NotEqual(t, fmt.Sprintf("%p", &ts2), fmt.Sprintf("%p", ts2a)) //ensure pointers are different

	diff := new(Logger)
	assert.True(t, sl.CopyName("*Logger", diff)) //grab a new copy
	loggerCheck(t, false, ll, diff)              //since we're asking for a copy, logger should not match
}

// test copying of simple singleton to a new ref
func TestInjectSingletonCopy(t *testing.T) {
	sl := CreateServiceLocator()
	sl.RegisterName("LoggerSingleton", func(s ServiceLocator) interface{} {
		return _log //return same singleton
	})
	sl.RegisterName("*diTestStruct", func(s ServiceLocator) interface{} {
		log := sl.LocateName("LoggerSingleton").(*Logger) //since we're locating a singleton, ref should be _log
		assert.NotNil(t, log)
		assert.Equal(t, _log.prefix, log.prefix)
		return &diTestStruct{Logger: log}
	})

	ts2 := diTestStruct{}
	assert.True(t, sl.CopyName("*diTestStruct", &ts2))
	assert.NotNil(t, ts2.Logger)
	loggerCheck(t, true, _log, ts2.Logger) //same

	ts2a := new(diTestStruct)
	assert.True(t, sl.CopyName("*diTestStruct", ts2a))
	assert.NotNil(t, ts2a.Logger)
	loggerCheck(t, true, _log, ts2a.Logger) //same

	ll := new(Logger)
	assert.True(t, sl.CopyName("LoggerSingleton", ll))
	assert.NotNil(t, ll)
	assert.Equal(t, "", ll.GetName())
	loggerCheck(t, false, _log, ll) //since we're copying a singleton, logger should not match
}

type TestCloser struct {
	Logger *Logger
	State  int32
}

func (t *TestCloser) Close() {
	if atomic.CompareAndSwapInt32(&t.State, 0, 1) {
		t.Logger.Info("Closed")
	} else {
		t.Logger.Debug("Already Closed")
	}
}

func TestClone(t *testing.T) {
	var (
		s1    = CreateServiceLocator()
		c1    = new(TestCloser)
		cType = reflect.TypeOf(c1)
		e     error
	)
	e = s1.RegisterType(cType, func(s ServiceLocator) interface{} {
		tc := TestCloser{
			Logger: new(Logger),
		}
		s.CopyName("*Logger", tc.Logger)
		return &tc
	})
	assert.Nil(t, e)
	e = s1.RegisterName("*Logger", func(s ServiceLocator) interface{} {
		l := DefaultLogger()
		l.prefix = "L1"
		return l
	})
	assert.Nil(t, e)

	c1 = s1.SingletonType(cType).(*TestCloser)
	assert.NotNil(t, c1)
	assert.NotNil(t, c1.Logger)
	assert.Equal(t, "L1", c1.Logger.prefix)

	s2 := s1.Clone()
	assert.NotNil(t, s2)
	assert.NotEqual(t, fmt.Sprintf("%p", s1), fmt.Sprintf("%p", s2))

	e = s2.RegisterName("*Logger", func(s ServiceLocator) interface{} {
		l := DefaultLogger()
		l.prefix = "L2"
		return l
	})
	assert.Nil(t, e)

	c2 := s2.SingletonType(cType).(*TestCloser)
	assert.NotNil(t, c2)
	assert.Same(t, c1, c2)
	loggerCheck(t, true, c1.Logger, c2.Logger)

	var (
		l1 = new(Logger)
		l2 = new(Logger)
	)
	assert.True(t, s1.CopyName("*Logger", l1))
	assert.True(t, s2.CopyName("*Logger", l2))
	assert.Equal(t, "L1", l1.prefix)
	assert.Equal(t, "L2", l2.prefix)

	s2.Close()
	time.Sleep(time.Second / 2)
	assert.Equal(t, int32(0), c2.State)
	assert.Equal(t, int32(0), c1.State)

	s1.Close()
	time.Sleep(time.Second / 2)
	assert.Equal(t, int32(1), c1.State)
	assert.Equal(t, int32(1), c2.State)
}
