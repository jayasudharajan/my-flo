package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/blang/semver"
	"github.com/labstack/gommon/log"

	"github.com/pkg/errors"
)

const onboardingLogCode = "ProcessOnboardingEventsKafkaMessage"
const failedToGetLatestTelemetryDataErrMsg = "failed to get %s from deviceId_%s latest telemetry data"

var _keyDur = NewKeyPerDuration(time.Hour) //limit local cache ttl so we don't consume all local RAM for high send volumes
var once sync.Once
var ohu *httpUtil

func ProcessOnboardingEventsTopic(ctx context.Context, payload []byte) error {
	onLog, err := unmarshallOnboardingEvent(payload)
	if err != nil {
		logError("%s: failed to unmarshall onboarding event for payload %s: %v", onboardingLogCode, payload, err)
		return err
	}
	hash, ttls, err := computeHash(onLog.Id, onLog.DeviceId)
	if err != nil {
		return err
	}

	var (
		dupKey  = fmt.Sprintf("onboarding event:dup:{%v}", hash)
		ttlsDur = time.Duration(int64(ttls)) * time.Second
		ok      bool
	)

	if ok = _keyDur.Check(dupKey, ttlsDur); ok { //check local cache first, should reduce redis calls
		go createKafkaApiOnboardingEvent(ctx, *onLog, dupKey, ttlsDur)
	}
	if !ok {
		logNotice("duplicate message processed within %v | key=%v", ttlsDur, dupKey)
	}

	return nil
}

func computeHash(id, deviceId string) (string, int, error) {
	var (
		hash string
		sb   = &strings.Builder{}
		ttls = 1800
	)

	sb.WriteString("onboard|")
	sb.WriteString(id)
	sb.WriteString("|")
	sb.WriteString(deviceId)

	slug := sb.String()
	sb.Reset()
	if mh, er := mh3(slug); er != nil { //hash bc time-uuid might be too uniformed
		logWarn("onboarding event: fail to mh3 %q", er)
		hash = slug //fall back
	} else {
		hash = mh
	}

	return hash, ttls, nil
}

func CheckNeedInstall(ctx context.Context, SqlRepo *PgDeviceRepository, macAddress string, log OnboardingLog) {
	defer panicRecover("rmOldAuditLogs")

	if !strings.HasPrefix(log.DeviceType, "flo_device") {
		logDebug("CheckNeedInstall: Skipping need install check as device %v is not a SWS", macAddress)
		return
	}

	dbResp, err := SqlRepo.GetDevicesById(ctx, []string{macAddress})
	if len(dbResp.Items) < 1 {
		logWarn("CheckNeedInstall: Could not find device %v in the db", macAddress)
		return
	}

	currVer, err := semver.Make(*dbResp.Items[0].FwVersion)
	if err != nil {
		logWarn("CheckNeedInstall: Cannot read current version %v for device %v", dbResp.Items[0].FwVersion, macAddress)
		return
	}
	minVer, err := semver.Make(minFwValueToReconcile)
	if err != nil {
		logWarn("CheckNeedInstall: Cannot read min version %v for device %v", minFwValueToReconcile, macAddress)
		return
	}

	if currVer.LT(minVer) {
		logDebug("CheckNeedInstall: There is no need to check need install fw props for device %v - v% as curr version is less than %v", macAddress, dbResp.Items[0].FwVersion, minFwValueToReconcile)
		return
	}

	fwProps := dbResp.Items[0].FwProperties
	if fwProps == nil {
		logDebug("CheckNeedInstall: Could not find fw props for device %v", macAddress)
		return
	}

	floFwDeviceInstalled := false
	floFwDeviceInstalledPropertyPresent := false

	if floFwValue, ok := (*fwProps)["device_installed"]; ok {
		floFwDeviceInstalledPropertyPresent = true
		if floFwDeviceInstalled, ok = floFwValue.(bool); !ok {
			logWarn(failedToCastErrMsg, floFwValue, "bool")
			return
		}
	}

	if !floFwDeviceInstalledPropertyPresent {
		logDebug("CheckNeedInstall: Skipping as check need install for device %v do not need to be udpated (floFwProp=true)", macAddress)
		return
	}

	if floFwDeviceInstalled {
		logDebug("CheckNeedInstall: Skipping as check need install for device %v do not need to be udpated (floFwProp=true)", macAddress)
		return
	}

	floFwTelemetryPressure := 0.0
	if floFwValue, ok := (*fwProps)["telemetry_pressure"]; ok {
		floFwTelemetryPressure = floFwValue.(float64)
	} else {
		telemetry := getTelemetryForDevice(ctx, macAddress)

		if &telemetry == nil || &telemetry.Devices[0] == nil {
			logDebug("CheckNeedInstall: Skipping as check need install for device %v doesn't have telemetry real time data", macAddress)
			return
		}

		floFwTelemetryPressure = telemetry.Devices[0].Psi
	}

	if floFwTelemetryPressure > 10 {
		event := LogEvent{
			Name: "installed",
		}

		oe := OnboardingLogEvent{
			Id:       log.Id,
			Event:    event,
			DeviceId: log.MacAddress,
		}

		hash, ttls, err := computeHash(oe.Id.String(), oe.DeviceId)
		if err != nil {
			logError("%s: failed to compute hash onboarding event for device id %s: %v", "processOnboardingNeedInstall", oe.DeviceId, err)
		}

		var (
			dupKey  = fmt.Sprintf("onboarding event:dup:{%v}", hash)
			ttlsDur = time.Duration(int64(ttls)) * time.Second
			ok      bool
		)

		if ok = _keyDur.Check(dupKey, ttlsDur); ok {
			createApiOnboardingEvent(ctx, oe, dupKey, ttlsDur)
		}
		logInfo("PublishFwProps: Fw need install publish for device %v has successfully completed", macAddress)
	}
}

