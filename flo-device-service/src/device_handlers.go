package main

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"github.com/opentracing/opentracing-go/ext"
)

// NOTES:
// 1. sqlRepo TXs take precedence over nosqlRepo TXs, e.g. if sqlRepo TX fails nosqlRepo TX should not be happening

const requestDeviceIdKey = "id"
const ssidKey = "ssid"
const offsetParam = "offset"
const limitParam = "limit"
const mobileParam = "mobile"
const defaultLimit = 10
const defaultOffset = 0
const errMsgDeviceIdBadRequest = "%s value has to be 12 characters long containing alphanumeric characters restricted to a-f or A-F letters"
const errMsgFailedToDeleteDeviceProps = "failed to delete device properties for deviceId_%s from the %s datastore"

const failedToGetRealTimeDataErrMsg = "failed to get %s from deviceId_%s real time data"
const telemetryKey = "telemetry"
const connectivityKey = "connectivity"

const deviceIdKey = "deviceId"

type DeviceServiceHandler struct {
	SqlRepo *PgDeviceRepository
	Cache   *RedisDeviceRepository
}

// Dsh is the global variable for Device Service Handler
var Dsh DeviceServiceHandler

func InitDeviceHttpRequestsHandlers(db *sql.DB, cache *redis.ClusterClient) {
	Dsh = DeviceServiceHandler{
		SqlRepo: &PgDeviceRepository{
			DB: db,
		},
		Cache: &RedisDeviceRepository{
			Redis: cache,
		},
	}
	if strings.EqualFold(getEnvOrDefault("DS_HEADSUP_EMAIL_DISABLE", ""), "true") {
		logNotice("DS_HEADSUP_EMAIL_DISABLE=true")
	} else if !Dsh.SqlRepo.RegisterAuditStoreEvents(Dsh.OnAuditStoreEventHeadsup) {
		logTrace("InitDeviceHttpRequestsHandlers: already registered Dsh.SqlRepo.RegisterAuditStoreEvents !?")
	}

	if !Dsh.SqlRepo.RegisterAuditStoreEvents(Dsh.OnAuditStoreEventConnectionMethod) {
		logTrace("InitDeviceHttpRequestsHandlers: already registered Dsh.SqlRepo.RegisterAuditStoreEvents !?")
	}
}

func (dsh DeviceServiceHandler) OnAuditStoreEventHeadsup(ae *AuditStoredEvent) {
	ctx := context.Background()
	st := time.Now()
	if ae == nil {
		return
	} else if !ae.hasChange(FWPROPS_AUDIT_WHITELIST_HEADSUP) {
		logDebug("OnAuditStoreEventHeadsup: no change detected, skipping POST headsup for %v", ae.ChangeRequest.DeviceId)
		return
	}
	//hu := CreateHttpUtil(token, &httpAdaptor{httpClient}) //use device service retry clients (might cause flooding)
	hu := CreateHttpUtil(token, nil) //use go's no retry client
	uri := fmt.Sprintf("%v/api/v2/headsup/devices", FloApiUrl)
	if rid, e := hu.Do(ctx, "POST", uri, ae, nil, nil); e != nil {
		logError("OnAuditStoreEventHeadsup: POST headsup for dev=%v reqId=%v | %v => %v", ae.MacAddr, rid.String(), ae.ChangeRequest, e)
	} else {
		logDebug("OnAuditStoreEventHeadsup: POST headsup %vms OK for %v | reqId=%v", time.Since(st).Milliseconds(), ae.MacAddr, rid.String())
	}
}

