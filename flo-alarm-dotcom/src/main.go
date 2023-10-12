package main

import (
	"syscall"
)

var (
	_commitSha    string
	_commitTime   string
	_commitBranch string
	_log          = DefaultLogger()
)

// @title flo-alarm-dotcom Api
// @version 1.0
// @description flo-alarm-dotcom Api Documentation
// @host flo-alarm-dotcom.flosecurecloud.com flo-alarm-dotcom.flocloud.co
// @schemes https http
func main() {
	_log.Notice("main: starting...")
	var (
		register = CreateRegistry(_log, ServiceLocatorWithLogCtx(CreateServiceLocator()))
		union    = register.RegisterServices().RegisterWorkers()
		app      = register.Locator().LocateName("*appContext").(*appContext)
		checker  = register.Locator().LocateName("Validator").(Validator)
	)

	if ws := CreateWebServer(checker, _log.CloneAsChild("WebSvr"), register.RegisterRoute, union); ws != nil {
		ws.Open()
		ws.Log().Info("Started")

		sig, _ := app.WaitForSignal()
		ws.Log().Notice("Stopping...")
		ws.Close()
		app.Exit(sig)
	} else {
		_log.Fatal("main: Can't Open WebServer!")
		app.Exit(syscall.SIGABRT)
	}
}
