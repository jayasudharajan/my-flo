package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync/atomic"
	"time"
)

// Registry setup services and provide a way to locate them by name
type Registry interface {
	RegisterServices() Registry
	RegisterWorkers() []OpenCloser
	RegisterRoute(w WebServer, r gin.IRoutes)
	Locator() ServiceLocator
	LocatorCtx(name string) ServiceLocator
}

type registry struct {
	log  Logger
	exit func()
	sl   ServiceLocator
}

func CreateRegistry(log Logger, sl ServiceLocator) Registry {
	var (
		lgr       = log.Clone().SetName("AppCtx")
		app       = NewAppContext(lgr, _commitSha, _commitTime, _commitBranch).SetHost() //static singleton
		delayExit = func() {
			time.Sleep(time.Second)
			app.Exit(os.Interrupt)
		}
		reg = registry{log.CloneAsChild("Reg"), delayExit, sl}
	)
	reg.sl.RegisterName("Logger", func(s ServiceLocator) interface{} { return DefaultLogger() })
	reg.sl.AliasNames("Logger", "Log")
	reg.sl.RegisterName("*appContext", func(s ServiceLocator) interface{} { return app })
	return &reg
}

func (r *registry) Locator() ServiceLocator {
	return r.sl
}

func (r *registry) LocatorCtx(name string) ServiceLocator {
	sl := r.sl.Clone()
	sl.RegisterName("Logger", func(s ServiceLocator) interface{} {
		return r.log.Clone().SetName(name)
	})
	return sl
}

// foundational utilities
func (r *registry) regUtils(floApiUrl string) {
	r.log.PushScope("regUtils")
	defer r.log.PopScope()
	r.log.Trace("Begin")

	r.sl.RegisterName("*http.Client", func(s ServiceLocator) interface{} { //meant to be used as singleton
		sec, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_HTTP_TIMEOUT_S, ""))
		if sec < 0 {
			sec = 4
		}
		return &http.Client{Timeout: time.Duration(int64(sec)) * time.Second}
	})
	r.sl.RegisterName("*httpUtil", func(s ServiceLocator) interface{} {
		return CreateHttpUtilFromClient(
			"",
			s.LocateName("Log").(Log), //allow a new or current instance of logger
			-1,
			s.SingletonName("*http.Client").(*http.Client)) //reuse no matter what
	})
	r.sl.RegisterName("HttpUtil", func(s ServiceLocator) interface{} {
		base := s.LocateName("*httpUtil").(*httpUtil)
		return CreateHttpUtilRetry(base, nil)
	})
	r.sl.RegisterName("MockHttpUtil", func(s ServiceLocator) interface{} {
		return CreateMockHttpUtil(
			s.SingletonName("HttpUtil").(HttpUtil),
			s.LocateName("Log").(Log),
			AdcMockEndPoints)
	})
	r.sl.RegisterName("Validator", func(s ServiceLocator) interface{} {
		if v, e := CreateValidator(_loggerSbPool); e != nil {
			r.log.IfWarnF(e, "Validator RegisterName")
			defer r.exit()
			return nil
		} else {
			return v
		}
	})
	r.sl.RegisterName("SeqGen", func(s ServiceLocator) interface{} { return _seqGen })
	var (
		cleanSec, _ = strconv.ParseInt(getEnvOrDefault("FLO_RAM_CACHE_CLEAN_S", "15"), 10, 64)
		memCache    = NewRamCache("Ram$", r.log, time.Duration(cleanSec)*time.Second)
	)
	r.sl.RegisterName("RamCache", func(s ServiceLocator) interface{} {
		return memCache //singleton ish
	})

	var adcSet int32 = 0
	adc := CreateAdcEnv()
	r.sl.RegisterName("AdcEnv", func(s ServiceLocator) interface{} {
		if atomic.CompareAndSwapInt32(&adcSet, 0, 1) { //run once
			cx := s.LocateName("*appContext").(*appContext)
			if e := adc.Load(cx.IsProd()); e != nil { //preload singleton
				r.log.IfFatalF(e, "AdcEnv.Load()")
				defer r.exit()
			} else {
				r.log.Notice("AdcEnv.Load() OK!")
			}
		}
		return adc
	})
	r.log.Debug("Done")
}

