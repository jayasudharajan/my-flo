package main

import (
	"context"
	"net/http"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/gin-gonic/gin"
)

// service that keeps track of other services
type registry struct {
	log        *Logger
	sl         ServiceLocator
	signalExit func()
}

// Utils register utilities
func (r *registry) Utils() *registry {
	r.log.PushScope("Utils").Trace("Begin")
	defer r.log.PopScope()

	r.sl.RegisterName("*Logger", func(s ServiceLocator) interface{} {
		return DefaultLogger()
	})

	var validateWarn int32 = 0
	r.sl.RegisterName("*Validator", func(s ServiceLocator) interface{} {
		v, e := CreateValidator()
		if e != nil && atomic.CompareAndSwapInt32(&validateWarn, 0, 1) {
			log := s.LocateName("*Logger").(*Logger)
			log.IfWarnF(e, "register *Validator")
		}
		return v
	})
	r.sl.RegisterName("*http.Client", func(s ServiceLocator) interface{} { //meant to be used as singleton
		sec, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_HTTP_TIMEOUT_S, ""))
		if sec < 0 {
			sec = 9
		}
		return &http.Client{Timeout: time.Duration(int64(sec)) * time.Second}
	})
	r.sl.RegisterName("*httpUtil", func(s ServiceLocator) interface{} {
		return CreateHttpUtilFromClient(
			"",
			-1,
			s.SingletonName("*http.Client").(*http.Client)) //reuse no matter what
	})
	r.sl.RegisterName("*httpUtilRetry", func(s ServiceLocator) interface{} {
		return CreateHttpUtilRetry(
			s.LocateName("*httpUtil").(HttpUtil),
			nil,
			s.LocateName("*Logger").(*Logger))
	})
	r.sl.RegisterName("HttpUtil", func(s ServiceLocator) interface{} {
		return s.LocateName("*httpUtil")
	})
	admCred := DefaultAdminCredential()
	r.sl.RegisterName("*adminCredential", func(s ServiceLocator) interface{} {
		return admCred //force singleton
	})

	r.log.Trace("Done")
	return r
}

type closerShim struct {
	shut func()
	log  *Logger
}

func (cs *closerShim) Open() {
	//do nothing to on purpose
}
func (cs *closerShim) Close() {
	if cs.shut != nil {
		cs.shut()
		cs.log.Debug("Closed %v", GetFunctionName(cs.shut))
	}
}

// Stores register databases
func (r *registry) Stores() []ICloser {
	r.log.PushScope("Stores").Trace("Begin")
	defer r.log.PopScope()

	closers := []func(){ //will init & close in this order
		r.registerPgSQL(),
		r.registerRedis(),
		r.registerKafka(),
	}

	res := make([]ICloser, 0, len(closers))
	for _, c := range closers {
		if c == nil {
			continue
		}
		res = append(res, &closerShim{c, r.log})
	}
	time.Sleep(time.Millisecond * 100)
	r.log.Trace("Done")
	return res
}

func (r *registry) registerRedis() func() {
	const envRedis = "FLO_REDIS_CN"
	if redisCN := getEnvOrDefault(envRedis, ""); redisCN == "" {
		r.log.Fatal("%v is MISSING", envRedis)
		r.signalExit()
	} else if redis, e := CreateRedisConnection(redisCN); e != nil {
		r.log.IfFatalF(e, "registerRedis")
		r.signalExit()
	} else {
		r.sl.RegisterName("*RedisConnection", func(s ServiceLocator) interface{} { return redis }) //forced singleton
		return redis.Close
	}
	return nil
}

func (r *registry) registerPgSQL() func() {
	const envPG = "FLO_PGDB_CN"
	if pgCN := getEnvOrDefault(envPG, ""); pgCN == "" {
		r.log.Fatal("%v is MISSING", envPG)
		r.signalExit()
	} else if pg, e := OpenPgSqlDb(pgCN); e != nil {
		r.log.IfFatalF(e, "registerPgSQL")
		r.signalExit()
	} else {
		r.sl.RegisterName("*PgSqlDb", func(s ServiceLocator) interface{} { return pg }) //forced singleton
		return pg.Close
	}
	return nil
}

