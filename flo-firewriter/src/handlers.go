package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/labstack/echo/v4"
)

const splitter = "-"
const errMsgJsonBodyIsEmpty = "json body is empty"
const errMsgFailedToBind = "failed to bind request body with %s map"
const locationsCollectionDefault = "locations"
const locationIdKey = "locationId"
const usersCollectionDefault = "users"
const userIdKey = "userId"
const errMsgDeviceIdBadRequest = "deviceId value has to be 12 characters long containing alphanumeric characters restricted to a-f or A-F letters, provided %s"
const devicesCollectionDefault = "devices"
const deviceIdKey = "deviceId"

// Fwh is the global variable for Device Service Handler
var Fwh FireWriterHandler
var devicesCollection string
var usersCollection string
var locationsCollection string

type GenericMap map[string]interface{}

type FireWriterHandler struct {
	kafkaConnection *KafkaConnection
	FirestoreRepo   *FsWriterRepo
}

func SetCollectionName(collections []string, defaultCollection string) string {
	result := defaultCollection
	for _, c := range collections {
		cSplit := strings.Split(c, splitter)
		if cSplit[0] == defaultCollection {
			result = c
		}
	}
	logDebug("collection to be used is %s, defaultCollection is %s", result, defaultCollection)
	return result
}

func InitHttpRequestsHandlers(kafkaConnection *KafkaConnection, repo *FsWriterRepo) {

	devicesCollection = SetCollectionName(KnownFsCollections, devicesCollectionDefault)
	usersCollection = SetCollectionName(KnownFsCollections, usersCollectionDefault)
	locationsCollection = SetCollectionName(KnownFsCollections, locationsCollectionDefault)

	Fwh = FireWriterHandler{
		kafkaConnection: kafkaConnection,
		FirestoreRepo:   repo,
	}
}

// PingHandler godoc
// @Summary checks the health status of the service and list its config data
// @Description checks the health status of the service and list its config data
// @Tags service
// @Accept  json
// @Produce  json
// @Success 200 {array} Ping
// @Failure 500 {object} ErrorResponse
// @Router /ping [get]
func PingHandler(c echo.Context) (err error) {

	numOfGoroutines := runtime.NumGoroutine()

	epochInt := 0
	if BuildDate != NoneValue {
		epochInt, err = strconv.Atoi(BuildDate)
		if err != nil {
			logError("failed to convert epoch string %s to int", BuildDate)
			epochInt = 0
		}
	}

	return c.JSON(http.StatusOK, Ping{
		Status:      http.StatusOK,
		Service:     ServiceName,
		CommitName:  CommitName,
		CommitSHA:   CommitSHA,
		BuildDate:   time.Unix(int64(epochInt), 0).Truncate(time.Second).Format(time.RFC3339),
		Environment: Env,
		Timestamp:   time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		Stats: map[string]interface{}{
			"numOfGoroutines": numOfGoroutines,
		},
	})
}

// StatsHandler godoc
// @Summary gets writes stats from the firewriter
// @Description gets writes stats from the firewriter
// @Tags service
// @Produce  json
// @Success 200 {array} GenericMap
// @Router /v1/stats [get]
func (fwh *FireWriterHandler) StatsHandler(c echo.Context) (err error) {

	statsChanChan := GetStatsChanChan()

	statsCh := make(chan map[string]Stats, 1)

	statsChanChan <- statsCh

	stats := <-statsCh

	return c.JSON(http.StatusOK, map[string]interface{}{
		"writesStats": stats,
	})

}

