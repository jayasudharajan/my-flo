package main

import (
	"context"
	"fmt"
	"strings"

	"github.com/blang/semver"
	"github.com/opentracing/opentracing-go/ext"
)

func ValidateDeviceFwPropertiesCapabilities(ctx context.Context, macAddress string, minVersion, maxVersion string) error {
	sp := MakeSpanInternal(ctx, "ValidateDeviceFwPropertiesCapabilities")
	defer sp.Finish()

	deviceResp, err := GetDevice(ctx, macAddress, "location(account)")
	if err != nil {
		msg := fmt.Errorf("cannot fetch device info for device %v, %w", macAddress, err)
		sp.SetTag(string(ext.Error), msg)
		return msg
	}
	if strings.EqualFold(deviceResp.Location.Account.Type, enterpriseAccountType) {
		return fmt.Errorf("Device %v is part of an enterprise account", macAddress)
	}
	if !strings.HasPrefix(deviceResp.DeviceType, "flo_device") {
		return fmt.Errorf("Device %v is not a SWS", macAddress)
	}

	versionOk, err := versionCheck(deviceResp.FwVersion, minVersion, maxVersion)
	if err != nil {
		msg := fmt.Errorf("cannot read version for device %v (min %v, max %v, ver %v), %w", macAddress,
			minVersion, maxVersion, deviceResp.FwVersion, err)
		sp.SetTag(string(ext.Error), msg)
		return msg
	}
	if !versionOk {
		msg := fmt.Errorf("version for device %v doesnt meet requirements (min %v, max %v, ver %v)",
			macAddress, minVersion, maxVersion, deviceResp.FwVersion)
		sp.SetTag(string(ext.Error), msg)
		return msg
	}
	return nil
}

func versionCheck(actualVersion, minimumVersion, maximumVersion string) (bool, error) {
	ver, err := semver.Make(actualVersion)
	if err != nil {
		return false, err
	}
	if minimumVersion != "" {
		goal, err := semver.Make(minimumVersion)
		if err != nil {
			return false, err
		}
		if !ver.GTE(goal) {
			return false, nil
		}
	}

	if maximumVersion != "" {
		goal, err := semver.Make(maximumVersion)
		if err != nil {
			return false, err
		}
		if !ver.LT(goal) {
			return false, nil
		}
	}

	return true, nil
}