func (r *registry) registerKafka() func() {
	const envKaf = "FLO_KAFKA_CN"
	if cn := getEnvOrDefault(envKaf, ""); cn == "" {
		r.log.Fatal("%v is MISSING", cn)
		r.signalExit()
	} else if kaf, e := OpenKafka(cn, nil); e != nil {
		r.log.IfFatalF(e, "registerKafka")
		r.signalExit()
	} else {
		r.sl.RegisterName("*KafkaConnection", func(s ServiceLocator) interface{} { return kaf })
		return kaf.Close
	}
	return nil
}

// Services register main logic
func (r *registry) Services() *registry {
	r.log.PushScope("Services").Trace("Begin")
	defer r.log.PopScope().Trace("Done")

	r.sl.RegisterName("MoenAuth", func(s ServiceLocator) interface{} {
		return CreateMoenAuth(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("HttpUtil").(HttpUtil),
			s.LocateName("*RedisConnection").(*RedisConnection),
			s.LocateName("*Validator").(*Validator),
		)
	})

	r.sl.RegisterName("*syncStore", func(s ServiceLocator) interface{} {
		return CreateSyncStore(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("*PgSqlDb").(*PgSqlDb),
			s.LocateName("*RedisConnection").(*RedisConnection),
			s.LocateName("*Validator").(*Validator))
	})
	var (
		syncCache       = CreateRamCache("usrAcc", r.log)                                         //singleton
		syncCacheTtl, _ = time.ParseDuration(getEnvOrDefault("FLO_ACCOUNT_SYNC_CACHE_DUR", "1h")) //1hr
	)
	r.sl.RegisterName("*syncStoreRam", func(s ServiceLocator) interface{} {
		return CreateSyncStoreRam(
			s.LocateName("*syncStore").(SyncStore),
			syncCache,
			syncCacheTtl)
	})
	r.sl.RegisterName("SyncStore", func(s ServiceLocator) interface{} {
		return s.LocateName("*syncStoreRam") //redirect to cache decorator
	})
	r.sl.RegisterName("*locStore", func(s ServiceLocator) interface{} {
		return CreateLocationStore(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("*PgSqlDb").(*PgSqlDb),
			s.LocateName("*Validator").(*Validator))
	})
	r.sl.RegisterName("*locStoreCache", func(s ServiceLocator) interface{} {
		return CreateLocationStoreCache(
			s.LocateName("*locStore").(LocationStore), //use pg impl as base
			s.LocateName("*RedisConnection").(*RedisConnection),
			s.LocateName("*Logger").(*Logger))
	})
	r.sl.RegisterName("LocationStore", func(s ServiceLocator) interface{} {
		return s.LocateName("*locStoreCache") //points to cached impl
	})

	r.sl.RegisterName("*publicGateway", func(s ServiceLocator) interface{} {
		return CreatePublicGateway(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("*httpUtilRetry").(HttpUtil),
			s.LocateName("*adminCredential").(*adminCredential),
			s.LocateName("*Validator").(*Validator))
	})
	r.sl.RegisterName("PublicGateway", func(s ServiceLocator) interface{} {
		return CreatePublicGatewayCached(
			s.LocateName("*publicGateway").(PublicGateway),
			s.LocateName("MoenAuth").(MoenAuth),
			s.LocateName("SyncStore").(SyncStore),
			s.LocateName("*RedisConnection").(*RedisConnection),
			s.LocateName("*Logger").(*Logger))
	})
	r.sl.RegisterName("AccountSync", func(s ServiceLocator) interface{} {
		unLnkFnc := func(moe *MoenUser) {
			if moe != nil && moe.Id != "" {
				tkx := s.LocateName("TokenExchange").(TokenExchange)
				tkx.RemoveUser(context.Background(), moe.Id, false)
			}
		}
		return CreateAccountSync(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("*Validator").(*Validator),
			s.LocateName("PublicGateway").(PublicGateway),
			s.LocateName("SyncStore").(SyncStore),
			s.LocateName("LocationStore").(LocationStore),
			s.LocateName("*KafkaConnection").(*KafkaConnection),
			unLnkFnc)
	})

	tokenCache := CreateRamCache("JWT", r.log) //singleton
	r.sl.RegisterName("TokenExchange", func(s ServiceLocator) interface{} {
		return CreateTokenExchange(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("MoenAuth").(MoenAuth),
			s.LocateName("PublicGateway").(PublicGateway),
			s.LocateName("SyncStore").(SyncStore),
			s.LocateName("*RedisConnection").(*RedisConnection),
			tokenCache) //always return this singleton
	})

	r.log.Trace("Done")
	return r
}