// UsersWriterHandler godoc
// @Summary users data to firestore
// @Description users data to firestore
// @Tags users
// @Accept  json
// @Param userId path string true "userId"
// @Param sync query string false "blocking call if sync=true"
// @Success 200
// @Success 202
// @Failure 400 {object} ErrorResponse "failed to bind request body with user map"
// @Failure 500 {object} ErrorResponse "failed to write userId_08d3cec0-09ba-49ff-83ec-9ce0c9f0658b doc to firestore user collection, err: <error>"
// @Failure 500 {object} ErrorResponse "failed to marshal userData map for userId_08d3cec0-09ba-49ff-83ec-9ce0c9f0658b"
// @Router /v1/firestore/users/{userId} [post]
func (fwh *FireWriterHandler) UsersWriterHandler(c echo.Context) (err error) {
	sp := MakeSpanInternal(c.Request().Context(), "UsersWriterHandler")
	defer sp.Finish()

	if c.Request().Body == nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    errMsgJsonBodyIsEmpty,
		})
	}

	userData := make(map[string]interface{})
	err = c.Bind(&userData)
	if err != nil {
		errMsg := fmt.Sprintf(errMsgFailedToBind, "user")
		if strings.Contains(err.Error(), "empty") {
			errMsg = errMsgJsonBodyIsEmpty
		}
		logError("%s, err: %v", errMsg, err)
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    errMsg,
		})
	}

	userId := c.Param(userIdKey)
	sync := c.QueryParam("sync")
	if sync != EmptyString {
		inputData := map[string]map[string]interface{}{
			userId: userData,
		}
		err := fwh.FirestoreRepo.UpsertIndividual(usersCollection, inputData)
		if err != nil {
			errMsg := fmt.Sprintf("failed to wtite userId_%s doc to firestore %s collection, err: %v",
				userId, usersCollection, err)
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				StatusCode: http.StatusInternalServerError,
				Message:    errMsg,
			})
		}
		return c.NoContent(http.StatusOK)

	} else {
		// NOTE: if you wonder why we push to kafka topic and consume from the same topic:
		// it may look jenky, but it works, taking advantage of kafka partitioning to distribute writes across
		// flo-firewriter instances (pods) with affinity of the user to the kafka partition, 6 kafka partitions ->
		// 6 service instances (to assure affinity we use userId as a kafka message key,
		// e.g 08d3cec0-09ba-49ff-83ec-9ce0c9f0658b will be picked up by partition 3, or partition 2, it's just an example)

		userData[CollectionKey] = usersCollection

		var jsonBytes []byte
		jsonBytes, err = json.Marshal(userData)
		if err != nil {
			errMsg := fmt.Sprintf("failed to marshal userData map for userId_%s", userId)
			logError(errMsg)
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				StatusCode: http.StatusInternalServerError,
				Message:    errMsg,
			})
		}

		err = fwh.kafkaConnection.PublishBytes(KafkaFirestoreWriterTopic, jsonBytes, []byte(userId))
		if err != nil {
			logError("failed to publish %s to %s topic", string(jsonBytes), KafkaFirestoreWriterTopic)
			// TODO: We should not exit, we should re-connect. But, system works, so lets not refactor. - AlexZ
			time.Sleep(time.Second * 3)
			os.Exit(-86)
		}

		return c.NoContent(http.StatusAccepted)
	}
}

