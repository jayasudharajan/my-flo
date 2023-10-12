package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
)

const failedToGenerateUuidErrorMsgTemplate = "failed to generate uuid for deviceId_%s request"

func (dsh *DeviceServiceHandler) parseUpdateFwReq(c echo.Context) (*FwUpdateReq, *ErrorResponse) {
	deviceId, er := dsh.parseDeviceId(c)
	if er != nil {
		return nil, er
	}

	req := FwUpdateReq{}
	if err := c.Bind(&req); err != nil {
		e := ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    "failed to bind request body",
		}
		logError("%s, err: %v", e.Error(), err)
		return nil, &e
	} else {
		req.DeviceId = deviceId
		return &req, nil
	}
}

// UpdateDeviceFirmwareProperties godoc
// @Summary updates device firmware properties with meta data, you can update any fields in model
// @Description updates device firmware properties with meta data - which is recorded for audit logging
// @Tags devices
// @Accept  json
// @Produce  json
// @Param device body FwUpdateReq true "Update device firmware properties"
// @Success 202
// @Failure 400 {object} ErrorResponse "failed to bind request body"
// @Failure 400 {object} ErrorResponse "parameter id can not be empty"
// @Failure 400 {object} ErrorResponse "failed to marshal device fw props setter"
// @Failure 500 {object} ErrorResponse ""
// @Router /devices/{id}/fw [post]
func (dsh *DeviceServiceHandler) UpdateFwPropsWithMetaHandler(c echo.Context) error {
	ctx := c.Request().Context()
	var (
		req *FwUpdateReq
		e   *ErrorResponse
	)
	if req, e = dsh.parseUpdateFwReq(c); e == nil {
		if e = dsh.pushFwUpdate(ctx, req); e == nil {
			return c.NoContent(http.StatusAccepted)
		}
	}
	if e.Message == "" {
		return c.NoContent(e.StatusCode)
	} else {
		return c.JSON(e.StatusCode, e)
	}
}

func (dsh *DeviceServiceHandler) pushFwUpdate(ctx context.Context, rq *FwUpdateReq) *ErrorResponse {
	logDebug("pushFwUpdateToMqtt: deviceId=%v | %v", rq.DeviceId, rq)

	// TODO: consider validating the keys since unknown or immutable fields will be ignored
	device, err := dsh.SqlRepo.GetDevice(ctx, rq.DeviceId)
	if err != nil {
		doesntExist := fmt.Sprintf(NoSuchDeviceErrorMsg, rq.DeviceId)
		if err.Error() == doesntExist {
			return &ErrorResponse{
				StatusCode: http.StatusNotFound,
				Message:    "Device not found",
			}
		}
		log.Errorf("failed to retrieve device with id %s: %v", rq.DeviceId, err)
		return &ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    SomethingWentWrongErrMsg,
		}
	}

	if isDevicePuck(device) {
		delete(rq.FwProps, "id")
		device.FwProperties = &rq.FwProps
		err := dsh.SqlRepo.UpsertDevice(ctx, device.MapDeviceToDeviceInternal())
		if err != nil {
			if err == sql.ErrNoRows {
				return &ErrorResponse{
					StatusCode: http.StatusNotFound,
					Message:    "Device not found.",
				}
			} else {
				log.Errorf("failed to update fwConfig for device id %s: %v", rq.DeviceId, err)
				return &ErrorResponse{
					StatusCode: http.StatusInternalServerError,
					Message:    SomethingWentWrongErrMsg,
				}
			}
		}
		return &ErrorResponse{StatusCode: http.StatusNoContent}
	}

	requestId, err := GenerateUuid()
	if err != nil {
		uuidErrorMsg := fmt.Sprintf(failedToGenerateUuidErrorMsgTemplate, rq.DeviceId)
		logError(uuidErrorMsg)
		return &ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    uuidErrorMsg,
		}
	}

	fwPropertiesSetter := FwPropertiesSetter{
		Id:           rq.DeviceId,
		RequestId:    requestId,
		FwProperties: rq.FwProps,
	}
	if buf, err := json.Marshal(fwPropertiesSetter); err != nil {
		marshalingErrorMsg := fmt.Sprintf("failed to marshal device fw props setter, err: %v", err)
		logError(marshalingErrorMsg)
		return &ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    marshalingErrorMsg,
		}
	} else {
		PublishToFwPropsMqttTopic(ctx, rq.DeviceId, QOS_1, buf, "set")
		if rq.DeviceId != "" {
			if e := dsh.SqlRepo.SetFwPropReq(ctx, rq); e != nil {
				log.Errorf("pushFwUpdate: failed to update fw_properties_req for device id %v: %v", rq.DeviceId, err)
				return &ErrorResponse{
					StatusCode: http.StatusInternalServerError,
					Message:    SomethingWentWrongErrMsg,
				}
			}
		}
		return nil
	}
}

// UpdateDeviceFirmwareProperties godoc
// @Summary updates device firmware properties, you can update any fields in model
// @Description updates device firmware properties
// @Tags devices
// @Accept  json
// @Produce  json
// @Param device body map[string]interface{} true "Update device firmware properties"
// @Success 202
// @Failure 400 {object} ErrorResponse "failed to bind request body"
// @Failure 400 {object} ErrorResponse "parameter id can not be empty"
// @Failure 400 {object} ErrorResponse "failed to marshal device fw props setter"
// @Failure 500 {object} ErrorResponse ""
// @Router /devices/{id}/fwproperties [post]
func (dsh *DeviceServiceHandler) UpdateDeviceFirmwarePropertiesHandler(c echo.Context) error {
	ctx := c.Request().Context()
	deviceId, er := dsh.parseDeviceId(c)
	if er != nil {
		return c.JSON(er.StatusCode, er)
	}

	deviceFwPropertyFieldsToUpdate := make(map[string]interface{})
	if err := c.Bind(&deviceFwPropertyFieldsToUpdate); err != nil {
		bindErrorMsg := "failed to bind request body"
		logError("%s, err: %v", bindErrorMsg, err)
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    bindErrorMsg,
		})
	}

	rq := FwUpdateReq{
		DeviceId: deviceId,
		FwProps:  deviceFwPropertyFieldsToUpdate,
	}
	if e := dsh.pushFwUpdate(ctx, &rq); e != nil {
		if e.Message == "" {
			return c.NoContent(e.StatusCode)
		} else {
			return c.JSON(e.StatusCode, e)
		}
	}
	return c.NoContent(http.StatusAccepted)
}
