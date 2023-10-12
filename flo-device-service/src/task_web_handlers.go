package main

import (
	"database/sql"
	"device-service/models"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
)

type TaskRouteHandler struct {
	repo *PgTaskRepository
}

var taskRouteHandler TaskRouteHandler

func InitTaskHttpRequestsHandlers(db *sql.DB) {
	taskRouteHandler = TaskRouteHandler{
		repo: &PgTaskRepository{
			DB: db,
		},
	}
}

// NewFirmwarePropTask godoc
// @Summary creates a new task to syn default firmware properties
// @Description creates a new task to syn default firmware properties
// @Tags tasks
// @Accept  json
// @Produce  json
// @Success 200 {object} TaskRespose
// @Router /task/FwPropProvisioning [POST]
func (trh TaskRouteHandler) NewFirmwarePropProvisioningTask(c echo.Context) error {
	req := models.TaskReq{}
	if e := c.Bind(&req); e != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    e.Error(),
		})
	}

	uuid, _ := GenerateUuid()
	task := models.Task{
		Id:         uuid,
		MacAddress: &req.MacAddress,
		Type:       models.Type_FWPropertiesProvisioning,
		Status:     models.TS_Pending,
		CreatedAt:  time.Now().UTC(),
		UpdatedAt:  time.Now().UTC(),
	}
	err := trh.repo.InsertTask(&task)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    err.Error(),
		})
	}
	return c.JSON(http.StatusOK, models.TaskResponse{Id: uuid})
}
