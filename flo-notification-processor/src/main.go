package main

import (
	"syscall"
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
		register = NewRegistry(_log)
		union    = register.RegisterServices().RegisterWorkers()
		locator  = register.Locator()
		app      = locator.LocateName("*appContext").(*appContext)
		checker  = locator.LocateName("Validator").(Validator)
	)

	if ws := NewWebServer(checker, _log, register.RegisterRoute, union); ws != nil {
		ws.Open()
		_log.Info("main: Started")

		sig, _ := app.WaitForSignal()
		_log.Info("main: Stopping...")
		ws.Close()

		_log.Notice("main: Exit")
		app.Exit(sig)
	} else {
		_log.Fatal("main: Can't Open WebServer!")
		app.Exit(syscall.SIGABRT)
	}
}