func (dsh DeviceServiceHandler) OnAuditStoreEventConnectionMethod(ae *AuditStoredEvent) {
	ctx := context.Background()
	if ae == nil || ae.PrevFwInfo.Reason == nil || *ae.PrevFwInfo.Reason != PROPERTY_REASON_CONNECTED {
		return
	}

	hu := CreateHttpUtil(token, nil)
	uri := fmt.Sprintf("%v/api/v2/devices/connection?macAddress=%v", FloApiUrl, ae.MacAddr)
	if rid, e := hu.Do(ctx, "POST", uri, SetConnectionMethodModel{Method: SetConnectionMethod_Unknown}, nil, nil); e != nil {
		logError("OnAuditStoreEventConnectionMethod: POST connection for dev=%v reqId=%v | %v => %v", ae.MacAddr, rid.String(), ae.ChangeRequest, e)
	}
}

func (ae *AuditStoredEvent) hasChange(wl map[string]int) bool {
	if ae.ChangeRequest != nil && len(ae.ChangeRequest.FwProps) != 0 {
		if ae.PrevFwInfo == nil || ae.PrevFwInfo.Properties == nil || len(*ae.PrevFwInfo.Properties) == 0 {
			return false
		}
		ogMap := *ae.PrevFwInfo.Properties
		for k, v := range ae.ChangeRequest.FwProps {
			if _, ok := wl[k]; !ok {
				continue //none important fields
			} else if ogVal, ok := ogMap[k]; ok {
				chStr, ogStr := fmt.Sprint(v), fmt.Sprint(ogVal)
				if chStr != ogStr {
					logTrace("hasChange: TRUE for dev=%v | req=%v og=%v", ae.MacAddr, chStr, ogStr)
					return true //relying on golang native stringify, should be ok, JSON if this fails
				}
			} else {
				logTrace("hasChange: TRUE for dev=%v | req=%v og=<missing>", ae.MacAddr, v)
				return true //something is not found in the og fw
			}
		}
	}
	return false
}

// TailDeviceIds godoc
// @Summary Fetch all DeviceSummary in batches
// @Description get DeviceSummary
// @Tags devices
// @Accept  json
// @Produce  json
// @Param limit query integer false "max items returned per batch, default is 100, cap is 500"
// @Param id query string false "the head or starting device id, default is blank (db head)"
// @Success 200 {object} TailDeviceResp
// @Failure 500 {object} ErrorResponse "failed to retrieve devices ids for whatever reason"
// @Router /device-summary/tail [get]
func (dsh DeviceServiceHandler) TailDeviceSummaryHandler(c echo.Context) error {
	ctx := c.Request().Context()
	req := TailDeviceReq{}
	if e := c.Bind(&req); e != nil {
		return c.JSON(400, ErrorResponse{
			StatusCode: 400,
			Message:    "Can't Parse QueryString: " + e.Error(),
		})
	}
	if req.DeviceId != "" && !isValidDeviceMac(req.DeviceId) {
		return c.JSON(400, ErrorResponse{
			StatusCode: 400,
			Message:    "Bad deviceId",
		})
	} else if res, e := dsh.SqlRepo.TailDeviceSummary(ctx, req.Normalize()); e != nil {
		return c.JSON(500, ErrorResponse{
			StatusCode: 500,
			Message:    "Can't tail device summary",
		})
	} else {
		return c.JSON(200, res)
	}
}