func getTelemetryForDevice(ctx context.Context, deviceId string) DevicesLatestTelemetry {
	latestTelemetryData := DevicesLatestTelemetry{}
	status, latestTelemetryData, err := getWaterMeterTelemetryByDevice(ctx, deviceId)
	if err != nil {
		log.Errorf("failed to get device latest telemetry data for deviceId_%s %v", deviceId, err)
	}
	if !status {
		log.Errorf("failed to get device latest telemetry data for deviceId_%s", deviceId)
	}

	return latestTelemetryData
}

func getWaterMeterTelemetryByDevice(ctx context.Context, macAddress string) (bool, DevicesLatestTelemetry, error) {
	var result DevicesLatestTelemetry
	var err error

	var waterMeterApiPath = strings.TrimSpace(WaterMeterApiPath)

	fullPath := fmt.Sprintf("%s/latest?macAddress="+macAddress, waterMeterApiPath)
	log.Debugf("getting deviceId_%s real time data", macAddress)
	res, err := makeHttpFullPathRequest(ctx, http.MethodGet, fullPath, EmptyString, nil)
	if err != nil {
		return false, result, err
	}
	if res != nil {
		defer res.Body.Close()
		if !ContainsInt(successStatusCodes, res.StatusCode) {
			return false, result, nil
		}
		bytes, err := ioutil.ReadAll(res.Body)
		if err != nil {
			return false, result, err
		}
		err = json.Unmarshal(bytes, &result)
		if err != nil {
			return false, result, err
		}
		return true, result, nil
	}
	errMsg := fmt.Sprintf("response from GET %s is nil", fullPath)
	return false, result, errors.New(errMsg)
}

func createApiOnboardingEvent(ctx context.Context, oe OnboardingLogEvent, dupKey string, ttlsDur time.Duration) {
	st := time.Now()
	var onboardingApiToken = strings.TrimSpace(OnboardingApiToken)
	var onboardingApiPath = strings.TrimSpace(OnboardingApiPath)

	once.Do(func() {
		ohu = CreateHttpUtil(onboardingApiToken, nil) //use go's no retry client
	})
	uri := fmt.Sprintf("%v"+onboardingApiPath, FloApiUrl)
	if rid, e := ohu.Do(ctx, "POST", uri, oe, nil, nil); e != nil {
		logError("createApiOnboardingEvent: POST headsup for dev=%v reqId=%v | %v => %v", oe.DeviceId, rid.String(), oe.Id, e)
		_keyDur.Check(dupKey, ttlsDur)
	} else {
		logDebug("createApiOnboardingEvent: POST headsup %vms OK for %v | reqId=%v", time.Since(st).Milliseconds(), oe.DeviceId, rid.String())
	}
}

func createKafkaApiOnboardingEvent(ctx context.Context, oe KafkaOnboardingLogEvent, dupKey string, ttlsDur time.Duration) {
	st := time.Now()
	var onboardingApiToken = strings.TrimSpace(OnboardingApiToken)
	var onboardingApiPath = strings.TrimSpace(OnboardingApiPath)

	once.Do(func() {
		ohu = CreateHttpUtil(onboardingApiToken, nil) //use go's no retry client
	})
	uri := fmt.Sprintf("%v"+onboardingApiPath, FloApiUrl)
	if rid, e := ohu.Do(ctx, "POST", uri, oe, nil, nil); e != nil {
		logError("createApiOnboardingEvent: POST headsup for dev=%v reqId=%v | %v => %v", oe.DeviceId, rid.String(), oe.Id, e)
		_keyDur.Check(dupKey, ttlsDur)
	} else {
		logDebug("createApiOnboardingEvent: POST headsup %vms OK for %v | reqId=%v", time.Since(st).Milliseconds(), oe.DeviceId, rid.String())
	}
}

func unmarshallOnboardingEvent(data []byte) (*KafkaOnboardingLogEvent, error) {
	if len(data) < 2 {
		return nil, errors.New("empty onboarding log payload")
	}

	onLog := new(KafkaOnboardingLogEvent)
	err := json.Unmarshal(data, &onLog)
	if err != nil {
		return nil, err
	}

	return onLog, nil
}
