package main

import (
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

const (
	defaultExpirationAsyncRequest = 120
	defaultSnsMaxRetries          = 3
	defaultValveStateDeferral     = 40
)

var (
	_commitSha    string
	_commitTime   string
	_commitBranch string
	_hostName     string
	_appName      string
	_appStart     time.Time
	_osInterrupt  chan os.Signal
	_validator    Validator
	_svc          ServiceLocator
)

func init() {
	_appStart = time.Now()
	_appName = getEnvOrDefault("APPLICATION_NAME", "flo-ring")
	_osInterrupt = make(chan os.Signal, 1)
	if n, _ := strconv.Atoi(_commitTime); n > 0 {
		_commitTime = time.Unix(int64(n), 0).Format(time.RFC3339)
	}
	_commitSha = getEnvOrDefault("CI_COMMIT_SHA", _commitSha)
	_commitBranch = getEnvOrDefault("CI_COMMIT_BRANCH", _commitBranch)
	if _log.isDebug && _commitBranch == "" {
		_commitBranch = "local"
	}
	_svc = CreateServiceLocator()
}

func signalExit() {
	_osInterrupt <- syscall.SIGABRT
}

// @title flo-ring Api
// @version 1.0
// @description flo-ring Api Documentation
// @host flo-ring.flosecurecloud.com flo-ring.flocloud.co
// @schemes https http
func main() {
	logInfo("main: starting...")
	_hostName = getHostname()
	_validator, _ = NewValidator(_log.sbPool)
	tracing.StartTracing(_appName)
	var (
		sig os.Signal
		ok  bool
		wkr = registerServices() //wire up service locator instructions
	)

	if ws := CreateWebServer(_validator, _log, registerRoutes(_svc), wkr).Open(); ws != nil {
		logInfo("main: web server started")
		signal.Notify(_osInterrupt, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
		sig, ok = <-_osInterrupt
		fmt.Println()
		if !ok {
			logDebug("main: console signal close received")
		}
		logInfo("main: stopping...")
		ws.Close()
	}
	close(_osInterrupt)
	logInfo("main: stopped - uptime was %v", time.Since(_appStart))
	if sig == syscall.SIGABRT {
		os.Exit(-11)
	} else {
		os.Exit(0)
	}
}
