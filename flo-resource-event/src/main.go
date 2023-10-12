package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"flotechnologies.com/flo-resource-event/src/commons/utils"
	"flotechnologies.com/flo-resource-event/src/commons/validator"
)

var (
	_commitSha   string
	_commitTime  string
	_hostName    string
	_appName     string
	_start       time.Time
	_osInterrupt chan os.Signal
	_validator   *validator.Validator
)

func CommitSha() string {
	return _commitSha
}

func CommitTime() string {
	return _commitTime
}

func HostName() string {
	return _hostName
}

func AppName() string {
	return _appName
}

func init() {
	_start = time.Now()
	_appName = utils.GetEnvOrDefault("APPLICATION_NAME", "flo-resource-event")
	_osInterrupt = make(chan os.Signal, 1)
}

func SignalExit() {
	_osInterrupt <- syscall.SIGABRT
}

// @title flo-resource-event Api
// @version 1.0
// @description flo-resource-event Api Documentation
// @host flo-resource-event.flosecurecloud.com flo-resource-event.flocloud.co
// @schemes https http
func main() {
	utils.LogInfo("main: Starting...")
	var (
		sig os.Signal
		ok  bool
		err error
	)
	_hostName = utils.GetHostname()
	_validator, err = validator.CreateValidator()

	if err != nil {
		utils.LogDebug("console signal close received")
	}

	if ws := CreateWebServer(_validator, utils.Log(), registerRoutes, nil).Open(); ws != nil {
		utils.LogInfo("main: Started")
		signal.Notify(_osInterrupt, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
		sig, ok = <-_osInterrupt
		fmt.Println()
		if !ok {
			utils.LogDebug("console signal close received")
		}
		utils.LogInfo("main: Stopping...")
		ws.Close()
	}

	close(_osInterrupt)
	utils.LogInfo("main: Stopped. Uptime was %v", time.Since(_start))
	if sig == syscall.SIGABRT {
		os.Exit(-11)
	} else {
		os.Exit(0)
	}
}
