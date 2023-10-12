package main

import (
	"syscall"

	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

var (
	_commitSha    string //set via CI at launch
	_commitTime   string //set via CI at launch
	_commitBranch string //set via CI at launch
	_log          = DefaultLogger()
)

// @title flo-email-gateway-v2 Api
// @version 1.0
// @description flo-email-gateway-v2 Api Documentation
// @host flo-email-gateway-v2.flosecurecloud.com flo-moen-auth.flocloud.co
// @schemes https http
func main() {
	_log.Info("main: Starting...")
	var (
		locator = CreateServiceLocatorWithLogs(CreateServiceLocator(), _log)
		app     = CreateAppContext(_log, _commitSha, _commitTime, _commitBranch).SetHost()
	)
	locator.RegisterName("*appContext", func(s ServiceLocator) interface{} { return app }) //singleton

	// need to create tracer before the modules are created so that the tracer can be passed to the middleware hooks
	startTracing(app.App)

	var (
		register = &registry{_log, locator, app.ForceExit}
		union    = append(register.Utils().Services().Stores(), register.Workers()...) //NOTE: close DBs last
		closers  = func() []ICloser { return union }
	)

	if ws := CreateWebServer(locator, register.Routes, closers).Open(); ws != nil {
		_log.Info("main: Started")
		sig, _ := app.WaitForSignal()
		_log.Info("main: Stopping...")

		ws.Close()
		app.Exit(sig)
	} else {
		_log.Fatal("main: Can't Open WebServer!")
		app.Exit(syscall.SIGABRT)
	}
}

func startTracing(deltaName string) {
	// preserve this isDebug() logic in WebServer.go:CreateWebServer() to NOT initInstana if log.isDebug
	if _log.isDebug {
		tracing.SetDisableTracing(true)
	}
	tracing.StartTracing(deltaName)
}
