package main

import (
	"fmt"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	//_ "gitlab.com/flotechnologies/flo-moen-auth/docs"
)

type WebHandler interface {
	Ping(c *gin.Context) //endpoints w/o Authorization middleware
}

type webHandler struct {
	locator ServiceLocator
	ws      WebServer
}

func NewWebHandler(sl ServiceLocator, web WebServer) WebHandler {
	return &webHandler{sl, web}
}

func (h *webHandler) svc(c *gin.Context) ServiceLocator {
	if sl, found := c.Get("ServiceLocator"); found && sl != nil {
		return sl.(ServiceLocator) //should pull slCp
	} else {
		var (
			slCp = h.locator.Clone()
			log  = slCp.LocateName("*Logger").(*Logger).CloneAsChild("Hndlr")
		)
		slCp.RegisterName("*Logger", func(s ServiceLocator) interface{} { return log })
		c.Set("ServiceLocator", slCp)
		return slCp
	}
}

func (h *webHandler) log(c *gin.Context) *Logger {
	return h.svc(c).LocateName("*Logger").(*Logger)
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
func (h *webHandler) Ping(c *gin.Context) {
	var (
		started = time.Now()
		sl      = h.svc(c)
		log     = h.log(c)
		app     = sl.LocateName("*appContext").(*appContext)
	)
	rv := map[string]interface{}{
		"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		"app":        app.App,
		"status":     "OK",
		"branch":     app.CodeBranch,
		"commit":     app.CodeHash,
		"commitTime": app.CodeTime,
		"host":       app.Host,
		"env":        app.Env,
		"debug":      h.log(c).isDebug,
		"uptime":     time.Since(app.Start).String(),
	}
	if c.Request.Method == "POST" { //deep ping
		rv["checks"], rv["status"] = h.deepPing(log, sl)
	}
	rv["took"] = time.Since(started).String()
	if rv["status"] == "OK" {
		c.JSON(200, rv)
	} else {
		c.AbortWithStatusJSON(503, rv)
	}
}

func (h *webHandler) deepPing(log *Logger, sl ServiceLocator) (map[string]string, string) {
	var (
		errAr = make([]string, 0)
		stats = make(map[string]string)
		msg   = "OK"
	)
	safePing := func(name string, p Pingable) error { //crash proofing
		defer panicRecover(log, "Ping: %v", name)
		return p.Ping()
	}
	check := func(name string, p Pingable) {
		if e := safePing(name, p); e != nil {
			stats[name] = e.Error()
			errAr = append(errAr, name)
		} else {
			stats[name] = "OK"
		}
	}

	//check("redis", sl.SingletonName("*RedisConnection").(*RedisConnection)) //we are not using redis ... yet
	ns := sl.SingletonName("NotifySub").(NotifySub)
	check("kafka", &pingAdaptor{ns.PingKafka})
	check("mqtt", &pingAdaptor{ns.PingMqtt})
	if len(errAr) != 0 {
		msg = fmt.Sprintf("%v failed", strings.Join(errAr, ","))
	}
	return stats, msg
}

type Pingable interface {
	Ping() error
}

type pingAdaptor struct {
	png func() error
}

func (p *pingAdaptor) Ping() error {
	return p.png()
}
