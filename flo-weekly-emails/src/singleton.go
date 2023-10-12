package main

import (
	"sync"
)

const (
	ENVVAR_REDIS_CN    = "FLO_REDIS_CN"
	ENVVAR_KAFKA_CN    = "FLO_KAFKA_CN"
	ENVVAR_KAFKA_TOPIC = "FLO_KAFKA_TOPIC"
	ENVVAR_PGDB_CN     = "FLO_PGDB_CN"
)

var (
	_redis     *RedisConnection
	_qdb       *queuedRepo
	_rdb       *runRepo
	_kafka     *KafkaConnection
	_validator *Validator
	_gw        *pubGwSvc
	_pg        *PgSqlDb
	_sender    *Sender
	_scheduler *Scheduler
	_dev       *deviceSvc
	_web       *WebServer
	_initLock  sync.Mutex
)

type singleton struct {
	die func()
	log *Logger
}

func (s *singleton) Redis(noLock bool) *RedisConnection { //lazy singleton
	if _redis == nil { //cheaper double check lock
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _redis == nil {
			var e error
			if redisCn := getEnvOrDefault(ENVVAR_REDIS_CN, ""); len(redisCn) < 3 {
				s.log.Fatal("Redis: invalid %v", ENVVAR_REDIS_CN)
			} else if _redis, e = CreateRedisConnection(redisCn); e != nil {
				s.log.IfFatalF(e, "Redis")
			}
			if _redis == nil {
				s.die()
			}
		}
	}
	return _redis
}

func (s *singleton) queueRepo(noLock bool) *queuedRepo { //lazy singleton
	if _qdb == nil { //cheaper double check lock
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _qdb == nil {
			pg := s.Postgres(true)
			valid := s.Validator(true)
			_qdb = CreateQueueRepo(pg, valid, s.log)
			if _qdb == nil {
				s.die()
			}
		}
	}
	return _qdb
}

func (s *singleton) Kafka(noLock bool) *KafkaConnection { //lazy singleton
	if _kafka == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _kafka == nil {
			var e error
			if cn := getEnvOrDefault(ENVVAR_KAFKA_CN, ""); cn == "" {
				s.log.Fatal("Kafka missing %v", ENVVAR_KAFKA_CN)
			} else if _kafka, e = OpenKafka(cn, nil); e != nil {
				s.log.IfFatalF(e, "Kafka")
			}
			if _kafka == nil {
				s.die()
			}
		}
	}
	return _kafka
}

func (s *singleton) Postgres(noLock bool) *PgSqlDb {
	if _pg == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _pg == nil {
			var e error
			if cn := getEnvOrDefault(ENVVAR_PGDB_CN, ""); len(cn) < 5 {
				s.log.Fatal("Postgres: invalid %v", ENVVAR_PGDB_CN)
			} else if _pg, e = OpenPgSqlDb(cn); e != nil {
				s.log.IfFatalF(e, "Postgres")
			}
			if _pg == nil {
				s.die()
			}
		}
	}
	return _pg
}

func (s *singleton) Validator(noLock bool) *Validator {
	if _validator == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _validator == nil {
			_validator = CreateValidator(s.log)
			if _validator == nil {
				s.die()
			}
		}
	}
	return _validator
}

func (s *singleton) pubGwSvc(noLock bool) *pubGwSvc {
	if _gw == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _gw == nil {
			redis := s.Redis(true)
			validator := s.Validator(true)
			_gw = CreatePubGwSvc(redis, validator, s.log)
			if _gw == nil {
				s.die()
			}
		}
	}
	return _gw
}

func (s *singleton) Sender(noLock bool) *Sender {
	if _sender == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _sender == nil {
			kafka := s.Kafka(true)
			kTopic := getEnvOrDefault(ENVVAR_KAFKA_TOPIC, "email-weekly-loc")
			kGroup := getEnvOrDefault(ENVVAR_KAFKA_GROUP_ID, "email-weekly-group")
			rd := s.Redis(true)
			q := s.queueRepo(true)
			gw := s.pubGwSvc(true)
			val := s.Validator(true)
			_sender = CreateSender(kafka, kTopic, kGroup, rd, q, gw, val, _log)
			if _sender == nil {
				s.die()
			}
		}
	}
	return _sender
}

func (s *singleton) Device(noLock bool) *deviceSvc {
	if _dev == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _dev == nil {
			validator := s.Validator(true)
			_dev = CreateDeviceSvc(validator, s.log)
			if _dev == nil {
				s.die()
			}
		}
	}
	return _dev
}

func (s *singleton) runRepo(noLock bool) *runRepo {
	if _rdb == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _rdb == nil {
			pg := s.Postgres(true)
			validator := s.Validator(true)
			_rdb = CreateRunRepo(pg, validator, s.log)
			if _rdb == nil {
				s.die()
			}
		}
	}
	return _rdb
}

func (s *singleton) Scheduler(noLock bool) *Scheduler {
	if _scheduler == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _scheduler == nil {
			dev := s.Device(true)
			gw := s.pubGwSvc(true)
			rdb := s.runRepo(true)
			redis := s.Redis(true)
			kaf := s.Kafka(true)
			kTopic := getEnvOrDefault(ENVVAR_KAFKA_TOPIC, "email-weekly-loc")
			_scheduler = CreateScheduler(dev, gw, rdb, redis, kaf, kTopic, s.log)
			if _scheduler == nil {
				s.die()
			}
		}
	}
	return _scheduler
}

func (s *singleton) WebServer(noLock bool, routes func(w *WebServer)) *WebServer {
	if _web == nil {
		if !noLock {
			_initLock.Lock()
			defer _initLock.Unlock()
		}
		if _web == nil {
			closers := []ICloser{
				s.Sender(true),
				s.Scheduler(true),
			}
			val := s.Validator(true)
			_web = CreateWebServer(val, s.log, routes, closers)
			if _web == nil {
				s.die()
			}
		}
	}
	return _web
}
