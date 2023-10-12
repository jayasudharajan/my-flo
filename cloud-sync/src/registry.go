package main

import (
	"context"
	"net/http"
	"strconv"
	"sync/atomic"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

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
	r.sl.RegisterName("HttpUtil", func(s ServiceLocator) interface{} {
		return s.LocateName("HttpUtilRetry") //pointer to pointer
	})
	r.sl.RegisterName("*httpUtilRetry", func(s ServiceLocator) interface{} {
		return CreateHttpUtilRetry(
			s.LocateName("*httpUtil").(HttpUtil),
			nil,
			s.LocateName("*Logger").(*Logger))
	})
	r.sl.RegisterName("HttpUtilRetry", func(s ServiceLocator) interface{} {
		return s.LocateName("*httpUtilRetry") //pointer to instance
	})
	r.sl.RegisterName("*session.Session", func(s ServiceLocator) interface{} {
		ss, err := session.NewSession(&aws.Config{Region: aws.String("us-west-2")})
		tracing.WrapInstaawssdk(ss, tracing.Instana)
		if err != nil {
			r.log.Fatal("Unable to create aws session. %v", err.Error())
			r.signalExit()
		}
		return ss
	})

	ss := r.sl.LocateName("*session.Session").(*session.Session)
	eventBridgeClientConf := &AWSEventBridgeConfig{
		log:          r.sl.LocateName("*Logger").(*Logger),
		eventBusName: getEnvOrExit("FLO_EXTERNAL_EVENT_BRIDGE_ARN"),
		source:       getEnvOrExit("FLO_CLOUD_SYNC_EVENT_BRIDGE_SOURCE"),
		session:      ss,
	}
	eventBridgeClient := CreateAWSEventBridgeClient(eventBridgeClientConf)
	r.sl.RegisterName("*awsEventBridgeClient", func(s ServiceLocator) interface{} {
		return eventBridgeClient
	})
	r.sl.RegisterName("AWSEventBridgeClient", func(s ServiceLocator) interface{} {
		return s.LocateName("*awsEventBridgeClient") //pointer
	})

	r.sl.RegisterName("*moenAuthService", func(s ServiceLocator) interface{} {
		moenAuthServiceConfig := &MoenAuthServiceConfig{
			log:         r.sl.LocateName("*Logger").(*Logger),
			http:        r.sl.LocateName("HttpUtil").(HttpUtil),
			moenAuthUrl: getEnvOrExit("FLO_MOEN_AUTH_SERVICE"),
		}
		return CreateMoenAuthService(moenAuthServiceConfig)
	})
	r.sl.RegisterName("MoenAuthService", func(s ServiceLocator) interface{} {
		return s.LocateName("*moenAuthService") //pointer
	})

	r.sl.RegisterName("*publicGateway", func(s ServiceLocator) interface{} {
		publicGatewayConfig := &PublicGatewayConfig{
			log:         r.sl.LocateName("*Logger").(*Logger),
			http:        r.sl.LocateName("HttpUtil").(HttpUtil),
			floAPIToken: getEnvOrExit("FLO_API_TOKEN"),
			baseURL:     getEnvOrExit("FLO_API_URL"),
		}
		return CreatePublicGateway(publicGatewayConfig)
	})
	r.sl.RegisterName("PublicGateway", func(s ServiceLocator) interface{} {
		return s.LocateName("*publicGateway") //pointer
	})

	r.log.Trace("Done")
	return r
}

type closerShim struct {
	shut func()
	log  *Logger
}

