package main

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"golang.org/x/sync/semaphore"
)

var _needInstallConcurrencySemaphore *semaphore.Weighted

type OnboardingLogServiceHandler struct {
	SqlRepo *PgOnboardingLogRepository
}

// Olsh is the global variable for OnboardingLog Service Handler
var Olsh OnboardingLogServiceHandler

func InitOnboardingLogHttpRequestsHandlers(db *sql.DB) {
	maxWeight, _ := strconv.Atoi(getEnvOrDefault("FLO_NEED_INSTALL_MAX_CONCURRENT_SEM", "10"))
	if maxWeight < 5 {
		maxWeight = 5 //minimum
	}
	logNotice("FLO_NEED_INSTALL_MAX_CONCURRENT_SEM=%v", maxWeight)
	_needInstallConcurrencySemaphore = semaphore.NewWeighted(int64(maxWeight))

	Olsh = OnboardingLogServiceHandler{
		SqlRepo: &PgOnboardingLogRepository{
			DB: db,
		},
	}
}

func (osh OnboardingLogServiceHandler) UpdateNeedsInstallHandler(ctx context.Context) error {
	limit := 500
	for offset := 0; offset <= 2000; offset += limit {
		logs, err := Olsh.SqlRepo.GetNeedInstallOnboardingLogs(offset, limit)
		if err != nil {
			log.Errorf("failed to retrieve onboarding logs. %v", err)
			return err
		}
		if len(logs) == 0 {
			return nil
		}

		logInfo("PublishFwProps: Starting need install check for devices count: %v", len(logs))
		for _, oLog := range logs {
			if err := _needInstallConcurrencySemaphore.Acquire(ctx, 1); err != nil {
				log.Errorf("failed to acquire semaphore need install. %v", err)
			}
			go func() {
				defer _needInstallConcurrencySemaphore.Release(1)
				CheckNeedInstall(ctx, Dsh.SqlRepo, oLog.MacAddress, oLog)
			}()
		}
	}
	return nil
}

// InitOnboardingLogs godoc
// @Summary Start onboarding log process
// @Description Start onboarding log process
// @Tags onboarding logs
// @Accept  json
// @Produce  json
// @Router /updateNeedsInstall [post]
func (osh OnboardingLogServiceHandler) InitOnboardingLogsHandler(c echo.Context) error {
	ctx := c.Request().Context()
	err := Olsh.UpdateNeedsInstallHandler(ctx)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    fmt.Sprintf("failed to retrieve onboarding logs"),
		})
	}

	return c.JSON(http.StatusOK, err)
}

// GetOnboardingLogs godoc
// @Summary Get onboarding logs
// @Tags onboardingLogs
// @Accept  json
// @Produce  json
// @Success 200 {array} OnboardingLogs
// @Failure 500 {object} ErrorResponse "failed to retrieve onboarding logs records"
// @Router /onboarding/_get [get]
func (osh OnboardingLogServiceHandler) GetOnboardingLogsHandler(c echo.Context) error {
	logs, err := Olsh.SqlRepo.GetNeedInstallOnboardingLogs(0, 1000)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    fmt.Sprintf("failed to retrieve onboarding logs"),
		})
	}

	return c.JSON(http.StatusOK, logs)
}