var _adcEnv *AdcEnv

func (r *registry) regDbConn() {
	r.log.PushScope("regDbConn")
	defer r.log.PopScope()
	r.log.Trace("Begin")

	r.sl.RegisterName("RedisConnection", func(s ServiceLocator) interface{} {
		var (
			log        = s.LocateName("Log").(Log)
			redis, err = CreateRedisConnection(getEnvOrExit("FLO_REDIS_CN"))
		)
		if err != nil {
			log.Fatal("error connecting to redis - %v", err)
			defer r.exit()
			return nil
		}
		log.Notice("init: OK")
		return redis
	})
	r.sl.RegisterName("Postgres", func(s ServiceLocator) interface{} {
		var (
			cn  = getEnvOrExit("FLO_PGDB_CN")
			log = s.LocateName("Log").(Log)
		)
		if db, e := CreatePgSqlDb(cn, log); e != nil {
			log.Fatal("initPgSql: error open connection - %v", e)
			defer r.exit()
			return nil
		} else {
			log.Notice("init: OK")
			return db
		}
	})
	r.sl.RegisterName("KafkaConnection", func(s ServiceLocator) interface{} {
		var (
			cn  = getEnvOrExit("FLO_KAFKA_CN")
			log = s.LocateName("Log").(Log)
		)
		kafkaConnection, err := CreateKafkaConnection(cn, log)
		if err != nil {
			log.Fatal("initKafka: error creating kafka connection - %v", err)
			defer r.exit()
			return nil
		}
		log.Notice("init: OK")
		return kafkaConnection
	})
	r.log.Debug("Done")
}

