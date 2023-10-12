package main

import (
	"github.com/labstack/echo"
)

// InitRouters initiates all routers
func InitRouters(e *echo.Echo) {
	SetPingRouters(e)
	SetSwaggerRouters(e)
	group := e.Group(APIVersion)
	SetAssetsRouters(group)
	SetLocalesRouters(group)
	SetLocalizeRouters(group)
	SetTagsRouters(group)
	SetTypesRouters(group)
}

// SetAssetsRouters sets the assets routers
func SetAssetsRouters(g *echo.Group) {
	g.POST("/assets", Lsh.CreateAssetHandler)
	// Add new tag to the asset, aka tag the asset
	g.POST("/assets/:id/tags", Lsh.TagAssetHandler)

	// Overwrite the asset tags
	g.PUT("/assets/:id/tags", Lsh.AddTagToAssetOfParticularTypeHandler)
	g.POST("/assets/:id", Lsh.UpdateAssetHandler)

	g.GET("/assets/:id", Lsh.GetAssetByIdHandler)
	g.GET("/assets", Lsh.GetFilteredAssetsHandler)

	g.DELETE("/assets/:id", Lsh.DeleteAssetHandler)
}

// SetPingRouters sets the ping routers
func SetPingRouters(e *echo.Echo) {
	e.GET("/ping", PingHandler)
}

// SetLocalizeRouters sets the localize routers
func SetLocalizeRouters(g *echo.Group) {
	g.GET("/localized", Lsh.GetLocalizedAssetHandler)
	g.POST("/localized", Lsh.GetLocalizedAssetsInBulkHandler)
}

// SetLocalesRouters sets the locales routers
func SetLocalesRouters(g *echo.Group) {
	g.POST("/locales", Lsh.CreateLocaleHandler)

	g.POST("/locales/:id", Lsh.UpdateLocaleHandler)

	g.GET("/locales/:id", Lsh.GetLocaleByIdHandler)
	g.GET("/locales", Lsh.GetFilteredLocalesHandler)

	g.DELETE("/locales/:id", Lsh.DeleteLocaleHandler)
}

// SetTagsRouters sets the tags routers
func SetTagsRouters(g *echo.Group) {

	g.POST("/tags", Lsh.CreateNewTagHandler)

	g.GET("/tags", Lsh.GetAllTagsHandler)

	g.DELETE("/tags/:id", Lsh.DeleteAssetHandler)
}

// SetSwaggerRouters sets the swagger documentation routers
func SetSwaggerRouters(e *echo.Echo) {
	e.GET("/swagger/*", SwaggerHandler)
}

// SetTypesRouters sets the types routers
func SetTypesRouters(g *echo.Group) {
	g.GET("/types", Lsh.GetAllTypesHandler)
}
