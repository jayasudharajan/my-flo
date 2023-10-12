package main

import (
	"github.com/gin-gonic/gin"
	"os"
	"time"
)

// Registry setup services and provide a way to locate them by name
type Registry interface {
	RegisterServices() Registry
	RegisterWorkers() []OpenCloser
	RegisterRoute(w WebServer, r gin.IRoutes)
	Locator() ServiceLocator
}

type registry struct {
	log  *Logger
	exit func()
	sl   ServiceLocator
}

func NewRegistry(log *Logger) Registry {
	if log == nil {
		log = _log
	}
	var (
		app       = NewAppContext(log, _commitSha, _commitTime, _commitBranch).SetHost() //static singleton
		delayExit = func() {
			time.Sleep(time.Second)
			app.Exit(os.Interrupt)
		}
		reg = registry{log.CloneAsChild("Reg"), delayExit, NewServiceLocator()}
	)
	reg.sl.RegisterName("*Logger", func(s ServiceLocator) interface{} { return log.Clone() })
	reg.sl.RegisterName("*appContext", func(s ServiceLocator) interface{} { return app })
	return &reg
}

func (r *registry) Locator() ServiceLocator {
	return r.sl
}

func (r *registry) registerUtils() {
	r.log.PushScope("utils").Trace("init")
	defer r.log.PopScope()
	defer r.log.Trace("done")

	r.sl.RegisterName("Validator", func(s ServiceLocator) interface{} {
		v, _ := NewValidator(_loggerSbPool)
		return v
	})
	r.sl.RegisterName("HttpUtil", func(s ServiceLocator) interface{} {
		return NewHttpUtil("", time.Second*9)
	})
	r.sl.RegisterName("RamCache", func(s ServiceLocator) interface{} {
		return NewRamCache(
			"RamCache",
			s.LocateName("*Logger").(*Logger),
		)
	})
}

func (r *registry) registerConnectors() {
	r.log.PushScope("connectors").Trace("init")
	defer r.log.PopScope()
	defer r.log.Trace("done")

	r.sl.RegisterName("*RedisConnection", func(s ServiceLocator) interface{} {
		if cn := getEnvOrDefault("FLO_REDIS_CN", ""); cn == "" {
			defer r.exit()
			r.log.Fatal("FLO_REDIS_CN is missing")
			return nil
		} else if red, e := NewRedisConnection(cn); e != nil {
			defer r.exit()
			r.log.IfFatalF(e, "NewRedisConnection")
			return nil
		} else {
			return red
		}
	})

	r.sl.RegisterName("*PgSqlDb", func(s ServiceLocator) interface{} {
		if cn := getEnvOrDefault("FLO_PGDB_CN", ""); cn == "" {
			defer r.exit()
			r.log.Fatal("FLO_PGDB_CN is missing")
			return nil
		} else if pg, e := NewPgSqlDb(cn, s.LocateName("*Logger").(*Logger)); e != nil {
			defer r.exit()
			r.log.IfFatalF(e, "OpenPgSqlDb")
			return nil
		} else {
			return pg
		}
	})

	r.sl.RegisterName("*KafkaConnection", func(s ServiceLocator) interface{} {
		if cn := getEnvOrDefault("FLO_KAFKA_CN", ""); cn == "" {
			defer r.exit()
			r.log.Fatal("FLO_KAFKA_CN is missing")
			return nil
		} else if kaf, e := OpenKafka(cn, nil); e != nil {
			defer r.exit()
			r.log.IfFatalF(e, "OpenKafka")
			return nil
		} else {
			return kaf
		}
	})
}

// RegisterServices provide instruction to construct services here
func (r *registry) RegisterServices() Registry {
	r.log.PushScope("services").Trace("init")
	defer r.log.PopScope()
	defer r.log.Trace("done")

	r.registerUtils()      //do these first
	r.registerConnectors() //do these first

	//register your services here
	r.sl.RegisterName("NotifySub", func(s ServiceLocator) interface{} {
		return NewNotifySub(
			s.LocateName("*Logger").(*Logger),
			s.SingletonName("*KafkaConnection").(*KafkaConnection),
		)
	})
	return r
}

//code adaptor to convert any method to OpenCloser interface to be treated as background worker process
type openCloseShim struct {
	openMe  func()
	closeMe func()
}

func (c *openCloseShim) Open() {
	if c != nil && c.openMe != nil {
		c.openMe()
	}
}

func (c *openCloseShim) Close() {
	if c != nil && c.closeMe != nil {
		c.closeMe()
	}
}

// RegisterWorkers provide instruction to init background processes here
func (r *registry) RegisterWorkers() []OpenCloser {
	r.log.PushScope("workers").Trace("init")
	defer r.log.PopScope()
	defer r.log.Trace("done")

	workers := []OpenCloser{
		r.sl.SingletonName("NotifySub").(NotifySub),
		&openCloseShim{closeMe: r.sl.Close}, //close self to cleanup all singletons, keep this last
	}
	return workers
}

// RegisterRoute provide instruction for http web routes here
func (r *registry) RegisterRoute(w WebServer, router gin.IRoutes) {
	r.log.PushScope("routes").Trace("init")
	defer r.log.PopScope()
	defer r.log.Trace("done")
	r.sl.RegisterName("WebServer", func(s ServiceLocator) interface{} { return w })
	r.sl.RegisterName("IRoutes", func(s ServiceLocator) interface{} { return router })

	newHandler := func() WebHandler { return NewWebHandler(r.sl, w) }
	r.sl.RegisterName("WebHandler", func(s ServiceLocator) interface{} { return newHandler() })

	router.GET("/", func(c *gin.Context) {
		newHandler().Ping(c) //new handler per request with this own cloned sl
	})
	router.GET("/ping", func(c *gin.Context) {
		newHandler().Ping(c)
	})
	router.POST("/ping", func(c *gin.Context) { //deep ping
		newHandler().Ping(c)
	})
	// add other handlers here...
}
