package main

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
)

const requestActionRuleIdKey = "actionRuleId"

type ActionRuleServiceHandler struct {
	SqlRepo *PgActionRuleRepository
}

// Arsh is the global variable for Action Rules Service Handler
var Arsh ActionRuleServiceHandler

func InitActionRuleHttpRequestsHandlers(db *sql.DB) {
	Arsh = ActionRuleServiceHandler{
		SqlRepo: &PgActionRuleRepository{
			DB: db,
		},
	}
}

// @Summary Retrieves Action Rules for the given Device ID
// @Description Retrieves Action Rules for the given Device ID
// @Tags devices
// @Accept json
// @Produce json
// @Param id path string true "device id"
// @Success 200 {object} ActionRules
// @Failure 500 {object} ErrorResponse "failed to retrieve action rules"
// @Router /devices/{id}/actionRules [get]
func (arsh *ActionRuleServiceHandler) GetActionRulesHandler(c echo.Context) error {
	ctx := c.Request().Context()
	deviceId := c.Param(requestDeviceIdKey)

	actionRules, err := arsh.SqlRepo.GetActionRules(ctx, deviceId)

	if err != nil {
		log.Errorf("failed to retrieve action rules for device id %s: %s", deviceId, err.Error())
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    SomethingWentWrongErrMsg,
		})
	}

	return c.JSON(http.StatusOK, ActionRules{
		Data: actionRules,
	})
}

// @Summary Upserts Action Rules for the given Device ID
// @Description Upserts Action Rules for the given Device ID
// @Tags devices
// @Accept json
// @Produce json
// @Param id path string true "device id"
// @Param actionRules body ActionRules true "Action Rules"
// @Success 200 {object} ActionRules
// @Failure 500 {object} ErrorResponse "failed to upsert action rules"
// @Router /devices/{id}/actionRules [post]
func (arsh *ActionRuleServiceHandler) UpsertActionRulesHandler(c echo.Context) error {
	deviceId := c.Param(requestDeviceIdKey)
	var actionRules ActionRules

	err := c.Bind(&actionRules)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    err.Error(),
		})
	}

	if !isValidUuid(deviceId) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    "Invalid Device ID. UUID expected.",
		})
	}

	for _, actionRule := range actionRules.Data {
		if len(actionRule.Id) > 0 && !isValidUuid(actionRule.Id) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				StatusCode: http.StatusBadRequest,
				Message:    "Invalid Action Rule ID. UUID expected.",
			})
		}

		if !isValidUuid(actionRule.TargetDeviceId) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				StatusCode: http.StatusBadRequest,
				Message:    "Invalid Device ID. UUID expected.",
			})
		}
	}

	actionRulesResponse, err := arsh.SqlRepo.UpsertActionRules(deviceId, actionRules)
	if err != nil {

		if err == UniqueConstraintFailed {
			return c.JSON(http.StatusConflict, ErrorResponse{
				StatusCode: http.StatusConflict,
				Message:    "An Action Rule with the provided event, action and target device already exists.",
			})
		}

		actionRulesStr, marshalErr := json.Marshal(actionRules)
		if marshalErr != nil {
			actionRulesStr = []byte("[]")
		}
		log.Errorf("failed to upsert action rules for device id %s - %s: %v", deviceId, actionRulesStr, err)

		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    SomethingWentWrongErrMsg,
		})
	}

	return c.JSON(http.StatusOK, actionRulesResponse)
}

// @Summary Deletes Action Rules for the given Device ID and Action Rule ID
// @Description Deletes Action Rules for the given Device ID and Action Rule ID
// @Tags devices
// @Accept json
// @Produce json
// @Param id path string true "device id"
// @Success 200 {object} ActionRule
// @Failure 500 {object} ErrorResponse "failed to delete action rule"
// @Router /devices/{id}/actionRules/{actionRuleId} [delete]
func (arsh *ActionRuleServiceHandler) DeleteActionRuleHandler(c echo.Context) error {
	deviceId := c.Param(requestDeviceIdKey)
	actionRuleId := c.Param(requestActionRuleIdKey)

	actionRuleResponse, err := arsh.SqlRepo.DeleteActionRule(deviceId, actionRuleId)
	if err != nil {
		if err == sql.ErrNoRows {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				StatusCode: http.StatusNotFound,
				Message:    "Action Rule not found.",
			})
		}
		log.Errorf("failed to delete action rule with id %s and device id %s: %s", actionRuleId, deviceId, err.Error())
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    SomethingWentWrongErrMsg,
		})
	}

	return c.JSON(http.StatusOK, actionRuleResponse)
}
