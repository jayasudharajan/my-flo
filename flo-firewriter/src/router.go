package main

import (
	"net/http"

	"github.com/labstack/echo/v4"
	echoSwagger "github.com/swaggo/echo-swagger"
	_ "gitlab.com/flotechnologies/flo-firewriter/src/docs"
)

// InitRouters initiates all routers
func InitRouters(e *echo.Echo) {
	SetPingRouters(e)
	SetSwaggerRouters(e)
	SetPPROF(e)
	group := e.Group(APIVersion)
	SetDevicesRouters(group)
	SetUsersRouters(group)
	SetLocationsRouters(group)
	SetStatsRouters(group)
	SetFirestoreAuthRouters(group)
}

func SetPPROF(e *echo.Echo) {
	e.GET("/debug/pprof/*", echo.WrapHandler(http.DefaultServeMux))
}

// SetDevicesRouters sets the devices routers
func SetDevicesRouters(g *echo.Group) {
	g.POST("/firestore/devices/:deviceId", Fwh.DevicesWriterPostHandler)
	g.DELETE("/firestore/devices/:deviceId", Fwh.DevicesWriterDeleteHandler)
	g.GET("/firestore/devices/:deviceId", Fwh.DevicesWriterGetHandler)
}

// SetLocationsRouters sets the locations routers
func SetLocationsRouters(g *echo.Group) {
	g.POST("/firestore/locations/:locationId", Fwh.LocationsWriterHandler)
}

// SetPingRouters sets the ping routers
func SetPingRouters(e *echo.Echo) {
	e.GET("/ping", PingHandler)
}

// SetStatsRouters sets the devices routers
func SetStatsRouters(g *echo.Group) {
	g.GET("/stats", Fwh.StatsHandler)
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

// SetUsersRouters sets the users routers
func SetUsersRouters(g *echo.Group) {
	g.POST("/firestore/users/:userId", Fwh.UsersWriterHandler)
}

// SetFirestoreAuthRouters sets the firestore auth routers
func SetFirestoreAuthRouters(g *echo.Group) {
	g.POST("/firestore/auth", Fwh.GenerateCustomJwtHandler)
}
