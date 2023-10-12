package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/gorilla/mux"
	"net/http"
	"time"
)

type LearningModel struct {
	ExpiresAt          *time.Time
	Enabled            bool
}

type LearningApiModel struct {
	ExpiresAt          *string                    `json:"expiresOnOrAfter"`
	Enabled            *bool                      `json:"enabled"`
}

type FloSenseLearningApiModel struct {
	Learning           *LearningApiModel          `json:"learning"`
}

func validateLearningModel(apiModel *FloSenseLearningApiModel) (*LearningModel, error) {
	if apiModel.Learning == nil {
		return nil, errors.New("invalid parameters: missing learning object")
	}
	if apiModel.Learning.Enabled == nil {
		return nil, errors.New("invalid parameters: missing learning.enabled value")
	}

	model := new(LearningModel)
	model.Enabled = *apiModel.Learning.Enabled
	expiresAt, err := parseDate(apiModel.Learning.ExpiresAt)
	if err != nil {
		return nil, err
	}
	model.ExpiresAt = expiresAt
	if model.Enabled && model.ExpiresAt.Before(time.Now()) {
		return nil, errors.New("expiresOnOrAfter should be a date in the future")
	}
	return model, nil
}

func parseDate(dateAsString *string) (*time.Time, error) {
	if dateAsString == nil {
		defaultTime, _ := time.Parse("2006-01-02", "1970-01-01")
		return &defaultTime, nil
	} else {
		parsedDate := tryParseDate(*dateAsString)
		if parsedDate == nil {
			return nil, errors.New("unable to parse date: expiresOnOrAfter")
		}
		return parsedDate, nil
	}
}

func getLearningHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}

	floSenseData, err := getFloSenseFromDb(mac)
	if err != nil {
		httpError(w, 500, fmt.Sprintf("unable to get record for device %v", mac), err)
		return
	}

	learningResponse := make(map[string]interface{})
	if floSenseData != nil && floSenseData.ReLearningEnabled > 0 {
		expiresAtStr := floSenseData.ReLearningExpiresAt.Format(time.RFC3339)
		learningResponse["expiresOnOrAfter"] = expiresAtStr
		learningResponse["enabled"] = true
	} else {
		learningResponse["enabled"] = false
	}

	logDebug("getLearningHandler: fetching learning data for device %v", mac)
	httpWrite(w, 200, learningResponse)
}

func postLearningHandler(w http.ResponseWriter, r *http.Request) {
	mac := mux.Vars(r)["mac"]
	if !isValidMacAddress(mac) {
		httpError(w, 400, "invalid mac address", nil)
		return
	}
	body, err := httpReadBody(r)
	if err != nil {
		httpError(w, 400, "unable to read body", err)
		return
	}

	apiModel := new(FloSenseLearningApiModel)
	err = json.Unmarshal(body, apiModel)
	if err != nil {
		httpError(w, 400, "unable to deserialize json payload", err)
		return
	}

	model, err := validateLearningModel(apiModel)
	if err != nil {
		httpError(w, 400, err.Error(), nil)
		return
	}

	logTrace("postLearningHandler: %v %v", mac, *apiModel)

	if model.Enabled {
		err = enableLearningMode(mac, w, model)
	} else {
		err = cancelLearningMode(mac, w)
	}
	if err == nil {
		httpWrite(w, 202, apiModel)
	}
}

func enableLearningMode(mac string, w http.ResponseWriter, model *LearningModel) error {
	floSenseData, err := getOrCreateFromDb(mac)
	if err != nil {
		httpError(w, 500, fmt.Sprintf("unable to get record for device %v", mac), err)
		return err
	}

	// check if relearning is currently enabled
	if floSenseData != nil && floSenseData.ReLearningEnabled > 0 {
		message := fmt.Sprintf("device %v already in relearning mode", mac)
		httpError(w, 400, message, nil)
		return errors.New(message)
	}

	err = updateLearningData(mac, model.ExpiresAt, 1)
	if err != nil {
		httpError(w, 500, fmt.Sprintf("unable to re-enable learning mode for device %v", mac), err)
		return err
	}

	// Retrieve the device from api to get device id
	devInfo, err := getDeviceInfo(mac)
	if err != nil {
		message := fmt.Sprintf("postLearningHandler: error retrieving device from api. %v %v", mac, err.Error())
		logError(message)
		httpError(w, 500, message, err)
		return err
	}
	systemMode := SystemModeModel{
		IsLocked: true,
		Target: "sleep",
	}
	status, err := SetDeviceSystemMode(devInfo.Id, &systemMode)
	if status > 300 || err != nil {
		message := fmt.Sprintf("unable to change system mode for device %v", mac)
		httpError(w, 500, message, err)
		return errors.New(message)
	}

	logDebug("postLearningHandler: learning mode re-enabled for device %v", mac)
	return nil
}