// ListDevices godoc
// @Summary List devices
// @Description get devices
// @Tags devices
// @Accept  json
// @Produce  json
// @Param limit query integer false "the limit parameter controls the maximum number of items that may be returned for a single request, default as well as max value is 10"
// @Param offset query integer false "the offset parameter controls the starting point within the collection of resource results, default values is 0"
// @Success 200 {array} Devices
// @Failure 400 {object} ErrorResponse "parameter limit has to be a number" "parameter offset has to be a number"
// @Failure 500 {object} ErrorResponse "failed to retrieve devices records with offset 0 and limit 10"
// @Router /devices [get]
func (dsh DeviceServiceHandler) ListDevicesHandler(c echo.Context) error {
	ctx := c.Request().Context()
	var err error
	var limit int
	var offset int

	offsetStr := c.QueryParam(offsetParam)
	if offsetStr == EmptyString {
		offset = defaultOffset
	} else {
		offset, err = strconv.Atoi(offsetStr)
		if err != nil {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				StatusCode: http.StatusBadRequest,
				Message:    fmt.Sprintf("parameter %s has to be a number", offsetParam),
			})
		}
	}

	limitStr := c.QueryParam(limitParam)
	if limitStr == EmptyString {
		limit = defaultLimit
	} else {
		limit, err = strconv.Atoi(limitStr)
		if err != nil {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				StatusCode: http.StatusBadRequest,
				Message:    fmt.Sprintf("parameter %s has to be a number", limitParam),
			})
		}
	}

	if limit > defaultLimit {
		limit = defaultLimit
	}

	pairMobile, err := boolPtr(c.QueryParam(mobileParam))
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    fmt.Sprintf("parameter %s has to be boolean", mobileParam),
		})
	}

	devices, err := dsh.SqlRepo.GetDevices(ctx, offset, limit, pairMobile)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    fmt.Sprintf("failed to retrieve devices records with offset %s and limit %s", offsetStr, limitStr),
		})
	}

	return c.JSON(http.StatusOK, devices)
}

// GetDevices godoc
// @Summary Get devices
// @Description get devices by id
// @Tags devices
// @Accept  json
// @Produce  json
// @Param device body DeviceIds true "Device IDs"
// @Success 200 {array} Devices
// @Failure 400 {object} ErrorResponse "invalid device ids"
// @Failure 500 {object} ErrorResponse "failed to retrieve devices records"
// @Router /devices/_get [post]
func (dsh DeviceServiceHandler) GetDevicesHandler(c echo.Context) error {
	ctx := c.Request().Context()
	var getDevicesBody GetDevicesBody

	err := c.Bind(&getDevicesBody)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    err.Error(),
		})
	}

	devices, err := dsh.SqlRepo.GetDevicesById(ctx, getDevicesBody.DeviceIds)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    fmt.Sprintf("failed to retrieve devices"),
		})
	}

	return c.JSON(http.StatusOK, devices)
}

func (dsh *DeviceServiceHandler) parseDeviceId(c echo.Context) (string, *ErrorResponse) {
	deviceId := c.Param(requestDeviceIdKey)
	if deviceId == EmptyString {
		return "", &ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    fmt.Sprintf("parameter %s can not be empty", requestDeviceIdKey),
		}
	}
	if !isValidDeviceMac(deviceId) {
		return "", &ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    fmt.Sprintf(errMsgDeviceIdBadRequest, requestDeviceIdKey),
		}
	}
	return deviceId, nil
}

