package main

import (
	"github.com/gin-gonic/gin"
	//_ "gitlab.com/flotechnologies/flo-weekly-emails/docs"
)

func registerRoutes(w *WebServer) { //IoC design, manual dependency injector
	l := w.Logger()
	l.Info("registerRoutes: start")
	ioc := singleton{log: l, die: signalExit}

	redisPing := func() (string, error) {
		e := ioc.Redis(false)._client.Ping().Err()
		return "redis", l.IfErrorF(e, "redisPing")
	}
	pgPing := func() (string, error) {
		return "pg", ioc.Sender(false).Ping()
	}
	kafkaPing := func() (string, error) {
		return "kafka", ioc.Scheduler(false).Ping()
	}
	pingAll := []func() (string, error){
		pgPing,
		kafkaPing,
		redisPing,
	}
	newHandler := func() *Handler {
		gw := ioc.pubGwSvc(false)
		snd := ioc.Sender(false)
		schd := ioc.Scheduler(false)
		return CreateHandler(w, gw, snd, schd, pingAll)
	}

	l.Debug("registerRoutes: build routes")
	w.router.GET("/", func(c *gin.Context) {
		newHandler().Ping(c)
	})
	w.router.GET("/ping", func(c *gin.Context) {
		newHandler().Ping(c)
	})
	w.router.POST("/ping", func(c *gin.Context) { //deep ping
		newHandler().Ping(c)
	})
	if w.log.isDebug { //allow local killing
		w.router.HEAD("/chop", func(c *gin.Context) {
			newHandler().Die(c)
		})
	}
	w.router.GET("/queue", func(c *gin.Context) {
		newHandler().QueueHistory(c)
	})
	w.router.POST("/queue", func(c *gin.Context) {
		newHandler().QueueOne(c)
	})
	w.router.GET("/queue/all", func(c *gin.Context) {
		newHandler().QueueAllHistory(c)
	})
	w.router.POST("/queue/all", func(c *gin.Context) {
		newHandler().QueueAll(c)
	})
	w.router.POST("/queue/all/:id/kill", func(c *gin.Context) {
		newHandler().KillAll(c)
	})
	l.Info("registerRoutes: done")
}
