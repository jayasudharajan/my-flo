package main

import (
	"net/http"
	"strconv"
	"strings"
	"sync/atomic"
	"time"
)

// foundational utilities
func registerUtils(floApiUrl string) {
	_log.Trace("registerUtils: Begin")
	_svc.RegisterName("*Logger", func(s ServiceLocator) interface{} {
		return DefaultLogger()
	})
	_svc.RegisterName("*http.Client", func(s ServiceLocator) interface{} { //meant to be used as singleton
		sec, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_HTTP_TIMEOUT_S, ""))
		if sec < 0 {
			sec = 4
		}
		return &http.Client{Timeout: time.Duration(int64(sec)) * time.Second}
	})
	_svc.RegisterName("*httpUtil", func(s ServiceLocator) interface{} {
		return CreateHttpUtilFromClient(
			"",
			s.LocateName("*Logger").(*Logger), //allow a new or current instance of logger
			-1,
			s.SingletonName("*http.Client").(*http.Client)) //reuse no matter what
	})
	_svc.RegisterName("BrokenValves", func(s ServiceLocator) interface{} {
		return CreateBrokenValves(s.LocateName("*Logger").(*Logger))
	})
	_log.Debug("registerUtils: OK")
}

// hook to register ALL services
func registerServices() []ICloser {
	_log.Trace("registerServices: Begin")
	var ( //simple singletons
		floApiUrl         = getEnvOrExit("FLO_API_URL")
		floApiAccessToken = "Bearer " + getEnvOrExit("FLO_API_RING_SERVICE_ACCESS_TOKEN")
		awsApiKey         = getEnvOrExit("FLO_AMAZON_KEY_API_KEY")
		debugAllow        = DefaultAllowResource()
	)
	registerUtils(floApiUrl)

	_svc.RegisterName("FloJWT", func(s ServiceLocator) interface{} {
		return floApiAccessToken
	})
	_svc.RegisterName("*RedisConnection", func(s ServiceLocator) interface{} { return initRedis() })
	_svc.RegisterName("*PgSqlDb", func(s ServiceLocator) interface{} { return initPgSql() })
	_svc.RegisterName("SnsClient", func(s ServiceLocator) interface{} { return initSns() })
	_svc.RegisterName("MockSnsClient", func(s ServiceLocator) interface{} {
		return CreateSnsMockClient(s.LocateName("*Logger").(*Logger))
	})
	_svc.RegisterName("*KafkaConnection", func(s ServiceLocator) interface{} { return initKafka() })
	_svc.RegisterName("AllowResource", func(s ServiceLocator) interface{} { return debugAllow })

	_svc.RegisterName("EntityStore", func(s ServiceLocator) interface{} {
		return CreateEntityStore(
			s.LocateName("*Logger").(*Logger),
			s.SingletonName("*RedisConnection").(*RedisConnection), //singleton
			s.SingletonName("*PgSqlDb").(*PgSqlDb))                 //singleton w/ auto close
	})
	var _snsArnWarn int32 = 0
	_svc.RegisterName("RingQueue", func(s ServiceLocator) interface{} {
		var (
			sns   SnsClient
			mock  = false
			topic = getEnvOrDefault("FLO_SNS_TOPIC_ARN", "")
			log   = s.LocateName("*Logger").(*Logger)
			store = s.LocateName("EntityStore").(EntityStore)
		)
		if mock = len(topic) < 10; mock {
			sns = s.LocateName("MockSnsClient").(SnsClient)
		} else {
			sns = s.SingletonName("SnsClient").(SnsClient)
		}
		if atomic.CompareAndSwapInt32(&_snsArnWarn, 0, 1) {
			if mock {
				log.Warn("RegisterName->RingQueue FLO_SNS_TOPIC_ARN=%q | using MockSnsClient instead", topic)
			} else {
				log.Notice("RegisterName->RingQueue FLO_SNS_TOPIC_ARN=%q", topic)
			}
		}
		return CreateRingQueue(log, sns, topic, store)
	})
	_svc.RegisterName("*adminCredential", func(s ServiceLocator) interface{} {
		return DefaultAdminCredential()
	})
	_svc.RegisterName("PublicGateway", func(s ServiceLocator) interface{} {
		floV1Url := getEnvOrDefault("FLO_API_V1", floApiUrl) //default to v2
		return CreatePublicGateway(
			floV1Url,
			floApiUrl, //v2
			floApiAccessToken,
			s.LocateName("*httpUtil").(*httpUtil),
			s.SingletonName("BrokenValves").(BrokenValves),
			s.SingletonName("*adminCredential").(*adminCredential))
	})

	_svc.RegisterName("AccountSync", func(s ServiceLocator) interface{} {
		return CreateAccountSync(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("PublicGateway").(PublicGateway),
			awsApiKey,
			s.LocateName("RingQueue").(RingQueue),
			s.LocateName("EntityStore").(EntityStore),
			s.LocateName("DeviceDiscovery").(DeviceDiscovery),
		)
	})
	_svc.RegisterName("DeviceDiscovery", func(s ServiceLocator) interface{} {
		return CreateDeviceDiscovery(
			s.LocateName("*Logger").(*Logger),
			&DeviceDiscoveryAmazonConfig{
				ApiKey: awsApiKey,
			},
			s.LocateName("EntityStore").(EntityStore),
			s.LocateName("PublicGateway").(PublicGateway))
	})
	_svc.RegisterName("DeviceState", func(s ServiceLocator) interface{} {
		return CreateDeviceState(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("EntityStore").(EntityStore),
			s.LocateName("PublicGateway").(PublicGateway))
	})
	_svc.RegisterName("DeviceControl", func(s ServiceLocator) interface{} {
		return initDeviceControl(
			s.LocateName("*Logger").(*Logger),
			s.SingletonName("*RedisConnection").(*RedisConnection),
			s.LocateName("DeviceState").(DeviceState),
			s.LocateName("EntityStore").(EntityStore),
			s.LocateName("PublicGateway").(PublicGateway))
	})
	_svc.RegisterName("Inspector", func(s ServiceLocator) interface{} {
		return CreateInspector(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("EntityStore").(EntityStore))
	})
	_svc.RegisterName("Cleanup", func(s ServiceLocator) interface{} {
		return NewCleanup(
			s.LocateName("*Logger").(*Logger),
			s.LocateName("EntityStore").(EntityStore),
			s.LocateName("PublicGateway").(PublicGateway),
			s.LocateName("RingQueue").(RingQueue),
			s.LocateName("DeviceDiscovery").(DeviceDiscovery),
			s.SingletonName("*RedisConnection").(*RedisConnection))
	})

	workers := registerHandlersAndWorkers(debugAllow)
	//close these last, in this order
	workers = append(workers, CreateCloserShim(_svc.SingletonName("*KafkaConnection").(*KafkaConnection)))
	workers = append(workers, CreateCloserShim(_svc.SingletonName("*PgSqlDb").(*PgSqlDb)))
	_log.Debug("registerServices: OK")
	return workers
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

func cloneWrap(scope string, s ServiceLocator) ServiceLocator {
	log := s.LocateName("*Logger").(*Logger).PushScope(scope)
	sl := s.Clone()
	sl.RegisterName("*Logger", func(sl ServiceLocator) interface{} { return log })
	return sl
}

// register handlers
func registerHandlersAndWorkers(debugAllow AllowResource) []ICloser {
	_log.Trace("registerHandlersAndWorkers: Begin")
	var (
		workers = make([]ICloser, 0)
		allowBg = !strings.EqualFold(getEnvOrDefault("FLO_DISABLE_BG_WORKERS", ""), "true")
	)
	_log.Log(IfLogLevel(!allowBg, LL_WARN, LL_NOTICE), "FLO_DISABLE_BG_WORKERS=true") //if set to true, will not run any background tasks

	_svc.RegisterName("EntityActivityHandler", func(s ServiceLocator) interface{} { //meant to be used as a singleton
		s = cloneWrap("EntityActivityHandler", s)
		return initEntityActivityHandler(
			s.LocateName("*Logger").(*Logger),
			s.SingletonName("*KafkaConnection").(*KafkaConnection), //auto closing
			s.SingletonName("*RedisConnection").(*RedisConnection),
			s.LocateName("RingQueue").(RingQueue),
			s.LocateName("DeviceDiscovery").(DeviceDiscovery),
			s.LocateName("DeviceControl").(DeviceControl),
			s.LocateName("AccountSync").(AccountSync),
			s.LocateName("EntityStore").(EntityStore),
			debugAllow)
	})
	if allowBg {
		workers = append(workers, _svc.SingletonName("EntityActivityHandler").(EntityActivityHandler))
	}

	_svc.RegisterName("HeartBeatHandler", func(s ServiceLocator) interface{} { //meant to be used as a singleton
		s = cloneWrap("HeartBeatHandler", s)
		return CreateHeartBeatHandler(
			s.LocateName("DeviceControl").(DeviceControl),
			s.LocateName("RingQueue").(RingQueue),
			s.SingletonName("*KafkaConnection").(*KafkaConnection), //auto closing
			s.SingletonName("*RedisConnection").(*RedisConnection),
			s.LocateName("*Logger").(*Logger),
			debugAllow)
	})
	if allowBg {
		workers = append(workers, _svc.SingletonName("HeartBeatHandler").(HeartBeatHandler))
	}

	_svc.RegisterName("ValveStateHandler", func(s ServiceLocator) interface{} { //meant to be used as a singleton
		s = cloneWrap("ValveStateHandler", s)
		return initValveStateHandler(
			s.LocateName("*Logger").(*Logger),
			s.SingletonName("*KafkaConnection").(*KafkaConnection), //auto closing
			s.LocateName("RingQueue").(RingQueue),
			s.LocateName("DeviceControl").(DeviceControl),
			s.LocateName("EntityStore").(EntityStore),
			debugAllow,
			s.SingletonName("BrokenValves").(BrokenValves))
	})
	if allowBg {
		workers = append(workers, _svc.SingletonName("ValveStateHandler").(ValveStateHandler))
	}

	if strings.EqualFold(getEnvOrDefault("FLO_ENABLE_SYSTEM_MODE", ""), "true") {
		_log.Notice("FLO_ENABLE_SYSTEM_MODE is ENABLED")
		_svc.RegisterName("SystemModeHandler", func(s ServiceLocator) interface{} {
			s = cloneWrap("SystemModeHandler", s)
			return CreateSystemModeHandler(
				s.LocateName("*Logger").(*Logger),
				s.LocateName("DeviceControl").(DeviceControl),
				s.SingletonName("*KafkaConnection").(*KafkaConnection), //auto closing
				s.LocateName("RingQueue").(RingQueue),
				debugAllow)
		})
		if allowBg {
			workers = append(workers, _svc.SingletonName("SystemModeHandler").(SystemModeHandler))
		}
	} else {
		_log.Notice("FLO_ENABLE_SYSTEM_MODE is DISABLED")
	}

	_svc.RegisterName("*Scheduler", func(s ServiceLocator) interface{} {
		return CreateScheduler(
			_svc.LocateName("Cleanup").(Cleanup),
			_svc.LocateName("*RedisConnection").(*RedisConnection),
			_svc.LocateName("*Logger").(*Logger))
	})
	if allowBg {
		workers = append(workers, _svc.SingletonName("*Scheduler").(*Scheduler))
	}

	_log.Debug("registerHandlersAndWorkers: OK")
	return workers
}

func initSns() SnsClient {
	region := getEnvOrExit("FLO_SNS_REGION")
	maxRetries, err := strconv.Atoi(getEnvOrDefault("FLO_SNS_MAX_RETRIES", strconv.Itoa(defaultSnsMaxRetries)))
	if err != nil {
		maxRetries = defaultSnsMaxRetries
	}
	sns, err := CreateSnsClient(region, maxRetries)
	if err != nil {
		logFatal("initSns: error creating sns client - %v", err)
		signalExit()
		return nil
	}
	logNotice("initSns: OK")
	return sns
}

func initRedis() *RedisConnection {
	redis, err := CreateRedisConnection(getEnvOrExit("FLO_REDIS_CN"))
	if err != nil {
		logFatal("initRedis: error connecting to redis - %v", err)
		signalExit()
		return nil
	}
	logNotice("initRedis: OK")
	return redis
}

func initKafka() *KafkaConnection {
	kafkaConnection, err := CreateKafkaConnection(getEnvOrExit("FLO_KAFKA_CN"))
	if err != nil {
		logFatal("initKafka: error creating kafka connection - %v", err)
		signalExit()
		return nil
	}
	logNotice("initKafka: OK")
	return kafkaConnection
}

func initPgSql() *PgSqlDb {
	if db, e := CreatePgSqlDb(getEnvOrExit("FLO_PGDB_CN")); e != nil {
		logFatal("initPgSql: error open connection - %v", e)
		signalExit()
		return nil
	} else {
		logNotice("initPgSql: OK")
		return db
	}
}

func initDeviceControl(
	logger *Logger,
	redis *RedisConnection,
	deviceState DeviceState,
	entityStore EntityStore,
	pubGW PublicGateway) DeviceControl {

	valveStateDeferral, _ := strconv.Atoi(getEnvOrDefault("FLO_DEFERRAL_SECONDS_VALVE_STATE", strconv.Itoa(defaultValveStateDeferral)))
	if valveStateDeferral < 10 {
		valveStateDeferral = defaultValveStateDeferral
	}

	amazonConfig := &DeviceControlAmazonConfig{
		ApiKey: getEnvOrExit("FLO_AMAZON_KEY_API_KEY"),
	}
	asyncRequestExpiration, _ := strconv.Atoi(getEnvOrDefault("FLO_EXPIRATION_ASYNC_REQUEST", ""))
	if asyncRequestExpiration <= 0 {
		asyncRequestExpiration = defaultExpirationAsyncRequest
	}
	redisConfig := &DeviceControlRedisConfig{
		reqExpiration: asyncRequestExpiration,
	}
	deviceControlConfig := &DeviceControlConfig{
		setValveStateDeferral: valveStateDeferral,
		redis:                 redisConfig,
		amazon:                amazonConfig,
	}
	return CreateDeviceControl(logger, deviceControlConfig, redis, deviceState, entityStore, pubGW)
}

func initEntityActivityHandler(
	logger *Logger,
	k *KafkaConnection,
	redis *RedisConnection,
	q RingQueue,
	dd DeviceDiscovery,
	dc DeviceControl,
	as AccountSync,
	store EntityStore,
	resChk AllowResource) EntityActivityHandler {

	kafkaConfig := &EntityActivityKafkaConfig{
		KafkaConnection: k,
		GroupId:         getEnvOrExit("FLO_KAFKA_GROUP_ID"),
		Topic:           getEnvOrExit("FLO_KAFKA_TOPIC_ENTITY_ACTIVITY"),
	}
	amazonConfig := &EntityActivityAmazonConfig{
		RingQueue: q,
	}
	processors := &EntityActivityProcessors{
		DeviceDiscovery: dd,
		DeviceControl:   dc,
		AccountSync:     as,
	}
	return CreateEntityActivityHandler(logger, kafkaConfig, amazonConfig, redis, processors, store, resChk)
}

func initValveStateHandler(
	logger *Logger,
	k *KafkaConnection,
	q RingQueue,
	dc DeviceControl,
	es EntityStore,
	resChk AllowResource,
	broken BrokenValves) ValveStateHandler {

	kafkaConfig := &ValveStateKafkaConfig{
		KafkaConnection: k,
		GroupId:         getEnvOrExit("FLO_KAFKA_GROUP_ID"),
		Topic:           getEnvOrExit("FLO_KAFKA_TOPIC_VALVE_STATE"),
	}
	amazonConfig := &ValveStateAmazonConfig{
		RingQueue: q,
	}
	processors := &ValveStateProcessors{
		DeviceControl: dc,
	}
	return CreateValveStateHandler(logger, kafkaConfig, amazonConfig, processors, es, resChk, broken)
}