// LocationsWriterHandler godoc
// @Summary writes locations data to firestore
// @Description writes locations data to firestore
// @Tags locations
// @Accept  json
// @Param locationId path string true "locationId"
// @Param sync query string false "blocking call if sync=true"
// @Success 200 {array} GenericMap
// @Failure 400 {object} ErrorResponse "failed to bind request body with location map"
// @Failure 500 {object} ErrorResponse "failed to write locationId_07d3cec0-09aa-49ef-83ec-9ce0c9f0658a doc to firestore location collection, err: <error>"
// @Failure 500 {object} ErrorResponse "failed to marshal locationData map for userId_07d3cec0-09aa-49ef-83ec-9ce0c9f0658a"
// @Router /v1/firestore/locations/{locationId} [post]
func (fwh *FireWriterHandler) LocationsWriterHandler(c echo.Context) (err error) {
	sp := MakeSpanInternal(c.Request().Context(), "LocationsWriterHandler")
	defer sp.Finish()

	if c.Request().Body == nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    errMsgJsonBodyIsEmpty,
		})
	}

	locationData := make(map[string]interface{})
	err = c.Bind(&locationData)
	if err != nil {
		errMsg := fmt.Sprintf(errMsgFailedToBind, "location")
		if strings.Contains(err.Error(), "empty") {
			errMsg = errMsgJsonBodyIsEmpty
		}
		logError("%s, err: %v", errMsg, err)
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    errMsg,
		})
	}

	locationId := c.Param(locationIdKey)
	sync := c.QueryParam("sync")
	if sync != EmptyString {
		inputData := map[string]map[string]interface{}{
			locationId: locationData,
		}
		err := fwh.FirestoreRepo.UpsertIndividual(locationsCollection, inputData)
		if err != nil {
			errMsg := fmt.Sprintf("failed to wtite locationId_%s doc to firestore %s collection, err: %v",
				locationId, locationsCollection, err)
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				StatusCode: http.StatusInternalServerError,
				Message:    errMsg,
			})
		}
		return c.NoContent(http.StatusOK)

	} else {
		// NOTE: if you wonder why we push to kafka topic and consume from the same topic:
		// it may look jenky, but it works, taking advantage of kafka partitioning to distribute writes across
		// flo-firewriter instances (pods) with affinity of the location to the kafka partition, 6 kafka partitions ->
		// 6 service instances (to assure affinity we use locationId as a kafka message key,
		// e.g 07d3cec0-09aa-49ef-83ec-9ce0c9f0658a will be picked up by partition 3, or partition 2, it's just an example)

		locationData[CollectionKey] = locationsCollection

		var jsonBytes []byte
		jsonBytes, err = json.Marshal(locationData)
		if err != nil {
			errMsg := fmt.Sprintf("failed to marshal locationData map for locationId %s", locationId)
			logError(errMsg)
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				StatusCode: http.StatusInternalServerError,
				Message:    errMsg,
			})
		}

		err = fwh.kafkaConnection.PublishBytes(KafkaFirestoreWriterTopic, jsonBytes, []byte(locationId))
		if err != nil {
			logError("failed to publish %s to %s topic", string(jsonBytes), KafkaFirestoreWriterTopic)
			// TODO: We should not exit, we should re-connect. But, system works, so lets not refactor. - AlexZ
			time.Sleep(time.Second * 3)
			os.Exit(-86)
		}

		return c.NoContent(http.StatusAccepted)
	}
}