func cancelLearningMode(mac string, w http.ResponseWriter) error {
	floSenseData, err := getFloSenseFromDb(mac)
	if err != nil {
		httpError(w, 500, fmt.Sprintf("unable to get record for device %v", mac), err)
		return err
	}
	if floSenseData == nil || floSenseData.ReLearningEnabled < 1 {
		message := fmt.Sprintf("device %v is not in relearning mode", mac)
		httpError(w, 400, message, nil)
		return errors.New(message)
	}

	defaultTime, _ := time.Parse("2006-01-02", "1970-01-01")
	err = updateLearningData(mac, &defaultTime, 0)
	if err != nil {
		httpError(w, 500, fmt.Sprintf("unable to cancel learning mode for device %v", mac), err)
		return err
	}

	err = restoreDeviceSystemMode(mac)
	if err != nil {
		httpError(w, 500, fmt.Sprintf("unable to cancel learning mode for device %v", mac), err)
		return err
	}

	logDebug("postLearningHandler: learning mode canceled for device %v", mac)
	return nil
}

func restoreDeviceSystemMode(macAddress string) error {
	// Retrieve the device from api to get device and location system mode values
	devInfo, err := getDeviceInfo(macAddress)
	if err != nil {
		logError("updateDeviceSystemMode: error retrieving device from api. %v %v", macAddress, err.Error())
		return err
	}

	if !devInfo.SystemMode.IsLocked {
		logDebug("updateDeviceSystemMode: device system mode not in locked sleep, skipping. %v %v", devInfo.MacAddress, devInfo.SystemMode)
		return nil
	}
	// Location system mode is missing/invalid, can't assume
	if len(devInfo.Location.SystemMode.Target) == 0 {
		logError("updateDeviceSystemMode: failed to set device system mode, location target empty. %v", devInfo.MacAddress)
		return nil
	}

	_, err = UnlockDeviceSystemMode(devInfo.Id)
	if err != nil {
		logWarn("updateDeviceSystemMode: failed to unlock device system mode. %v %v", devInfo.MacAddress, err.Error())
		return err
	}

	// Do not put a device to sleep, put it in home mode if location is in sleep
	target := devInfo.Location.SystemMode.Target
	if target == SYSTEM_MODE_SLEEP {
		target = SYSTEM_MODE_HOME
	}

	_, err = SetDeviceTargetSystemMode(devInfo.Id, target)
	if err != nil {
		logError("updateDeviceSystemMode: failed to set device system mode. %v %v %v", devInfo.MacAddress, devInfo.Location.SystemMode.Target, err.Error())
		return err
	}

	logDebug("restoreDeviceSystemMode: set device system mode. %v %v", devInfo.MacAddress, devInfo.Location.SystemMode.Target)
	return nil
}

func updateLearningData(macAddress string, expiresAt *time.Time, reLearningEnabled int) error {
	result, err := _pgCn.ExecNonQuery("UPDATE flosense SET relearning_expires_at=$2, relearning_enabled=$3 WHERE device_id=$1;",
		macAddress,
		&expiresAt,
		reLearningEnabled)

	if err != nil {
		logWarn("updateLearningStatus: Unable to update learning mode status for device %v", macAddress)
		return err
	}
	if affected, _ := result.RowsAffected(); affected != 1 {
		logWarn("updateLearningStatus: floSense row not found for device %v", macAddress)
		return err
	}
	return nil
}