package main

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

type PingHandler interface {
	Ping(*gin.Context)
	Die(*gin.Context)
	Catch(*gin.Context)
}

type pingHandler struct {
	svc ServiceLocator
}

func CreatePingHandler(svcLoc ServiceLocator) PingHandler {
	return &pingHandler{svcLoc}
}

// Ping godoc
// @Summary check the health status of the service and list its config data
// @Description returns status of the service
// @Tags system
// @Accept  json
// @Produce  json
// @Success 200
// @Router /ping [get]
// Health is the handler for ping
func (h *pingHandler) Ping(c *gin.Context) {
	var (
		started = time.Now()
		code    = http.StatusOK
		sl      = h.svc.Context(c)
		log     = sl.LocateName("Log").(Log)
		app     = sl.LocateName("*appContext").(*appContext)
	)
	log.PushScope("Ping")
	defer log.PopScope()
	c.Set("Log", log)

	rv := map[string]interface{}{
		"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		"app":        app.App,
		"status":     "OK",
		"commit":     _commitSha,
		"branch":     _commitBranch,
		"commitTime": _commitTime,
		"env":        app.Env,
		"debug":      log.IsDebug(),
		"uptime":     time.Since(app.Start).String(),
	}
	if c.Request.Method == "POST" { //deep ping
		h.deep(log, c, rv)
	}
	if strings.EqualFold(c.Query("log"), "true") {
		defer func(r interface{}, t time.Time) {
			log.Info("%vms | %v", time.Since(t).Milliseconds(), tryToJson(r))
		}(rv, started)
	}
	rv["took"] = time.Since(started).String()
	if rv["status"] != "OK" {
		code = http.StatusServiceUnavailable
	}
	log.Trace("status: %v", rv["status"])
	c.JSON(code, rv)
}

func (h *pingHandler) deep(log Log, c *gin.Context, rv map[string]interface{}) {
	var (
		svc    = h.svc.Context(c)
		redis  = svc.SingletonName("RedisConnection").(RedisConnection)
		kafka  = svc.SingletonName("KafkaConnection").(KafkaConnection)
		pgSql  = svc.SingletonName("Postgres").(Postgres)
		pubGw  = svc.LocateName("FloAPI").(FloAPI)
		trace  = c.Query("trace") != ""
		checks = make(map[string]string)
	)
	log.PushScope("deep")
	defer log.PopScope()

	h.pingDependency(log, checks, "redis", redis.Ping, trace)
	h.pingDependency(log, checks, "kafka", kafka.Ping, trace)
	h.pingDependency(log, checks, "pqSql", pgSql.Ping, trace)
	h.pingDependency(log, checks, "pubGW", pubGw.PingV2, trace)
	h.pingDependency(log, checks, "pubGW_v1", pubGw.PingV1, trace)
	rv["checks"] = checks
	for _, v := range checks {
		if v != "OK" {
			rv["status"] = "Unavailable"
			break
		}
	}
}

func (h *pingHandler) pingDependency(log Log, m map[string]string, name string, pingMe func() error, trace bool) {
	ll := IfLogLevel(trace, LL_DEBUG, LL_TRACE)
	log.Log(ll, "START %v", name)
	if e := pingMe(); e != nil {
		log.IfWarnF(e, "FAILED %v", name)
		m[name] = e.Error()
	} else {
		log.Log(ll, "OK %v", name)
		m[name] = "OK"
	}
}

func (h *pingHandler) Die(c *gin.Context) {
	var (
		sl  = h.svc.Context(c)
		log = sl.LocateName("Log").(Log)
	)
	go func() {
		defer os.Exit(0)
		log.PushScope("Die")
		defer log.PopScope()

		log.Notice("Goodbye 💔")
		time.Sleep(time.Second / 2)
	}()
	c.Data(204, "text/html", nil)
}

func (h *pingHandler) processCatch(he *HttpErr) *HttpErr {
	if he.Code < 400 {
		he.Code = 500
	} else if he.Code == 408 || he.Code == 504 {
		if n, _ := strconv.ParseFloat(he.Message, 64); n > 0 {
			time.Sleep(time.Duration(n) * time.Second)
			he.Message = fmt.Sprintf("Slept for %v seconds", n)
		} else {
			time.Sleep(time.Second * 11) //ensure timeout
		}
	}
	if he.Message == "" {
		he.Message = "Something went wrong*"
	}
	return he
}

func (h *pingHandler) Catch(c *gin.Context) {
	var (
		he = new(HttpErr)
		sl = h.svc.Context(c)
		w  = sl.SingletonName("WebServer").(WebServer)
	)
	if e := w.HttpReadBody(c, he); e != nil {
		return //already wrote error
	} else {
		he = h.processCatch(he)
		c.JSON(he.Code, he)
	}
}
