package main

type Services struct {
	scheduler Scheduler
}

func registerRoutes(log *Logger, appInfo *AppInfo, services *Services) func(WebServer) {
	webHandler := CreateWebHandler(log, appInfo, services)

	return func(w WebServer) {
		w.GetEngine().GET("/", webHandler.Ping())
		w.GetEngine().GET("/ping", webHandler.Ping())

		w.GetEngine().POST("/tasks", webHandler.NewTask())
		w.GetEngine().POST("/tasks/:taskId/cancel", webHandler.CancelTask())
	}
}