// DevicesWriterPostHandler godoc
// @Summary writes real time device data to firestore
// @Description writes real time device data to firestore
// @Tags devices
// @Accept  json
// @Param deviceId path string true "Device MAC Address"
// @Param sync query string false "If string is 'true', will block until firestore commits data"
// @Success 200
// @Success 202
// @Failure 400 {object} ErrorResponse "deviceId value has to be 12 characters long containing alphanumeric characters restricted to a-f or A-F letters, provided f045da2cc1edddddd"
// @Failure 400 {object} ErrorResponse "deviceId is missing in json body"
// @Failure 400 {object} ErrorResponse "deviceId mismatch: query param deviceId: f045da2cc1ed, deviceId provided in json body: 1145de3cc1e1"
// @Failure 400 {object} ErrorResponse "failed to bind request body with device map"
// @Failure 500 {object} ErrorResponse "failed to write deviceId_f045da2cc1ed doc to firestore devices collection, err: <error>"
// @Failure 500 {object} ErrorResponse "failed to marshal deviceData map for deviceId f045da2cc1ed"
// @Router /v1/firestore/devices/{deviceId} [post]
func (fwh *FireWriterHandler) DevicesWriterPostHandler(c echo.Context) (err error) {
	sp := MakeSpanInternal(c.Request().Context(), "DevicesWriterPostHandler")
	defer sp.Finish()

	deviceId := c.Param(deviceIdKey)

	if !isValidDeviceId(deviceId) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    fmt.Sprintf(errMsgDeviceIdBadRequest, deviceId),
		})
	}

	if c.Request().Body == nil {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    errMsgJsonBodyIsEmpty,
		})
	}

	deviceData := make(map[string]interface{})
	err = c.Bind(&deviceData)
	if err != nil {
		errMsg := fmt.Sprintf(errMsgFailedToBind, "device")
		if strings.Contains(err.Error(), "empty") {
			errMsg = errMsgJsonBodyIsEmpty
		}
		logError("%s, err: %v", errMsg, err)
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    errMsg,
		})
	}

	// NOTE: on 08.15.19 decision has been made to accept data as is with no validation for the exception of the deviceId
	deviceIdFromJsonBody, ok := deviceData[deviceIdKey]
	if !ok {
		errMsg := "deviceId is missing in json body"
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    errMsg,
		})
	}

	if deviceId != deviceIdFromJsonBody {
		errMsg := fmt.Sprintf("deviceId mismatch: query param deviceId: %s, deviceId provided in json body: %s",
			deviceId, deviceIdFromJsonBody)
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    errMsg,
		})
	}

	// Set the date of received data for storage
	deviceData["_latestWrite"] = time.Now().UTC().Truncate(time.Second).Format(time.RFC3339)

	sync := c.QueryParam("sync")

	if sync != EmptyString {
		inputData := map[string]map[string]interface{}{
			deviceId: deviceData,
		}
		err := fwh.FirestoreRepo.UpsertIndividual(devicesCollection, inputData)
		if err != nil {
			errMsg := fmt.Sprintf("failed to write deviceId_%s doc to firestore %s collection, err: %v",
				deviceId, devicesCollection, err)
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				StatusCode: http.StatusInternalServerError,
				Message:    errMsg,
			})
		} else {
			logInfo("DevicesWriterPostHandler: %v sync %v", deviceId, deviceData)
		}
		return c.NoContent(http.StatusOK)

	} else {
		deviceData[CollectionKey] = devicesCollection

		var jsonBytes []byte
		jsonBytes, err = json.Marshal(deviceData)
		if err != nil {
			errMsg := fmt.Sprintf("failed to marshal deviceData map for deviceId_%s", deviceId)
			logError(errMsg)
			return c.JSON(http.StatusInternalServerError, ErrorResponse{
				StatusCode: http.StatusInternalServerError,
				Message:    errMsg,
			})
		}

		err = fwh.kafkaConnection.PublishBytes(KafkaFirestoreWriterTopic, jsonBytes, []byte(deviceId))
		if err != nil {
			logError("DevicesWriterPostHandler: failed to publish %s to %s topic", string(jsonBytes), KafkaFirestoreWriterTopic)
			// TODO: We should not exit, we should re-connect. But, system works, so lets not refactor. - AlexZ
			time.Sleep(time.Second * 3)
			os.Exit(-86)
		} else {
			logInfo("DevicesWriterPostHandler: %v async %v", deviceId, deviceData)
		}

		return c.NoContent(http.StatusAccepted)
	}
}

// DevicesWriterDeleteHandler godoc
// @Summary deletes real time device data doc from firestore
// @Description deletes real time device data doc from firestore
// @Tags devices
// @Param deviceId path string true "Device MAC Address"
// @Success 204
// @Failure 400 {object} ErrorResponse "deviceId value has to be 12 characters long containing alphanumeric characters restricted to a-f or A-F letters, provided f045da2cc1edddddd"
// @Failure 500 {object} ErrorResponse "failed to delete deviceId_f045da2cc1ed doc from firestore devices collection, err: <error>"
// @Router /v1/firestore/devices/{deviceId} [delete]
func (fwh *FireWriterHandler) DevicesWriterDeleteHandler(c echo.Context) (err error) {
	sp := MakeSpanInternal(c.Request().Context(), "DevicesWriterDeleteHandler")
	defer sp.Finish()

	deviceId := c.Param(deviceIdKey)

	if !isValidDeviceId(deviceId) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    fmt.Sprintf(errMsgDeviceIdBadRequest, deviceId),
		})
	}

	status, err := fwh.FirestoreRepo.DeleteDoc(devicesCollection, deviceId)
	if err != nil && status == http.StatusInternalServerError {
		errMsg := fmt.Sprintf("failed to delete Id_%s document from collection %s: %v", deviceId, devicesCollection, err)
		logError(errMsg)
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    errMsg,
		})
	}

	if err != nil && status == http.StatusNotFound {
		return c.JSON(http.StatusNotFound, ErrorResponse{
			StatusCode: http.StatusNotFound,
			Message:    fmt.Sprintf("deviceId_%s not found", deviceId),
		})
	}

	return c.NoContent(http.StatusNoContent)
}