// RegisterServices hook to register ALL services
func (r *registry) RegisterServices() Registry {
	r.log.PushScope("RegisterServices")
	defer r.log.PopScope()
	r.log.Trace("Begin")

	var ( //simple singletons
		floApiUrl         = getEnvOrExit("FLO_API_URL")
		floApiAccessToken = getEnvOrExit("FLO_API_JWT")
		noRamCache        = strings.EqualFold(getEnvOrDefault("FLO_RAM_CACHE_DISABLE", ""), "true")
		mockADC           = strings.EqualFold(getEnvOrDefault("FLO_MOCK_ADC_EPS", ""), "true")
		adminCred         = CreateAdminCredential(_log)
	)
	r.regUtils(floApiUrl)
	r.regDbConn()

	r.sl.RegisterName("FloJWT", func(s ServiceLocator) interface{} {
		return floApiAccessToken
	})

	r.sl.RegisterName("*entityStore", func(s ServiceLocator) interface{} { //source of truth
		return CreateEntityStore(
			s.LocateName("Log").(Log),
			s.LocateName("Validator").(Validator),
			s.SingletonName("Postgres").(Postgres)) //singleton w/ auto close
	})
	r.sl.RegisterName("*entityCache", func(s ServiceLocator) interface{} { //L1 cache
		return CreateEntityStoreCache(
			s.LocateName("*entityStore").(EntityStore),
			s.SingletonName("RedisConnection").(RedisConnection),
			s.LocateName("Log").(Log))
	})
	r.sl.RegisterName("*entityRam", func(s ServiceLocator) interface{} { //L2 cache
		return CreateEntityStoreRamCache(
			r.sl.LocateName("*entityCache").(EntityStore),
			r.sl.SingletonName("RamCache").(RamCache))
	})
	if noRamCache { // use L1 only
		r.sl.AliasNames("*entityCache", "EntityStoreViaCache")
	} else { //default entity store interface has L2 + L1 + src data
		r.sl.AliasNames("*entityRam", "EntityStoreViaCache")
	}
	r.sl.RegisterName("*entityCascade", func(s ServiceLocator) interface{} {
		return CreateEntityStoreCascade(
			s.LocateName("EntityStoreViaCache").(EntityStore),
			s.LocateName("DeviceStore").(DeviceStore))
	})
	r.sl.AliasNames("*entityCascade", "EntityStore") //default entity store interface has L2 + L1 + src data

	r.sl.RegisterName("*deviceStore", func(s ServiceLocator) interface{} {
		return CreateDeviceStore(
			r.sl.SingletonName("Postgres").(Postgres),
			r.sl.LocateName("Validator").(Validator),
			r.sl.LocateName("Log").(Log))
	})
	r.sl.RegisterName("*deviceCache", func(s ServiceLocator) interface{} {
		return CreateDeviceStoreCache(
			r.sl.LocateName("*deviceStore").(DeviceStore),
			r.sl.SingletonName("RedisConnection").(RedisConnection),
			r.sl.LocateName("Log").(Log))
	})
	r.sl.RegisterName("*deviceRam", func(s ServiceLocator) interface{} {
		return CreateDeviceStoreRam(
			r.sl.LocateName("*deviceCache").(DeviceStore),
			r.sl.SingletonName("RamCache").(RamCache))
	})
	if noRamCache { //only use L1
		r.sl.AliasNames("*deviceCache", "DeviceStore")
	} else { //default device store with L1 cache as local RAM, L2 cache as redis
		r.sl.AliasNames("*deviceRam", "DeviceStore")
	}

	r.sl.RegisterName("StatNotifyManager", func(s ServiceLocator) interface{} {
		var (
			htu   HttpUtil
			appCx = s.LocateName("*appContext").(*appContext)
		)
		if !mockADC && appCx.IsProd() {
			htu = s.SingletonName("HttpUtil").(HttpUtil)
		} else {
			htu = s.LocateName("MockHttpUtil").(HttpUtil)
		}
		return CreateStatNotifyManager(
			s.LocateName("StatManager").(StatManager),
			s.LocateName("AdcTokenManager").(AdcTokenManager),
			s.LocateName("DeviceStore").(DeviceStore),
			s.LocateName("EntityStore").(EntityStore),
			htu,
			s.LocateName("Log").(Log),
			s.LocateName("FloAPI").(FloAPI))
	})
	r.sl.RegisterName("EntityNotifyManager", func(s ServiceLocator) interface{} {
		var (
			htu     HttpUtil
			appCx   = s.LocateName("*appContext").(*appContext)
			factory = func() StatNotifyManager {
				o := s.LocateName("StatNotifyManager")
				return o.(StatNotifyManager)
			}
		)
		if !mockADC && appCx.IsProd() {
			htu = s.SingletonName("HttpUtil").(HttpUtil)
		} else {
			htu = s.LocateName("MockHttpUtil").(HttpUtil)
		}
		return CreateEntityNotifyManager(
			s.LocateName("AdcTokenManager").(AdcTokenManager),
			s.LocateName("DeviceStore").(DeviceStore),
			s.LocateName("EntityStore").(EntityStore),
			htu,
			s.LocateName("Log").(Log),
			s.LocateName("FloAPI").(FloAPI),
			factory)
	})

	r.sl.RegisterName("FloAPI", func(s ServiceLocator) interface{} {
		floV1Url := getEnvOrDefault("FLO_API_V1", floApiUrl) //default to v2
		return CreateFloAPI(
			floV1Url,
			floApiUrl, //v2
			floApiAccessToken,
			s.SingletonName("HttpUtil").(HttpUtil).WithLogs(),
			adminCred)
	})

	r.sl.RegisterName("*atkMan", func(s ServiceLocator) interface{} {
		var (
			htu   HttpUtil
			appCx = s.LocateName("*appContext").(*appContext)
		)
		if !mockADC && appCx.IsProd() {
			htu = s.SingletonName("HttpUtil").(HttpUtil).WithLogs()
		} else {
			htu = s.LocateName("MockHttpUtil").(HttpUtil)
		}
		return CreateAdcTokenManager(
			s.LocateName("Log").(Log),
			htu,
			s.LocateName("*appContext").(*appContext),
			s.LocateName("AdcEnv").(AdcEnv))
	})
	r.sl.RegisterName("*atkCache", func(s ServiceLocator) interface{} {
		return CreateAdcTokenManagerCache(
			s.LocateName("*atkMan").(*atkMan),
			s.LocateName("Log").(Log))
	})
	r.sl.AliasNames("*atkCache", "AdcTokenManager")

	r.regIntentInvokers()
	r.log.Debug("Done")
	return r
}

type closerShim struct {
	Closers []Closer
}