// Workers register background processes
func (r *registry) Workers() []ICloser {
	r.log.PushScope("Workers").Trace("Begin")
	defer r.log.PopScope()

	wk := make([]ICloser, 0) //add background workers here
	{
		mon := CreateActivityMonitor(
			r.sl.LocateName("*Logger").(*Logger),
			r.sl.LocateName("*KafkaConnection").(*KafkaConnection),
			r.sl.LocateName("TokenExchange").(TokenExchange),
			r.sl.LocateName("*appContext").(*appContext),
			func() AccountSync {
				return r.sl.LocateName("AccountSync").(AccountSync)
			}) //always get ref due to instance cache

		r.sl.RegisterName("ActivityMonitor", func(s ServiceLocator) interface{} { return mon })
		wk = append(wk, mon) //singleton
	}

	time.Sleep(time.Millisecond * 100)
	r.log.Trace("Done")
	return wk
}

// Routes register REST http routes
func (r *registry) Routes(w *WebServer, sl ServiceLocator) {
	r.log.Trace("Routes: begin")
	defer r.log.Trace("Routes: done")

	requireAuth := func(c *gin.Context) bool {
		p := c.Request.URL.Path
		return (strings.Index(p, "/sync") == 0 && p != "/sync/id") ||
			(strings.Index(p, "/token") == 0 && p != "/token/trade")
	}
	handler := func() WebHandler {
		return CreateWebHandler(sl, w, requireAuth) //NOTE: we are using webServer's ref of sl here
	}
	//not authenticated
	w.router.GET("/", func(c *gin.Context) { handler().Ping(c) })
	w.router.GET("/ping", func(c *gin.Context) { handler().Ping(c) })
	w.router.POST("/ping", func(c *gin.Context) { handler().Ping(c) })             //deep ping
	w.router.GET("/token/trade", func(c *gin.Context) { handler().TokenTrade(c) }) //self authenticated

	//authenticated above (at public-gateway level), not authenticated here
	w.router.GET("/sync/id", func(c *gin.Context) { handler().LookupSyncIds(c) })      //internal route for looking up Flo user id
	w.router.DELETE("/sync/id", func(c *gin.Context) { handler().CacheInvalidate(c) }) //clear local ram cache only
	w.router.GET("sync/locations", func(c *gin.Context) { handler().GetFloLocMap(c) })
	w.router.POST("sync/locations", func(c *gin.Context) { handler().PutFloLocMap(c) })
	w.router.DELETE("sync/locations", func(c *gin.Context) { handler().RemoveFloLocMap(c) })

	w.router.Use(handler().EnsureAuthorizedDecorator) //all EPs after this will have this MiddleWare applied

	//middleware authenticated
	w.router.GET("/token", func(c *gin.Context) { handler().GetMoenUser(c) })
	w.router.HEAD("/sync/me", func(c *gin.Context) { handler().CheckSync(c) })
	w.router.GET("/sync/me", func(c *gin.Context) { handler().GetFloUser(c) })
	w.router.PUT("/sync/me", func(c *gin.Context) { handler().SyncFloUser(c) })
	w.router.DELETE("/sync/me", func(c *gin.Context) { handler().UnSyncFloUser(c) })
	w.router.POST("/sync/new", func(c *gin.Context) { handler().CreateFloUser(c) })
	w.router.POST("/sync/auth", func(c *gin.Context) { handler().SyncAuthorizedUser(c) })
}