// DevicesWriterGetHandler godoc
// @Summary gets real time device data doc from firestore
// @Description dgets real time device data doc from firestore
// @Tags devices
// @Param deviceId path string true "Device MAC Address"
// @Produce json
// @Success 200 {object} main.GenericMap
// @Failure 400 {object} main.ErrorResponse "deviceId value has to be 12 characters long containing alphanumeric characters restricted to a-f or A-F letters, provided f045da2cc1edddddd"
// @Failure 500 {object} main.ErrorResponse "failed to get deviceId_f045da2cc1ed doc from firestore devices collection, err: <error>"
// @Router /v1/firestore/devices/{deviceId} [get]
func (fwh *FireWriterHandler) DevicesWriterGetHandler(c echo.Context) (err error) {
	sp := MakeSpanInternal(c.Request().Context(), "DevicesWriterGetHandler")
	defer sp.Finish()

	deviceId := c.Param(deviceIdKey)

	if !isValidDeviceId(deviceId) {
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    fmt.Sprintf(errMsgDeviceIdBadRequest, deviceId),
		})
	}

	data, status, err := fwh.FirestoreRepo.GetRealTimeData(devicesCollection, deviceId)

	if err != nil && status == http.StatusInternalServerError {
		errMsg := fmt.Sprintf("failed to get Id_%s document from collection %s: %v", deviceId, devicesCollection, err)
		logError(errMsg)
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    errMsg,
		})
	}

	if err != nil && status == http.StatusNotFound {
		return c.JSON(http.StatusNotFound, ErrorResponse{
			StatusCode: http.StatusNotFound,
			Message:    fmt.Sprintf("deviceId_%s not found", deviceId),
		})
	}

	return c.JSON(http.StatusOK, data)
}

func isValidDeviceId(deviceID string) bool {
	return DeviceIdRegex.MatchString(deviceID)
}

// GenerateCustomJwtHandler godoc
// @Summary generates custom JWT token to authenticate clients with Firestore
// @Description generates custom JWT token to authenticate clients with Firestore limiting access to specified asset ids
// @Description it is achieved by passing the ids of customer's asset such as devices in the request body which is going to be baked in as a custom claim "ids" into the jwt
// @Tags security
// @Accept  json
// @Produce  json
// @Param firestoreAuth body main.FirestoreAuth test "Input"
// @Success 200 {object} main.FirestoreToken
// @Failure 400 {object} main.ErrorResponse "parameter ids has to be a string" "parameter ids can not be empty"
// @Failure 500 {object} main.ErrorResponse "failed to generate firestore jwt"
// @Router /v1/firestore/auth [POST]
func (fwh *FireWriterHandler) GenerateCustomJwtHandler(c echo.Context) error {
	sp := MakeSpanInternal(c.Request().Context(), "GenerateCustomJwtHandler")
	defer sp.Finish()

	var err error

	bindErrorMsg := "failed to bind request body with FirestoreAuth struct"
	firestoreAuth := FirestoreAuth{
		Devices:   []string{},
		Locations: []string{},
		Users:     []string{},
	}

	err = c.Bind(&firestoreAuth)
	if err != nil {
		logError("%s, err: %v", bindErrorMsg, err)
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    bindErrorMsg,
		})
	}

	for _, deviceId := range firestoreAuth.Devices {
		if !isValidDeviceId(deviceId) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				StatusCode: http.StatusBadRequest,
				Message:    fmt.Sprintf(errMsgDeviceIdBadRequest, deviceId),
			})
		}
	}
	//TODO: we might have firestoreAuth.Pucks or such, the list of deviceIds (comma separated) might grow, change the way
	// deviceIds are assembled if expansion is needed

	deviceIds := strings.Join(firestoreAuth.Devices, ",")
	locationIds := strings.Join(firestoreAuth.Locations, ",")
	userIds := strings.Join(firestoreAuth.Users, ",")

	token, err := fwh.FirestoreRepo.GenerateFirestoreJwt(deviceIds, locationIds, userIds)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    fmt.Sprintf("failed to generate firestore jwt"),
		})
	}

	firestoreToken := FirestoreToken{
		Token: token,
	}

	return c.JSON(http.StatusOK, firestoreToken)
}