func CreateCloserShim(closers ...Closer) *closerShim {
	return &closerShim{Closers: closers}
}
func (cs *closerShim) Open() {
	//do nothing to on purpose
}
func (cs *closerShim) Close() {
	if cs.Closers == nil {
		return
	}
	for _, c := range cs.Closers {
		c.Close()
	}
}

const DEFAULT_KAFKA_GROUP = "flo-alarm-dotcom-grp"

// register handlers
func (r *registry) regSubscribers() []OpenCloser {
	r.log.PushScope("regSubscribers")
	defer r.log.PopScope()
	r.log.Trace("Begin")

	var (
		workers = make([]OpenCloser, 0)
		allowBg = !strings.EqualFold(getEnvOrDefault("FLO_DISABLE_BG_WORKERS", ""), "true")
	)
	r.log.Log(IfLogLevel(!allowBg, LL_WARN, LL_NOTICE), "FLO_DISABLE_BG_WORKERS=%v", !allowBg) //if set to true, will not run any background tasks

	r.sl.RegisterName("HeartBeatHandler", func(s ServiceLocator) interface{} { //meant to be used as a singleton
		factory := func() StatNotifyManager {
			o := s.LocateName("StatNotifyManager")
			return o.(StatNotifyManager)
		}
		return CreateHeartBeatHandler(
			s.SingletonName("KafkaConnection").(KafkaConnection), //auto closing
			s.LocateName("Log").(Log),
			factory)
	})
	r.sl.RegisterName("EntityActivityHandler", func(s ServiceLocator) interface{} {
		var (
			cfg = EntityActivityKafkaConfig{
				KafkaConnection: s.SingletonName("KafkaConnection").(KafkaConnection),
				GroupId:         getEnvOrDefault("FLO_KAFKA_GROUP_ID", DEFAULT_KAFKA_GROUP),
				Topic:           getEnvOrDefault("FLO_KAFKA_TOPIC_ENTITY_ACTIVITY", "entity-activity-v1"),
			}
			factory = func() EntityNotifyManager {
				o := s.LocateName("EntityNotifyManager")
				return o.(EntityNotifyManager)
			}
			log = s.LocateName("Log").(Log)
		)
		return CreateEntityActivityHandler(log, &cfg, factory)
	})
	r.sl.RegisterName("ValveStateHandler", func(s ServiceLocator) interface{} {
		var (
			cfg = ValveStateKafkaConfig{
				KafkaConnection: s.SingletonName("KafkaConnection").(KafkaConnection),
				GroupId:         getEnvOrDefault("FLO_KAFKA_GROUP_ID", DEFAULT_KAFKA_GROUP),
				Topic:           getEnvOrDefault("FLO_KAFKA_TOPIC_VALVE_STATE", "valve-state-v1"),
			}
			factory = func() StatNotifyManager {
				o := s.LocateName("StatNotifyManager")
				return o.(StatNotifyManager)
			}
		)
		return CreateValveStateHandler(s.LocateName("Log").(Log), &cfg, factory)
	})
	if allowBg {
		workers = append(workers, r.sl.SingletonName("HeartBeatHandler").(HeartBeatHandler))
		workers = append(workers, r.sl.SingletonName("EntityActivityHandler").(EntityActivityHandler))
		workers = append(workers, r.sl.SingletonName("ValveStateHandler").(ValveStateHandler))
	}

	r.log.Debug("Done")
	return workers
}

func (r *registry) RegisterWorkers() []OpenCloser {
	r.log.PushScope("RegisterWorkers")
	defer r.log.PopScope()
	r.log.Trace("Begin")

	workers := make([]OpenCloser, 0) //close these last, in this order
	workers = append(workers, r.regSubscribers()...)
	workers = append(workers, CreateCloserShim(r.sl.SingletonName("KafkaConnection").(KafkaConnection)))
	workers = append(workers, CreateCloserShim(r.sl.SingletonName("Postgres").(Postgres)))
	workers = append(workers, r.sl.SingletonName("RamCache").(RamCache))

	r.log.Debug("Done")
	return workers
}

