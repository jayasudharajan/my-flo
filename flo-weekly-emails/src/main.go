package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"
)

const (
	APP_NAME              = "flo-weekly-emails"
	ENVVAR_KAFKA_GROUP_ID = "FLO_KAFKA_GROUP_ID"
)

var (
	_commitSha  string
	_commitTime string
	_hostName   string
	_start      time.Time
	_osInterupt chan os.Signal
)

func init() {
	_start = time.Now()
	_osInterupt = make(chan os.Signal, 1)
}

func signalExit() {
	_log.Fatal("signalExit")
	_osInterupt <- syscall.SIGABRT
}

// @title flo-weekly-emails Api
// @version 1.0
// @description flo-weekly-emails Api Documentation
// @schemes https http
func main() {
	_log.Info("main: Starting...")
	_hostName = getHostname()

	_log.Info("main: Started")
	var (
		ioc = singleton{log: _log, die: signalExit}
		ws  = ioc.WebServer(false, registerRoutes)
		sig os.Signal
		ok  bool
	)
	if ws != nil {
		ws.Open()

		signal.Notify(_osInterupt, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
		sig, ok = <-_osInterupt // Block until we receive our signal.
		fmt.Println()

		if !ok {
			_log.Debug("console signal close received")
		}
		_log.Info("main: Stopping...")
		ws.Close()
	}

	close(_osInterupt)
	_log.Info("main: Stopped. Uptime was %v", fmtDuration(time.Since(_start)))

	if sig == syscall.SIGABRT {
		os.Exit(-11)
	} else {
		os.Exit(0)
	}
}