// GetDevice godoc
// @Summary get device state by id
// @Description get device by id (device mac address), device state includes itself: isConnected flag, providing the
// @Description knowledge about the device online state (connected or disconnected from the network), firmware properties
// @Description passed from the device (the list of the properties is lengthy and is still growing), keep in mind that
// @Description there is no validation on the firmware properties in the device service (it takes the data as is from the device)
// @Description system mode, valve state and telemetry
// @Tags devices
// @Accept  json
// @Produce  json
// @Param id path string true "device id"
// @Success 200 {array} DeviceExtended
// @Failure 400 {object} ErrorResponse "path parameter id can not be empty"
// @Failure 404 {object} ErrorResponse "deviceId_f045da2cc1ed doesn't exist"
// @Failure 500 {object} ErrorResponse "failed to retrieve record for deviceId_000005f0cccc from the datastore"
// @Router /devices/{id} [get]
func (dsh *DeviceServiceHandler) GetDeviceHandler(c echo.Context) error {
	ctx := c.Request().Context()
	deviceId, er := dsh.parseDeviceId(c)
	if er != nil {
		return c.JSON(er.StatusCode, er)
	}

	deviceExtended := DeviceExtended{}
	realTimeDeviceData := DeviceRealTime{}

	// get device real time data, first try redis - if failure, try Firestore
	deviceCachedData, err := dsh.Cache.GetDeviceCachedData(ctx, deviceId)
	if err == nil && deviceCachedData != nil && len(deviceCachedData) != 0 {
		realTimeDeviceData, err = ToRealTimeData(deviceCachedData)
	} else {
		log.Warnf("failed to get cached device data from redis for deviceId_%s, err: %v", deviceId, err)
		// get device real time data from Firestore
		status, realTimeDeviceDataMap, err := GetDeviceRealTimeData(ctx, deviceId)
		if err != nil {
			log.Errorf("failed to get device real time data for deviceId_%s %v", deviceId, err)
		}
		if !status {
			log.Errorf("failed to get device real time data for deviceId_%s", deviceId)
		}
		realTimeDeviceData, err = convertRealTimeDataMapToStruct(realTimeDeviceDataMap)
		if err != nil {
			log.Errorf("failed to convert realTimeDeviceData map to realTimeDeviceData struct for deviceId_%s %v", deviceId, err)
		}
	}

	if &realTimeDeviceData != nil {
		if realTimeDeviceData.DeviceId != deviceId {
			log.Warnf("real time data deviceId_%s does not match queried deviceId_%s", realTimeDeviceData.DeviceId, deviceId)
		}
		// get telemetry data from Firestore, it's going to be replaced with a call to redis
		telemetryFinal := make(map[string]interface{})
		if realTimeDeviceData.Telemetry != nil {
			telemetryFinal = realTimeDeviceData.Telemetry
		}
		deviceExtended.Telemetry = telemetryFinal
		// get valve state data from Firestore, it's going to be replaced with a call to redis
		valveStateFinal := map[string]interface{}{
			"lastKnown": "unknown",
		}
		if realTimeDeviceData.ValveState != nil && len(realTimeDeviceData.ValveState) != 0 {
			valveStateFinal = realTimeDeviceData.ValveState
		}
		deviceExtended.ValveState = valveStateFinal
		if redisLastKnown, ok := deviceCachedData["valve.lastKnown"]; ok {
			if redisLastKnown != unknownKey {
				deviceExtended.ValveState["lastKnown"] = redisLastKnown
			}
		}

		// get system mode data from Firestore, it's going to be replaced with a call to redis
		systemModeFinal := map[string]interface{}{
			"lastKnown": "unknown",
		}
		if realTimeDeviceData.SystemMode != nil {
			systemModeFinal = realTimeDeviceData.SystemMode
		}
		deviceExtended.SystemMode = systemModeFinal
		if redisLastKnown, ok := deviceCachedData["systemMode.lastKnown"]; ok {
			if redisLastKnown != unknownKey {
				deviceExtended.SystemMode["lastKnown"] = redisLastKnown
			}
		}
	}

	// get the base device state from Postgres
	deviceBase, err := dsh.SqlRepo.GetDevice(ctx, deviceId)
	if err != nil {
		doesntExist := fmt.Sprintf(NoSuchDeviceErrorMsg, deviceId)
		if err.Error() == doesntExist {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				StatusCode: http.StatusNotFound,
				Message:    doesntExist,
			})
		}
		log.Errorf("failed to retrieve device %s: %v", deviceId, err)
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    fmt.Sprintf("failed to retrieve record for deviceId_%s from the datastore", deviceId),
		})
	}

	if isDevicePuck(deviceBase) {
		deviceExtended.Telemetry = map[string]interface{}{
			"current": map[string]interface{}{
				"humidity": (*deviceBase.FwProperties)["telemetry_humidity"],
				"tempF":    (*deviceBase.FwProperties)["telemetry_temperature"],
				"updated":  *deviceBase.LastHeardFrom,
			},
		}
	}

	deviceExtended.DeviceBase = deviceBase

	// aggregate connectivity data from both data sources, Postgres and real time data
	connectivityFinal := make(map[string]interface{})
	if realTimeDeviceData.Connectivity != nil {
		connectivityFinal = realTimeDeviceData.Connectivity
	}

	ssid := EmptyString
	if deviceBase.FwProperties != nil {
		ssidI := (*deviceBase.FwProperties)[FwWifiSsidKey]
		if ssidI != nil {
			ssid = ssidI.(string)
		}
	}
	connectivityFinal[ssidKey] = ssid
	deviceExtended.Connectivity = connectivityFinal

	// Use the Redis Last Update Date if available ( redis updates every min, db every 5 min )
	if len(deviceCachedData) > 0 {
		t, e := time.Parse(time.RFC3339, deviceCachedData["hb.lastHeardFrom"])

		if e == nil && t.Year() > 2000 && t.Year() < 2100 {
			deviceExtended.LastHeardFrom = &t
		}
	}

	return c.JSON(http.StatusOK, getFilteredProperties(deviceExtended, c.QueryParam("fields")))
}