func (r *registry) regIntentInvokers() {
	r.log.PushScope("regIntents")
	defer r.log.PopScope()
	r.log.Trace("Start")

	r.sl.RegisterName("SyncManager", func(s ServiceLocator) interface{} {
		return CreateSyncManager(
			s.LocateName("Log").(Log),
			s.LocateName("FloAPI").(FloAPI))
	})
	r.sl.RegisterName(string(IntentSync), func(s ServiceLocator) interface{} { //warps the intent req with decorator
		return CreateSyncIntentDecor(
			s.LocateName("SyncManager").(IntentInvoker),
			s.LocateName("EntityStore").(EntityStore),
			s.LocateName("DeviceStore").(DeviceStore))
	})

	r.sl.RegisterName("StatManager", func(s ServiceLocator) interface{} {
		return CreateStatManager(
			s.LocateName("Log").(Log),
			s.LocateName("Validator").(Validator),
			s.LocateName("SeqGen").(SeqGen),
			s.LocateName("FloAPI").(FloAPI))
	})
	r.sl.AliasNames("StatManager", string(IntentQuery)) //forward intents to the right manager as IntentInvoker

	r.sl.RegisterName("CmdManager", func(s ServiceLocator) interface{} {
		return CreateCmdManager(
			s.LocateName("Log").(Log),
			s.LocateName("Validator").(Validator),
			s.LocateName("SeqGen").(SeqGen),
			s.LocateName("FloAPI").(FloAPI))
	})
	r.sl.AliasNames("CmdManager", string(IntentExecute)) //forward intents to the right manager as IntentInvoker

	r.sl.RegisterName("UnSyncManager", func(s ServiceLocator) interface{} {
		return CreateUnSyncManager(
			s.LocateName("Log").(Log),
			s.LocateName("FloAPI").(FloAPI),
			s.LocateName("EntityStore").(EntityStore))
	})
	r.sl.AliasNames("UnSyncManager", string(IntentDisconnect)) //forward intents to the right manager as IntentInvoker

	r.log.Debug("Done")
}

// RegisterRoute provide instruction for http web routes here
func (r *registry) RegisterRoute(w WebServer, router gin.IRoutes) {
	r.log.PushScope("routes")
	defer r.log.PopScope()
	r.log.Trace("init")

	r.sl.RegisterName("WebServer", func(s ServiceLocator) interface{} { return w })
	r.sl.RegisterName("IRoutes", func(s ServiceLocator) interface{} { return router })
	router.Use(func(c *gin.Context) {
		c.Set("StartTime", time.Now().UTC()) //set start time for all requests to measure execution
	})

	p := CreatePingHandler(r.LocatorCtx("PngHndlr"))
	router.GET("/", p.Ping)
	router.GET("/ping", p.Ping)
	router.POST("/ping", p.Ping)
	if r.log.IsDebug() {
		router.HEAD("/chop", p.Die)    //☠️
		router.POST("/throw", p.Catch) //⚾️
	}

	hg := CreateHomeGraphHandler(r.LocatorCtx("HomGrpHdr"))
	router.POST("/fulfillment", hg.JwtCheckMidWare, hg.IntentReqMidWare, hg.Fulfillment)

	atk := CreateAdcTokenHandler(r.LocatorCtx("AdcTkHdr"))
	router.GET("/pem", atk.CliIdCheckMidWare, atk.GetPubPEM)
	router.GET("/jwk", atk.CliIdCheckMidWare, atk.GetPubJWK)
	if r.log.IsDebug() {
		router.GET("/jwt-req", atk.CliIdCheckMidWare, atk.GetAdcReqToken)
		router.GET("/jwt-push", atk.CliIdCheckMidWare, atk.GetAdcPushToken)
	}

	ent := CreateEntityHandler(r.LocatorCtx("EntHdr"))
	router.GET("/users/:userId", ent.UsrIdChkMidWare, ent.GetUser)
	if r.log.IsDebug() {
		router.DELETE("users/:userId", ent.UsrIdChkMidWare, ent.DeleteUser)
	}
	router.POST("/users/:userId/sync", ent.UsrIdChkMidWare, ent.SyncInviteUser)
	router.POST("/users/:userId/devices", ent.UsrIdChkMidWare, ent.UpdateUserDevices)

	r.log.Trace("done")
}
