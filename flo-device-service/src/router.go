package main

import (
	"net/http"

	"github.com/labstack/echo/v4"
	echoSwagger "github.com/swaggo/echo-swagger"
	_ "gitlab.com/flotechnologies/flo-device-service/docs"
)

// InitRouters initiates all routers
func InitRouters(e *echo.Echo) {
	SetSystemRouters(e)
	SetSwaggerRouters(e)
	group := e.Group(APIVersion)
	SetDevicesRouters(group)
	SetFirestoreAuthRouters(group)
	SetActionRulesRouters(group)
	SetTaskRouters(group)
	SetOnboardingLogsRouters(group)
}

// SetSwaggerRouters sets the swagger documentation routers
func SetSwaggerRouters(e *echo.Echo) {
	e.GET("/swagger/*", echoSwagger.WrapHandler)
	e.GET("/docs", func(c echo.Context) (err error) {
		return c.Redirect(http.StatusFound, "/swagger/index.html")
	})
	e.GET("/swagger", func(c echo.Context) (err error) {
		return c.Redirect(http.StatusFound, "/swagger/index.html")
	})
}

// SetPingRouters sets the ping routers
func SetSystemRouters(e *echo.Echo) {
	e.GET("/", PingHandler)
	e.GET("/ping", PingHandler)
	e.POST("/ping", PingHandler) //deep ping, will check all connected data sources except MQTT
	e.GET("/syncSystemMode", func(c echo.Context) (err error) {
		ctx := c.Request().Context()
		go sleepModeReconciliation(ctx)
		return c.NoContent(202)
	})
	e.POST("/syncSystemMode", func(c echo.Context) (err error) {
		macStart := c.QueryParam("macStart")
		go _recon.ReconcileAll(macStart)
		return c.NoContent(202)
	})
}

// SetFirestoreAuthRouters sets the firestore auth routers
func SetFirestoreAuthRouters(g *echo.Group) {
	g.POST("/firestore/auth", Dsh.GenerateCustomJwtHandler)
}

// SetDevicesRouters sets the devices routers
func SetDevicesRouters(g *echo.Group) {
	g.GET("/device-summary/tail", Dsh.TailDeviceSummaryHandler)
	g.GET("/devices", Dsh.ListDevicesHandler)
	g.GET("/devices/:id", Dsh.GetDeviceHandler)
	g.DELETE("/devices/:id", Dsh.DeleteDeviceHandler)
	g.POST("/devices/_get", Dsh.GetDevicesHandler)
	g.POST("/devices/:id/sync", Dsh.DeviceSyncHandler)
	g.POST("/devices/:id/fw", Dsh.UpdateFwPropsWithMetaHandler)
	g.POST("/devices/:id/fwproperties", Dsh.UpdateDeviceFirmwarePropertiesHandler)
	g.POST("/devices/:id", Dsh.UpsertDeviceHandler)
}

// SetOnboardingLogsRouters sets the onboarding logs routers
func SetOnboardingLogsRouters(g *echo.Group) {
	g.GET("/onboardingLogs", Olsh.GetOnboardingLogsHandler)
	g.POST("/updateNeedsInstall", Olsh.InitOnboardingLogsHandler)
}

func SetTaskRouters(g *echo.Group) {
	g.POST("/task/fwPropProvisioning", taskRouteHandler.NewFirmwarePropProvisioningTask)
}

// SetActionRulesRouters sets the action rules routers
func SetActionRulesRouters(g *echo.Group) {
	g.GET("/devices/:id/actionRules", Arsh.GetActionRulesHandler)
	g.POST("/devices/:id/actionRules", Arsh.UpsertActionRulesHandler)
	g.DELETE("/devices/:id/actionRules/:actionRuleId", Arsh.DeleteActionRuleHandler)
}