// DeviceSyncHandler godoc
// @Summary forces the device to sync
// @Description forces the device to sync with the backend services, providing the latest data for for System Mode,
// @Description Valve State, Firmware Properties
// @Tags devices
// @Accept  json
// @Produce  json
// @Param id path string true "device id"
// @Success 202
// @Failure 400 {object} ErrorResponse "path parameter id can not be empty"
// @Failure 404 {object} ErrorResponse "deviceId_f045da2cc1ed doesn't exist"
// @Failure 500 {object} ErrorResponse
// @Router /devices/{id}/sync [post]
func (dsh *DeviceServiceHandler) DeviceSyncHandler(c echo.Context) error {
	ctx := c.Request().Context()
	sp := MakeSpanInternal(ctx, "DeviceSyncHandler")
	defer sp.Finish()

	// parameter validation
	deviceId, er := dsh.parseDeviceId(c)
	if er != nil {
		sp.SetTag(string(ext.Error), er.Error())
		return c.JSON(er.StatusCode, er)
	}

	force := c.QueryParam("force")

	// Fix for fw issue (ver >6) not setting correctly flodetect properties
	go ReconcileFwProps(ctx, dsh.SqlRepo, deviceId)

	if verifySystemMode(ctx, deviceId, "DeviceSyncHandler", strings.EqualFold(force, "true")) {
		go _recon.MarkSynced(ctx, deviceId)
	}

	// Send a request for properties after a second
	go func(mac string) {
		time.Sleep(time.Second)
		PublishToFwPropsMqttTopic(ctx, mac, QOS_1, nil, "get")
	}(deviceId)

	return c.NoContent(http.StatusAccepted)
}

func convertRealTimeDataMapToStruct(data map[string]interface{}) (DeviceRealTime, error) {

	realTimeDeviceData := DeviceRealTime{}

	deviceIdFromFs := "unknown"
	deviceIdFromFsI, ok := data[deviceIdKey]
	if !ok {
		return realTimeDeviceData, fmt.Errorf(failedToGetRealTimeDataErrMsg, deviceIdKey, "none")
	}
	if deviceIdFromFsI != nil {
		deviceIdFromFs = deviceIdFromFsI.(string)
		realTimeDeviceData.DeviceId = deviceIdFromFs
	}

	var telemetry map[string]interface{}
	telemetryI, ok := data[telemetryKey]
	if ok && telemetryI != nil {
		telemetry = telemetryI.(map[string]interface{})
		realTimeDeviceData.Telemetry = telemetry
	}

	var connectivity map[string]interface{}
	connectivityI, ok := data[connectivityKey]
	if ok && connectivityI != nil {
		connectivity = connectivityI.(map[string]interface{})
		realTimeDeviceData.Connectivity = connectivity
	}

	var valveState map[string]interface{}
	valveStateI, ok := data[valveKey]
	if ok && valveStateI != nil {
		valveState = valveStateI.(map[string]interface{})
		realTimeDeviceData.ValveState = valveState
	}

	var systemMode map[string]interface{}
	systemModeI, ok := data[systemModeKey]
	if ok && systemModeI != nil {
		systemMode = systemModeI.(map[string]interface{})
		realTimeDeviceData.SystemMode = systemMode
	}

	return realTimeDeviceData, nil

}

