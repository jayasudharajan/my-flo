package main

type Services struct {
	syncService SyncService
}

func registerRoutes(log *Logger, appInfo *AppInfo, services *Services) func(*WebServer) {
	webHandler := CreateWebHandler(log, appInfo, services)

	return func(w *WebServer) {
		w.router.GET("/", webHandler.Ping())
		w.router.GET("/ping", webHandler.Ping())

		w.router.POST("/devices/:macAddress/sync", webHandler.SyncDevice())
	}
}
