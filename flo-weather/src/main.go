package main

import (
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

var (
	_commitSha   string
	_commitTime  string
	_start       time.Time
	_localDebug  bool
	_osInterrupt chan os.Signal
)

func init() {
	_start = time.Now()
	_localDebug = strings.ToLower(getEnvOrDefault(ENVVAR_LOCAL_DEBUG, "")) == "true"
	_osInterrupt = make(chan os.Signal, 1)
}

func signalExit() {
	_log.Fatal("signalExit")
	_osInterrupt <- syscall.SIGABRT
}

// @title flo-weather Api
// @version 1.0
// @description flo-weather Api Documentation
// @host flo-weather.flosecurecloud.com gojumpstart.flocloud.co
// @schemes https http
func main() {
	log := DefaultLogger().SetName("main")
	log.Info("Starting...")
	var (
		sig os.Signal
		ok  bool
		ws  = registerHandlers(log, DefaultWebServerOrExit())
	)
	if ws != nil {
		log.Notice("Started")
		ws.Open(false)

		// Wait for end signal, we'll accept graceful shutdowns when quit via SIGINT (Ctrl+C) or SIGTERM, SIGKILL, SIGQUIT
		signal.Notify(_osInterrupt, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
		sig, ok = <-_osInterrupt // Block until we receive our signal.
		fmt.Println()
		if !ok {
			log.Debug("console signal close received")
		}
		log.Info("Stopping...")
		ws.Close()
	}

	close(_osInterrupt)
	log.Notice("Stopped. Uptime was %v", fmtDuration(time.Since(_start)))
	if sig == syscall.SIGABRT {
		os.Exit(-11)
	} else {
		os.Exit(0)
	}
}
