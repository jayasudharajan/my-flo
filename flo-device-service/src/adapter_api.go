package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/pkg/errors"

	"github.com/labstack/gommon/log"
)

const locationsKey = "locations"
const locationKey = "location"
const idKey = "id"
const devicesKey = "devices"
const macAddressKey = "macAddress"

// const systemModeKey = "systemMode"
const targetKey = "target"
const isLockedKey = "isLocked"
const revertModeKey = "revertMode"
const revertScheduledAtKey = "revertScheduledAt"
const shouldInheritKey = "shouldInherit"
const lastKnown = "lastKnown"
const absentKeyErrMsg = "%s key is absent in the response %v from %s"
const nilValueErrMsg = "nil value for %s key in the response from %s"
const failedToCastErrMsg = "failed to cast %v to %s"
const enterpriseAccountType = "enterprise"

type SystemModeValue = string

const (
	SM_Home  SystemModeValue = "home"
	SM_Away  SystemModeValue = "away"
	SM_Sleep SystemModeValue = "sleep"
)

type SystemMode struct {
	IsLocked      bool            `json:"isLocked"`
	ShouldInherit bool            `json:"shouldInherit"`
	LastKnown     SystemModeValue `json:"lastKnown"`
	Target        SystemModeValue `json:"target"`
	RevertMode    SystemModeValue `json:"revertMode"`
	RevertMinutes int             `json:"revertMinutes"`
}

type Account struct {
	Id   string `json:"id"`
	Type string `json:"type"`
}

type Location struct {
	Id         string     `json:"id"`
	Timezone   string     `json:"timezone"`
	SystemMode SystemMode `json:"systemMode"`
	Devices    []Device   `json:"devices"`
	Account    Account    `json:"account"`
}

type Device struct {
	Id          string     `json:"id"`
	MacAddress  string     `json:"macAddress"`
	IsConnected bool       `json:"isConnected"`
	FwVersion   string     `json:"fwVersion"`
	DeviceModel string     `json:"deviceModel"`
	DeviceType  string     `json:"deviceType"`
	Location    Location   `json:"location"`
	SystemMode  SystemMode `json:"systemMode"`
}

func getPubGwPing(ctx context.Context) error {
	resp, err := makeHttpRequest(ctx, http.MethodGet, "/api/v2/ping", EmptyString, nil)
	if err == nil && resp != nil {
		defer resp.Body.Close()
		if resp.StatusCode >= 400 {
			if jd, e := ioutil.ReadAll(resp.Body); e != nil {
				err = e
			} else {
				rmap := make(map[string]interface{})
				if e = json.Unmarshal(jd, &rmap); e != nil {
					err = e
				} else if msg, ok := rmap["message"]; ok && msg != nil {
					err = errors.New(fmt.Sprint(msg))
				} else {
					err = errors.New(fmt.Sprintf("%v %v", resp.StatusCode, resp.Status))
				}
			}
		}
	}
	return err
}

func getDeviceLastKnownData(ctx context.Context, getDeviceInfoRelativePath string) (map[string]interface{}, error) {
	respD, err := makeHttpRequest(ctx, http.MethodGet, getDeviceInfoRelativePath, EmptyString, nil)
	if err != nil {
		return nil, err
	}
	defer respD.Body.Close()
	log.Debugf("called GET %s", getDeviceInfoRelativePath)
	if respD.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unsuccessful request to %s, status code %d", getDeviceInfoRelativePath, respD.StatusCode)
	}
	var jsonResponseD []byte
	if jsonResponseD, err = ioutil.ReadAll(respD.Body); err != nil {
		return nil, err
	}
	var deviceInfoResponse map[string]interface{}
	if err = json.Unmarshal(jsonResponseD, &deviceInfoResponse); err != nil {
		return nil, err
	}
	icdI, ok := deviceInfoResponse[idKey]
	if !ok {
		return deviceInfoResponse, fmt.Errorf(absentKeyErrMsg, idKey, deviceInfoResponse, getDeviceInfoRelativePath)
	}
	if icdI == nil {
		return deviceInfoResponse, fmt.Errorf(nilValueErrMsg, idKey, getDeviceInfoRelativePath)
	}
	if _, ok := icdI.(string); !ok {
		return deviceInfoResponse, fmt.Errorf(failedToCastErrMsg, icdI, "string")
	}
	return deviceInfoResponse, nil
}

