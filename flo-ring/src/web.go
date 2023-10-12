package main

import (
	"strings"
)

func registerRoutes(svcLoc ServiceLocator) func(*WebServer) {
	var (
		webHandler = CreateWebHandler(svcLoc)
		debugEp    = strings.EqualFold(getEnvOrDefault("FLO_DEBUG_ENDPOINT", ""), "true")
	)

	return func(w *WebServer) {
		//💓 EPs
		w.router.GET("/", webHandler.Ping())
		w.router.GET("/ping", webHandler.Ping())
		w.router.POST("/ping", webHandler.Ping())
		if debugEp || _log.isDebug {
			w.router.HEAD("/chop", webHandler.Die())
			w.router.POST("/throw", webHandler.Catch(w))
		}

		//EPs for testing
		w.router.GET("/messages/:messageId", webHandler.MessageRetrievalById())
		w.router.GET("/devices/:deviceId/messages", webHandler.MessagesByDevice())
		w.router.GET("/devices/:deviceId", webHandler.ReportStateDebug())
		w.router.GET("/users/:userId/discovery", webHandler.DeviceDiscoverDebug())
		w.router.PUT("/users/:userId", webHandler.UserLink())      //NOTE: no events fired, for testing only
		w.router.DELETE("/users/:userId", webHandler.UserUnLink()) //NOTE: this does not log user out, just delete ops
		w.router.POST("/sync/devices", webHandler.DeviceCleanup())

		//lambda EPs
		w.router.Use(webHandler.ParseAndStoreDirectiveMiddleware()) //messageId injection into logger should happen here
		if debugEp || _log.isDebug {
			w.router.POST("/lambda/:namespace/throw/:messageId", webHandler.ThrowDirective())
		}

		w.router.POST("/lambda/:namespace/authorizeuser/:messageId", webHandler.UserAuthorization())
		w.router.POST("/lambda/:namespace/refreshtoken/:messageId", webHandler.UserRefreshToken())
		w.router.POST("/lambda/:namespace/revokeaccess/:messageId", webHandler.RevokeAccess())

		w.router.Use(webHandler.TokenCheckMiddleware())

		w.router.POST("/lambda/:namespace/getprofile/:messageId", webHandler.UserProfile())
		w.router.POST("/lambda/:namespace/discover/:messageId", webHandler.DeviceDiscovery())
		w.router.POST("/lambda/:namespace/setmode/:messageId", webHandler.ValveControl())
		w.router.POST("/lambda/:namespace/reportstate/:messageId", webHandler.ReportState())
	}
}
