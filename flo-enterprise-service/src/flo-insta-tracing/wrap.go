package tracing

import (
	"database/sql"
	"database/sql/driver"
	"net/http"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/gorilla/mux"
	instana "github.com/instana/go-sensor"
	"github.com/instana/go-sensor/instrumentation/instaawssdk"
	"github.com/instana/go-sensor/instrumentation/instaecho"
	"github.com/instana/go-sensor/instrumentation/instagin"
	"github.com/instana/go-sensor/instrumentation/instamux"
	"github.com/instana/go-sensor/instrumentation/instaredis"
	"github.com/labstack/echo/v4"
)

// WrapIntraredisClusterClient instruments a redis.ClusterClient
// ref: https://pkg.go.dev/github.com/instana/go-sensor/instrumentation/instaredis#section-readme
func WrapInstaredisClusterClient(client instaredis.InstanaRedisClusterClient, sensor instana.TracerLogger) {
	if !IsTracingDisabled() {
		instaredis.WrapClusterClient(client, sensor)
	}
}

// WrapIntraredisClient instruments a redis.Client
// ref: https://pkg.go.dev/github.com/instana/go-sensor/instrumentation/instaredis#section-readme
func WrapInstaredisClient(client instaredis.InstanaRedisClient, sensor instana.TracerLogger) {
	if !IsTracingDisabled() {
		instaredis.WrapClient(client, sensor)
	}
}

// WrapIntraredisUniversalClient instruments a redis.UniversalClient
//
//	client := redis.NewUniversalClient(cfg)
//	tracing.WrapInstaredisUniversalClient(client, cfg, tracing.Instana)
func WrapInstaredisUniversalClient(client redis.UniversalClient, cfg *redis.UniversalOptions, sensor instana.TracerLogger) {
	if !IsTracingDisabled() {
		// logic taken from redis@v6.15.9/universal.go:173
		if cfg.MasterName == "" && len(cfg.Addrs) > 1 {
			if rcc, ok := client.(instaredis.InstanaRedisClusterClient); ok {
				WrapInstaredisClusterClient(rcc, Instana)
			}
		} else {
			if rc, ok := client.(instaredis.InstanaRedisClient); ok {
				WrapInstaredisClient(rc, Instana)
			}
		}
	}
}

// WrapSqlOpen performs SQL Open and adds instrumentation
//
//	db, err := tracing.WrapSqlOpen(tracing.Instana, "postgres", pq.Driver{}, cnString)
//
// ref: https://www.ibm.com/docs/en/instana-observability/current?topic=go-collector-common-operations#database-clients
func WrapSqlOpen(sensor instana.TracerLogger, driverName string, driver driver.Driver, cn string) (*sql.DB, error) {
	var (
		db  *sql.DB
		err error
	)
	if !IsTracingDisabled() {
		instana.InstrumentSQLDriver(sensor, driverName, driver)
		db, err = instana.SQLOpen(driverName, cn)
	} else {
		db, err = sql.Open(driverName, cn)
	}
	return db, err
}

// WrapMux instruments http mux router
//
//	ws.instana = tracing.InitInstana(sn)
//	tracing.WrapMux(ws.instana, ws.router)
func WrapMux(sensor instana.TracerLogger, router *mux.Router) {
	if !IsTracingDisabled() {
		instamux.AddMiddleware(sensor, router)
	}
}

// WrapInstagin instruments http gin engine
//
//	ws.instana = tracing.InitInstana(sn)
//	tracing.WrapInstagin(ws.instana, ws.router)
func WrapInstagin(sensor instana.TracerLogger, engine *gin.Engine) {
	if !IsTracingDisabled() {
		instagin.AddMiddleware(sensor, engine)
	}
}

// WrapRoundTripper returns the instana RoundTripper for http client
//
//	hc := &http.Client{Timeout: timeout}
//	hc.Transport = tracing.WrapRoundTripper(tracing.Instana, hc.Transport)
func WrapRoundTripper(sensor instana.TracerLogger, original http.RoundTripper) http.RoundTripper {
	if !IsTracingDisabled() {
		return instana.RoundTripper(sensor, original)
	} else {
		return original
	}
}

// WrapInstaawssdk instruments certain aws sdk calls
//
//	ws.instana = tracing.InitInstana(sn)
//	if ss, ok := sl.LocateName("*session.Session").(*session.Session); ok {
//			tracing.WrapInstaawssdk(ss, tracing.Instana)
//	}
func WrapInstaawssdk(sess *session.Session, sensor instana.TracerLogger) {
	if !IsTracingDisabled() {
		instaawssdk.InstrumentSession(sess, sensor)
	}
}

// WrapNewInstaecho creates an instrumented echo router
// ref: https://pkg.go.dev/github.com/instana/go-sensor/instrumentation/instaecho
func WrapNewInstaecho(sensor instana.TracerLogger) *echo.Echo {
	var (
		e *echo.Echo
	)
	if !IsTracingDisabled() {
		e = instaecho.New(sensor)
	} else {
		e = echo.New()
	}
	return e
}