func getSystemModeDevice(ctx context.Context, getDeviceInfoRelativePath string) (systemModeDevice SystemModeDevice, deviceInfoResponse map[string]interface{}, err error) {
	if deviceInfoResponse, err = getDeviceLastKnownData(ctx, getDeviceInfoRelativePath); err != nil {
		return
	}
	var systemModeDev map[string]interface{}
	if systemModeDev, err = getMapOfStringInterface(deviceInfoResponse, systemModeKey, getDeviceInfoRelativePath); err != nil {
		return
	}

	isLockedDev := getBoolValueByKeyFromMapOfStringInterface(systemModeDev, isLockedKey, getDeviceInfoRelativePath)
	shouldInheritDev := getBoolValueByKeyFromMapOfStringInterface(systemModeDev, shouldInheritKey, getDeviceInfoRelativePath)
	lastKnownDev := getStringValueByKeyFromMapOfStringInterface(systemModeDev, lastKnown, getDeviceInfoRelativePath)
	targetDev := getStringValueByKeyFromMapOfStringInterface(systemModeDev, targetKey, getDeviceInfoRelativePath)
	revertScheduledAtDev := getStringValueByKeyFromMapOfStringInterface(systemModeDev, revertScheduledAtKey, getDeviceInfoRelativePath)
	revertModeDev := getStringValueByKeyFromMapOfStringInterface(systemModeDev, revertModeKey, getDeviceInfoRelativePath)

	systemModeDevice = SystemModeDevice{
		SystemModeBase: SystemModeBase{
			Target:            targetDev,
			RevertScheduledAt: revertScheduledAtDev,
			RevertMode:        revertModeDev,
		},
		IsLocked:      isLockedDev,
		ShouldInherit: shouldInheritDev,
		LastKnown:     lastKnownDev,
	}
	return
}

func getSystemModeBase(getDeviceInfoRelativePath string, deviceInfoResponse map[string]interface{}) (locationId string, systemModeRes SystemModeBase, err error) {
	var location map[string]interface{}
	if location, err = getMapOfStringInterface(deviceInfoResponse, locationKey, getDeviceInfoRelativePath); err != nil {
		return
	}
	locationIdI, ok := location[idKey]
	if !ok {
		err = fmt.Errorf(absentKeyErrMsg, "location "+idKey, deviceInfoResponse, getDeviceInfoRelativePath)
		return
	}
	if locationIdI == nil {
		err = fmt.Errorf(nilValueErrMsg, "location "+idKey, getDeviceInfoRelativePath)
		return
	}
	if locationId, ok = locationIdI.(string); !ok {
		err = fmt.Errorf(failedToCastErrMsg, locationIdI, "string")
		return
	}
	var systemModeLoc map[string]interface{}
	if systemModeLoc, err = getMapOfStringInterface(location, systemModeKey, getDeviceInfoRelativePath); err != nil {
		return
	}

	targetLoc := getStringValueByKeyFromMapOfStringInterface(systemModeLoc, targetKey, getDeviceInfoRelativePath)
	revertModeLoc := getStringValueByKeyFromMapOfStringInterface(systemModeLoc, revertModeKey, getDeviceInfoRelativePath)
	revertScheduledAtLoc := getStringValueByKeyFromMapOfStringInterface(systemModeLoc, revertScheduledAtKey, getDeviceInfoRelativePath)
	systemModeRes = SystemModeBase{
		Target:            targetLoc,
		RevertScheduledAt: revertScheduledAtLoc,
		RevertMode:        revertModeLoc,
	}
	return
}

type ReconRejectionError struct {
	err error
}

func (re *ReconRejectionError) Error() string {
	return re.err.Error()
}

func (re ReconRejectionError) String() string {
	return fmt.Sprint(re.err)
}

var (
	PUCK_RECON_ERR  = &ReconRejectionError{errors.New("device is a puck")}
	NOT_CONNECT_ERR = &ReconRejectionError{errors.New("device is not connected")}
	NOT_PAIRED_ERR  = &ReconRejectionError{errors.New("device is not paired")}
)

func GetSystemModeReconciliation(ctx context.Context, deviceId string) (SystemModeReconciliation, error) {
	var (
		getDeviceInfoRelativePath                 = fmt.Sprintf("/api/v2/devices?macAddress=%s&expand=location", deviceId)
		systemModeDevice, deviceInfoResponse, err = getSystemModeDevice(ctx, getDeviceInfoRelativePath)
	)
	if err != nil {
		return SystemModeReconciliation{}, err
	}
	if model, ok := deviceInfoResponse["deviceModel"]; ok && model != nil {
		var modelName string
		if modelName, ok = model.(string); ok {
			if strings.Index(strings.ToLower(modelName), "flo_device_") != 0 {
				return SystemModeReconciliation{}, PUCK_RECON_ERR
			}
		}
	}
	if isPaired, ok := deviceInfoResponse["isPaired"]; ok && isPaired != nil {
		var paired bool
		if paired, ok = isPaired.(bool); !(ok && paired) {
			return SystemModeReconciliation{}, NOT_PAIRED_ERR
		}
	} else {
		return SystemModeReconciliation{}, NOT_PAIRED_ERR
	}
	if isConn, ok := deviceInfoResponse["isConnected"]; ok && isConn != nil {
		var connected bool
		if connected, ok = isConn.(bool); !(ok && connected) {
			return SystemModeReconciliation{}, NOT_CONNECT_ERR
		}
	} else {
		return SystemModeReconciliation{}, NOT_CONNECT_ERR
	}

	var (
		locationId    string
		systemModeLoc SystemModeBase
	)
	if locationId, systemModeLoc, err = getSystemModeBase(getDeviceInfoRelativePath, deviceInfoResponse); err != nil {
		return SystemModeReconciliation{}, err
	}

	icd, _ := deviceInfoResponse[idKey]
	return SystemModeReconciliation{
		Icd:        icd.(string),
		Mac:        deviceId,
		LocationId: locationId,
		Device:     systemModeDevice,
		Location:   systemModeLoc,
	}, nil
}