func (cs *closerShim) Open(ctx context.Context) {
	//do nothing to on purpose
}
func (cs *closerShim) Close(ctx context.Context) {
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
		// r.registerPgSQL(),
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
	r.log.PushScope("registerRedis")
	defer r.log.PopScope()
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
	r.log.PushScope("registerPgSQL")
	defer r.log.PopScope()
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
	r.log.PushScope("registerKafka")
	defer r.log.PopScope()
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

// Routers register routers
func (r *registry) Routers() *registry {
	r.log.PushScope("Routers").Trace("Begin")
	defer r.log.PopScope()
	r.sl.RegisterName("*MoenRouter", func(s ServiceLocator) interface{} {
		moenRouterConfig := &MoenRouterConfig{
			log:         r.sl.LocateName("*Logger").(*Logger),
			http:        r.sl.LocateName("HttpUtil").(HttpUtil),
			floAPIToken: getEnvOrExit("FLO_API_TOKEN"),
			pubGwURL:    getEnvOrExit("FLO_API_URL"),
			eventbridge: r.sl.LocateName("AWSEventBridgeClient").(AWSEventBridgeClient),
			redis:       r.sl.LocateName("*RedisConnection").(*RedisConnection),
			moenAuthSvc: r.sl.LocateName("MoenAuthService").(MoenAuthService),
		}
		moenRouter := CreateMoenRouter(moenRouterConfig)
		return moenRouter
	})
	r.sl.RegisterName("*UnsupportedRouter", func(s ServiceLocator) interface{} {
		return CreateUnsupportedRouter(r.sl.LocateName("*Logger").(*Logger))
	})
	r.sl.RegisterName("*eventRouter", func(s ServiceLocator) interface{} {
		eventRouterConfig := &EventRouterConfig{
			log:               r.sl.LocateName("*Logger").(*Logger),
			moenSource:        getEnvOrExit("FLO_CLOUD_SYNC_MOEN_EVENT_SOURCE"),
			moenRouter:        r.sl.LocateName("*MoenRouter").(*MoenRouter),
			unsupportedRouter: r.sl.LocateName("*UnsupportedRouter").(*UnsupportedRouter),
			redis:             r.sl.LocateName("*RedisConnection").(*RedisConnection),
			eventbridge:       r.sl.LocateName("AWSEventBridgeClient").(AWSEventBridgeClient),
		}
		return CreateEventRouter(eventRouterConfig)
	})
	r.sl.RegisterName("EventRouter", func(s ServiceLocator) interface{} {
		return s.LocateName("*eventRouter") //pointer
	})
	r.log.Trace("Done")
	return r
}

// Services register main logic
func (r *registry) Services() *registry {
	r.log.PushScope("Services").Trace("Begin")
	defer r.log.PopScope()

	r.sl.RegisterName("*MessageProcessor", func(s ServiceLocator) interface{} {
		messageProcessorConfig := &MessageProcessorConfig{
			log:    r.sl.LocateName("*Logger").(*Logger),
			router: r.sl.LocateName("EventRouter").(EventRouter),
		}
		return CreateMessageProcessor(messageProcessorConfig)
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
		eacCfg := entityActivityCollectorConfig{
			log: r.sl.LocateName("*Logger").(*Logger),
			kafkaConfig: &kafkaConfig{
				kafkaConnection: r.sl.LocateName("*KafkaConnection").(*KafkaConnection),
				groupId:         getEnvOrExit("FLO_KAFKA_ENTITY_ACTIVITY_GROUP_ID"),
				topic:           getEnvOrExit("FLO_KAFKA_ENTITY_ACTIVITY_TOPIC"),
			},
			redis:         r.sl.LocateName("*RedisConnection").(*RedisConnection),
			eventbridge:   r.sl.LocateName("AWSEventBridgeClient").(AWSEventBridgeClient),
			moenAuthSvc:   r.sl.LocateName("MoenAuthService").(MoenAuthService),
			publicGateway: r.sl.LocateName("PublicGateway").(PublicGateway),
		}
		eac := NewEntityActivityCollector(&eacCfg)

		r.sl.RegisterName("EntityActivityCollector", func(s ServiceLocator) interface{} { return eac }) //singleton ref
		sqsReaderConf := &SQSReaderConfig{
			log:          r.sl.LocateName("*Logger").(*Logger),
			sqsQueueName: getEnvOrExit("FLO_SQS_NAME_EVENT_BRIDGE"),
			session:      r.sl.LocateName("*session.Session").(*session.Session),
			processor:    r.sl.LocateName("*MessageProcessor").(*MessageProcessor),
		}
		sqsReader := CreateSQSReader(sqsReaderConf)
		r.sl.RegisterName("*SQSReader", func(s ServiceLocator) interface{} { return sqsReader })

		wk = append(wk, sqsReader, eac)
	}

	time.Sleep(time.Millisecond * 100)
	r.log.Trace("Done")
	return wk
}

// Routes registers REST http endpoints
func (r *registry) Routes(w *WebServer, sl ServiceLocator) {
	r.log.PushScope("Routes").Trace("Begin")
	defer r.log.PopScope()

	webHandlerConfig := &WebHandlerConfig{sl, w}
	newHandler := func() WebHandler {
		return CreateWebHandler(webHandlerConfig)
	}
	w.router.GET("/", newHandler().Ping())
	w.router.GET("/ping", newHandler().Ping())
	w.router.POST("/ping", newHandler().Ping())
	w.router.POST("/event/receive", newHandler().SimulateInboundEvent())
	w.router.GET("/event/receive/:requestID", newHandler().GetInboundEventResponse())
	w.router.POST("/event/send", newHandler().PublishEvent())
	w.router.POST("/event/process/:type/:action", newHandler().ProcessMessage())
	r.log.Trace("Done")
}
