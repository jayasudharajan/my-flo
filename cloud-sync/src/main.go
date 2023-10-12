package main

import (
	"context"
	"os"
	"syscall"
	"time"

	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

const defaultTimeoutSeconds = 10

var (
	_commitSha    string
	_commitTime   string
	_hostName     string
	_appName      string
	_commitBranch string
	_start        time.Time
	_osInterrupt  chan os.Signal
	_validator    *Validator
)

func init() {
	_start = time.Now()
	_appName = getEnvOrDefault("APPLICATION_NAME", "cloud-sync")
	_osInterrupt = make(chan os.Signal, 1)
}

func signalExit() {
	_osInterrupt <- syscall.SIGABRT
}

// @title flo-email-gateway-v2 Api
// @version 1.0
// @description flo-email-gateway-v2 Api Documentation
// @host flo-email-gateway-v2.flosecurecloud.com cloud-sync.flocloud.co
// @schemes https http
func main() {
	ctx := context.Background()
	_log.Info("main: Starting...")
	var (
		locator  = CreateServiceLocatorWithLogs(CreateServiceLocator(), _log)
		app      = CreateAppContext(_log, _commitSha, _commitTime, _commitBranch).SetHost()
		register = &registry{_log, locator, app.ForceExit}
		union    = append(register.Utils().Routers().Services().Stores(), register.Workers()...)
		closers  = func() []ICloser { return union }
	)
	locator.RegisterName("*appContext", func(s ServiceLocator) interface{} { return app })

	// need to create tracer before the services are created so that the tracer can be passed to the middleware hooks
	startTracing()

	if ws := CreateWebServer(locator, register.Routes, closers).Open(ctx); ws != nil {
		_log.Info("main: Started")
		sig, _ := app.WaitForSignal()
		_log.Info("main: Stopping...")

		ws.Close(ctx)
		app.Exit(sig)
	} else {
		_log.Fatal("main: Can't Open WebServer!")
		app.Exit(syscall.SIGABRT)
	}
}

func startTracing() {
	// preserve this logic found in WebServer.go:CreateWebServer() - don't start Instana if log.isDebug
	if _log.isDebug {
		tracing.SetDisableTracing(true)
	}
	tracing.StartTracing(_appName)
}