// this function raises returns and error if key is not in the input map
func getMapOfStringInterface(input map[string]interface{}, key string, path string) (map[string]interface{}, error) {
	outputI, ok := input[key]
	if !ok {
		return nil, fmt.Errorf(absentKeyErrMsg, key, input, path)
	}
	if outputI == nil {
		return nil, fmt.Errorf(nilValueErrMsg, key, path)
	}
	output, ok := outputI.(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf(failedToCastErrMsg, outputI, "map[string]interface{}")
	}
	return output, nil
}

// this function defaults to unknown
func getStringValueByKeyFromMapOfStringInterface(input map[string]interface{}, key string, path string) string {
	value := "undefined"
	valueI, ok := input[key]
	if !ok {
		log.Debugf(absentKeyErrMsg, key, input, path)
	} else {
		if valueI == nil {
			log.Warnf(nilValueErrMsg, key, path)
		} else {
			value, ok = valueI.(string)
			if !ok {
				log.Errorf(failedToCastErrMsg, valueI)
			}
		}
	}
	return value
}

// this function defaults to false
func getBoolValueByKeyFromMapOfStringInterface(input map[string]interface{}, key string, path string) bool {
	value := false
	isLockedI, ok := input[key]
	if !ok {
		log.Debugf(absentKeyErrMsg, key, input, path)
	} else {
		if isLockedI == nil {
			log.Warnf(nilValueErrMsg, key, path)
		} else {
			value, ok = isLockedI.(bool)
			if !ok {
				log.Errorf(failedToCastErrMsg, isLockedI, "bool")
			}
		}
	}
	return value
}

var _logSleepOnly = false

func init() {
	_logSleepOnly = strings.EqualFold(getEnvOrDefault("DS_LOG_DEVICE_SLEEP_ONLY", ""), "true")
}

func logDeviceSleepTargetOnly(level string, systemMode string) bool {
	if _logSleepOnly {
		//return strings.EqualFold(level, "devices") && strings.EqualFold(systemMode, SYSTEM_MODE_SLEEP)
		return strings.EqualFold(systemMode, SYSTEM_MODE_SLEEP)
	}
	return false
}

func SetTargetSystemMode(ctx context.Context, id, level, systemMode string, context SystemModeReconciliation) bool {
	var (
		rl     = ReconLog{level, id, systemMode, &context, context.reason}
		status int
		err    error
	)
	go _reconAudit.Store(&rl)

	if logDeviceSleepTargetOnly(level, systemMode) { //store audit log async
		logInfo("RSM SetTargetSystemMode: SKIP %v for %s %s", systemMode, level, id)
		status = 304
	} else {
		var (
			relativePath = fmt.Sprintf("/api/v2/%s/%s/systemMode", level, id)
			data         = map[string]interface{}{targetKey: systemMode}
			buf          []byte
			resp         *http.Response
		)
		if buf, err = json.Marshal(data); err == nil {
			if resp, err = makeHttpRequest(ctx, http.MethodPost, relativePath, string(buf), nil); err == nil {
				defer resp.Body.Close()
				status = resp.StatusCode
			}
		}
	}

	if err != nil {
		logError("RSM SetTargetSystemMode: failed to set %v mode for id %s to %v. %v", level, id, systemMode, err.Error())
		return false
	} else if status >= 400 {
		logError("RSM SetTargetSystemMode: failed to set %v mode for id %s to %v. status code %v", level, id, systemMode, status)
		return false
	} else {
		logInfo("RSM SetTargetSystemMode: set %v mode for id %s to %v", level, id, systemMode)
		return true
	}
}

func GetDevice(ctx context.Context, macAddress string, expand string) (*Device, error) {
	expandStr := ""
	if len(expand) > 0 {
		expandStr = "&expand=" + expand
	}
	relativePath := "/api/v2/devices?macAddress=" + macAddress + expandStr
	respD, err := makeHttpRequest(ctx, http.MethodGet, relativePath, EmptyString, nil)
	if err != nil {
		return nil, err
	}
	defer respD.Body.Close()
	log.Debugf("called GET %s", relativePath)
	if respD.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unsuccessful request to %s, status code %d", relativePath, respD.StatusCode)
	}
	var jsonResponseD []byte
	if jsonResponseD, err = ioutil.ReadAll(respD.Body); err != nil {
		return nil, err
	}
	deviceInfoResponse := Device{}
	if err = json.Unmarshal(jsonResponseD, &deviceInfoResponse); err != nil {
		return nil, err
	}
	if len(deviceInfoResponse.Id) == 0 {
		return nil, fmt.Errorf(absentKeyErrMsg, idKey, deviceInfoResponse, relativePath)
	}
	return &deviceInfoResponse, nil
}
