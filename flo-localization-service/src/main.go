package main

import (
	"fmt"
	"os"
	"runtime"
	"time"

	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
	"github.com/labstack/gommon/log"
)

// These global variables are set by GO compiler if provided. Can be used to internally.
var commitName string
var commitSha string
var commitTime string

// @title Localization Service (LS) API
// @version 1.0
// @Description Localization Service (LS) is responsible for providing FLO Technologies localized content (language and country specific).

// @contact.name Alexander Galushka
// @contact.email alex.galushka@flotechnologies.com

// @host flo-localization-service.flocloud.co
// @basePath /v1
// @schemes http https

func main() {

	// initialize service configuration
	InitConfig(commitName, commitSha, commitTime)

	// initialize relational database, e.g. Postgres
	db, err := InitRelationalDb()
	if err != nil {
		log.Fatal(err)
	}

	jsonToDb, dbToJson := MapJsonToDbAndDbToJson(Asset{})
	mutableAssetFields, err := GetMutableStructJsonFields(Asset{})
	if err != nil {
		log.Fatal(err)
	}
	mutableLocaleFields, err := GetMutableStructJsonFields(Locale{})
	if err != nil {
		log.Fatal(err)
	}

	assetTagsMappings := AssetTagsMappings{
		JsonToDb: jsonToDb,
		DbToJson: dbToJson,
	}

	InitLocalizationServiceHandlers(db, mutableAssetFields, mutableLocaleFields, assetTagsMappings)

	InitInMemoryDatastore(db, assetTagsMappings)

	// preset echo
	e := echo.New()
	e.Use(setupLogger())
	e.Use(middleware.Recover())
	e.Pre(middleware.RemoveTrailingSlash())
	e.Use(middleware.CORS())

	// initialize all the routes
	InitRouters(e)

	log.Debugf("%s has %d goroutines before starting web server", ServiceName, runtime.NumGoroutine())

	// kick echo web server
	err = e.Start(fmt.Sprintf(":%s", WebServerPort))
	if err != nil {
		log.Fatalf("failed to start web server, err: %v", err)
	}
}

func setupLogger() echo.MiddlewareFunc {
	var ourLogConfig = middleware.LoggerConfig{
		Skipper:          middleware.DefaultSkipper,
		Format:           `${time_rfc3339} INFO ${status} ${method} ${uri} ${remote_ip} ${latency_human} "${user_agent}" ${error}` + "\n",
		CustomTimeFormat: time.RFC3339,
		Output:           os.Stdout,
	}

	return middleware.LoggerWithConfig(ourLogConfig)
}