// DeleteDevice godoc
// @Summary delete device by id
// @Description delete device
// @Tags devices
// @Accept  json
// @Produce  json
// @Param id path int true "DeviceBase Id"
// @Success 204 {array} DeviceBase
// @Failure 400 {object} ErrorResponse "parameter id can not be empty"
// @Failure 404 {object} ErrorResponse "deviceId_f045da2cc1ed doesn't exist"
// @Failure 500 {object} ErrorResponse "failed to delete device props from the SQL datastore" "failed to delete device props from the NOSQL datastore"
// @Router /devices/{id} [delete]
func (dsh *DeviceServiceHandler) DeleteDeviceHandler(c echo.Context) error {
	ctx := c.Request().Context()
	deviceId, er := dsh.parseDeviceId(c)
	if er != nil {
		return c.JSON(er.StatusCode, er)
	}

	err := dsh.SqlRepo.DeleteDevice(deviceId)
	if err != nil {
		doesntExist := fmt.Sprintf(NoSuchDeviceErrorMsg, deviceId)
		if err.Error() == doesntExist {
			return c.JSON(http.StatusNotFound, ErrorResponse{
				StatusCode: http.StatusNotFound,
				Message:    fmt.Sprintf("%s in Postgres", doesntExist),
			})
		}
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    fmt.Sprintf(errMsgFailedToDeleteDeviceProps, deviceId, "Postgres"),
		})
	} else {
		// see NOTE 1

		// cleanup redis cache
		deviceConnectivityKey := dsh.Cache.GetDeviceConnectivityKey(deviceId)
		deviceCacheKey := dsh.Cache.GetDeviceCacheKey(deviceId)
		// TODO consider recreating presence keys
		//presentDevices := dsh.Cache.GetDevicePresenceKeys()
		//devicesPsesenceKeys :=  dsh.Cache.GetDevicePresenceKeys(deviceId)
		keysToRemove := []string{deviceConnectivityKey, deviceCacheKey}
		_, err := dsh.Cache.DeleteKeys(ctx, keysToRemove)
		if err != nil {
			log.Errorf("failed to remove %v keys from redis", keysToRemove)
		}

		status, err := DeleteDeviceRealTimeData(ctx, deviceId)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				StatusCode: http.StatusInternalServerError,
				Message:    fmt.Sprintf(errMsgFailedToDeleteDeviceProps, deviceId, "Firestore"),
			})
		}
		if status == http.StatusNoContent {
			return c.NoContent(http.StatusNoContent)
		} else {
			return c.JSON(status, ErrorResponse{
				StatusCode: status,
				Message:    fmt.Sprintf(errMsgFailedToDeleteDeviceProps, deviceId, "Firestore"),
			})
		}
	}
}

// CreateDevice godoc
// @Summary Creates device and device stub
// @Description Creates device and device stub
// @Tags devices
// @Accept  json
// @Produce  json
// @Param id path int true "Device Id"
// @Param device body DeviceBase true "Device Base"
// @Router /devices/{id} [post]
func (dsh *DeviceServiceHandler) UpsertDeviceHandler(c echo.Context) error {
	ctx := c.Request().Context()
	macAddress, er := dsh.parseDeviceId(c)
	if er != nil {
		return c.JSON(er.StatusCode, er)
	}

	var device DeviceBase
	err := c.Bind(&device)
	if err != nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    err.Error(),
		})
	}

	status, err := CreateDeviceStub(ctx, macAddress)
	if err != nil {
		log.Errorf("failed to create device stub with id %s: %s", macAddress, err.Error())
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    SomethingWentWrongErrMsg,
		})
	}
	status2xx := status >= 200 && status < 300
	if !status2xx {
		log.Errorf("failed to create device stub with id %s", macAddress)
		return c.JSON(status, ErrorResponse{
			StatusCode: status,
			Message:    SomethingWentWrongErrMsg,
		})
	}

	device.DeviceId = &macAddress
	deviceInternal := device.MapDeviceToDeviceInternal()

	convertHwThresholds(&deviceInternal)
	err = dsh.SqlRepo.UpsertDevice(ctx, deviceInternal)

	if err != nil {
		log.Errorf("failed to upsert device with id : %s", macAddress, err.Error())
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    SomethingWentWrongErrMsg,
		})
	}

	return c.NoContent(http.StatusNoContent)
}

