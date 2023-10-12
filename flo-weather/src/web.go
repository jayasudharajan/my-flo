package main

import (
	"net/http"

	"github.com/gorilla/mux"
	httpSwagger "github.com/swaggo/http-swagger"
)

const ENVVAR_REDIS_CN = "FLO_REDIS_CN"

func initRedis(log *Logger) *RedisConnection {
	log.PushScope("initRedis")
	defer log.PopScope()

	rcn := getEnvOrDefault(ENVVAR_REDIS_CN, "")
	if rcn == "" {
		log.Fatal("env %v is missing", ENVVAR_REDIS_CN)
		signalExit()
	}
	redis, err := newRedisConnection(rcn)
	if err != nil {
		log.IfFatal(err)
		signalExit()
	}
	log.Debug("Connected!")
	return redis
}

func registerHandlers(log *Logger, ws *WebServer) *WebServer {
	//real registration begins
	ws.ConfigRoutes(func(mr *mux.Router) {
		mr.HandleFunc("/docs", func(w http.ResponseWriter, r *http.Request) {
			http.Redirect(w, r, "/swagger/index.html", http.StatusFound)
		})
		mr.PathPrefix("/swagger/").Handler(httpSwagger.WrapHandler)
	})
	ws.HandleTrace("/ping", ws.DefaultPingHandler, "GET")

	//all singleton scopes
	cleanLogger := log.Clone().ClearName()
	redis := initRedis(cleanLogger)
	weatherSrc := CreateWeatherSource(redis, cleanLogger)
	weatherRepo := CreateWeatherRepository(redis, cleanLogger)
	geo := CreateGeoCoderWithCache(redis, cleanLogger)
	if geo != nil {
		ws.RegisterOpenCloser(geo)
	}

	//this handler is used by pre-cache & guaranteed no recursive pre-cache trigger accidents
	preHandler := CreateWeatherHandler(ws, geo, weatherSrc, weatherRepo, nil, log)
	preCache := CreatePreCache(redis, geo, preHandler, log)
	if preCache != nil {
		ws.RegisterOpenCloser(preCache)
	}

	presence := CreatePresenceWorker(redis, preHandler.fetchAddr, cleanLogger)
	if presence != nil {
		ws.RegisterOpenCloser(presence)
	}

	ws.Handle("/temperature/geo-code", func(w http.ResponseWriter, r *http.Request) {
		handler := CreateWeatherHandler(ws, geo, weatherSrc, weatherRepo, preCache.Run, ws.Log)
		handler.GeoTemp(w, r) //proper share nothing handler scope per request
	}, "GET")
	ws.Handle("/temperature/address", func(w http.ResponseWriter, r *http.Request) {
		handler := CreateWeatherHandler(ws, geo, weatherSrc, weatherRepo, preCache.Run, ws.Log)
		handler.AddressTemp(w, r) //shared nothing handler scope per request
	}, "GET")

	if getEnvOrDefault(ENVVAR_BOOTSTRAP_REDIS_KEY, "") != "" { //only boot if there's a redis key presence
		bo0t3r := CreateBootstrap(preCache, geo, redis, log)
		if bo0t3r != nil {
			ws.RegisterOpenCloser(bo0t3r)
			go bo0t3r.DiskLoad()
		}
	}
	return ws
}
