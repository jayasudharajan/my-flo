package main

import (
	"net/http"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis/v8"

	"github.com/labstack/echo/v4"
)

// Ping is the ping response struct
type Ping struct {
	Status      int                    `json:"status" example:"flo-device-service"`
	Service     string                 `json:"service_name" example:"flo-device-service"`
	CommitName  string                 `json:"commit_name" example:"cleanup_and_todo"`
	CommitSHA   string                 `json:"commit_sha" example:"b32ecf837b64055626a7403c15c8fb8195f4197a"`
	BuildDate   string                 `json:"build_date" example:"2019-05-03T18:44:37Z"`
	Environment string                 `json:"env" example:"dev"`
	Timestamp   string                 `json:"timestamp" example:"flo-device-service"`
	Stats       map[string]interface{} `json:"stats"`
}

// PingDeviceService godoc
// @Summary check the health status of the service and list its config data
// @Description get devices
// @Tags devices
// @Accept  json
// @Produce  json
// @Success 200 {array} Ping
// @Failure 500 {object} ErrorResponse
// @Router /ping [get]
// PingHandler is the handler for healthcheck aka ping
func PingHandler(c echo.Context) (err error) {
	ctx := c.Request().Context()

	if err = DB.Ping(); err != nil { //keeping old behavior of pining db on GET
		logWarn("PingHandler: PG %v", err)
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    "connection to DB has been lost",
		})
	}

	numOfGoroutines := runtime.NumGoroutine()
	stats := map[string]interface{}{
		"numOfGoroutines": numOfGoroutines,
	}

	if strings.EqualFold(c.Request().Method, "POST") { //deep ping

		dbStats := DB.Stats()
		stats["numOfOpenDBConnections"] = dbStats.OpenConnections

		//redis ping
		{
			cmd := _redis.Ping(ctx)
			if _, err = cmd.Result(); err != nil && err != redis.Nil {
				logWarn("PingHandler: Redis %v", err)
				return c.JSON(523, ErrorResponse{
					StatusCode: 523,
					Message:    "connection to Redis has been lost",
				})
			}
		}
		//pubGW ping
		if err = getPubGwPing(ctx); err != nil {
			logWarn("PingHandler: PubGW %v", err)
			return c.JSON(523, ErrorResponse{
				StatusCode: 523,
				Message:    "connection to PubGW is bad",
			})
		}
	}

	epochInt := 0
	if BuildDate != NoneValue {
		epochInt, err = strconv.Atoi(BuildDate)
		if err != nil {
			//log.Errorf("failed to convert epoch string %s to int", BuildDate)
			epochInt = 0
		}
	}

	return c.JSON(http.StatusOK, Ping{
		Status:      http.StatusOK,
		Service:     ServiceName,
		CommitName:  CommitName,
		CommitSHA:   CommitSHA,
		BuildDate:   time.Unix(int64(epochInt), 0).Format(time.RFC3339),
		Environment: Env,
		Timestamp:   time.Now().UTC().Truncate(time.Minute).Format(time.RFC3339),
		Stats:       stats,
	})
}