func convertHwThresholds(device *DeviceInternal) {
	if device.HardwareThresholds != nil {
		if device.HardwareThresholds.TempF != nil {
			if device.HardwareThresholds.TempC == nil {
				device.HardwareThresholds.TempC = new(ThresholdDefinition)
			}

			if device.HardwareThresholds.TempF.OkMin != nil && device.HardwareThresholds.TempC.OkMin == nil {
				okMinC := fahrenheitToCelsius(*device.HardwareThresholds.TempF.OkMin)
				device.HardwareThresholds.TempC.OkMin = &okMinC
			}

			if device.HardwareThresholds.TempF.OkMax != nil && device.HardwareThresholds.TempC.OkMax == nil {
				okMaxC := fahrenheitToCelsius(*device.HardwareThresholds.TempF.OkMax)
				device.HardwareThresholds.TempC.OkMax = &okMaxC
			}

			if device.HardwareThresholds.TempF.MinValue != nil && device.HardwareThresholds.TempC.MinValue == nil {
				minValueC := fahrenheitToCelsius(*device.HardwareThresholds.TempF.MinValue)
				device.HardwareThresholds.TempC.MinValue = &minValueC
			}

			if device.HardwareThresholds.TempF.MaxValue != nil && device.HardwareThresholds.TempC.MaxValue == nil {
				maxValueC := fahrenheitToCelsius(*device.HardwareThresholds.TempF.MaxValue)
				device.HardwareThresholds.TempC.MaxValue = &maxValueC
			}
		}

		if device.HardwareThresholds.TempC != nil {
			if device.HardwareThresholds.TempF == nil {
				device.HardwareThresholds.TempF = new(ThresholdDefinition)
			}

			if device.HardwareThresholds.TempC.OkMin != nil && device.HardwareThresholds.TempF.OkMin == nil {
				okMinF := celsiusToFahrenheit(*device.HardwareThresholds.TempC.OkMin)
				device.HardwareThresholds.TempF.OkMin = &okMinF
			}

			if device.HardwareThresholds.TempC.OkMax != nil && device.HardwareThresholds.TempF.OkMax == nil {
				okMaxF := celsiusToFahrenheit(*device.HardwareThresholds.TempC.OkMax)
				device.HardwareThresholds.TempF.OkMax = &okMaxF
			}

			if device.HardwareThresholds.TempC.MinValue != nil && device.HardwareThresholds.TempF.MinValue == nil {
				minValueF := celsiusToFahrenheit(*device.HardwareThresholds.TempC.MinValue)
				device.HardwareThresholds.TempF.MinValue = &minValueF
			}

			if device.HardwareThresholds.TempC.MaxValue != nil && device.HardwareThresholds.TempF.MaxValue == nil {
				maxValueF := celsiusToFahrenheit(*device.HardwareThresholds.TempC.MaxValue)
				device.HardwareThresholds.TempF.MaxValue = &maxValueF
			}
		}
	}
}

func fahrenheitToCelsius(f float64) float64 {
	return (f - 32.0) * 5.0 / 9.0
}

func celsiusToFahrenheit(c float64) float64 {
	return (c * 9.0 / 5.0) + 32.0
}
