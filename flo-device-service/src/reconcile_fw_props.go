package main

import (
	"context"

	"github.com/pkg/errors"

	"encoding/json"
)

func ReconcileFwProps(ctx context.Context, SqlRepo *PgDeviceRepository, macAddress string) {
	sp := MakeSpanInternal(ctx, "ReconcileFwProps")
	sp.Finish()

	logInfo("ReconcileFwProps: Starting fw props reconciliation for device %v", macAddress)
	err := ValidateDeviceFwPropertiesCapabilities(ctx, macAddress, minFwValueToReconcile, noFwValue)
	if err != nil {
		logWarn("ReconcileFwProps: %v", err.Error())
		return
	}

	dbResp, _ := SqlRepo.GetDevicesById(ctx, []string{macAddress})
	if len(dbResp.Items) < 1 {
		logWarn("ReconcileFwProps: Could not find device %v in the db", macAddress)
		return
	}
	fwProps := dbResp.Items[0].FwProperties
	if fwProps == nil {
		logDebug("ReconcileFwProps: Could not find fw props for device %v", macAddress)
		return
	}
	floDetectEnabled := false
	if floDetectValue, ok := (*fwProps)["flodetect_post_enabled"]; ok {
		if floDetectEnabled, ok = floDetectValue.(bool); !ok {
			logWarn(failedToCastErrMsg, floDetectValue, "bool")
			return
		}
	}
	if floDetectEnabled {
		logDebug("ReconcileFwProps: Skipping as fw props for device %v do not need to be updated (flodetect_post_enabled=true)", macAddress)
		return
	}

	propsToSend := make(map[string]interface{})
	propsToSend["flodetect_post_enabled"] = true
	if err = sendPropsToDevice(ctx, macAddress, propsToSend, SqlRepo); err != nil {
		logWarn("ReconcileFwProps: Could not send fw properties to device %v", macAddress)
		return
	}
	logInfo("ReconcileFwProps: Fw props reconciliation for device %v has successfully completed", macAddress)
}

func sendPropsToDevice(ctx context.Context, macAddress string, fwProperties map[string]interface{}, SqlRepo *PgDeviceRepository) error {
	sp := MakeSpanInternal(ctx, "sendPropsToDevice")
	defer sp.Finish()

	requestId, err := GenerateUuid()
	if err != nil {
		return errors.Wrapf(err, failedToGenerateUuidErrorMsgTemplate, macAddress)
	}
	if len(fwProperties) == 0 {
		return nil
	}
	fwPropertiesSetter := FwPropertiesSetter{
		Id:           macAddress,
		RequestId:    requestId,
		FwProperties: fwProperties,
	}
	if buf, err := json.Marshal(fwPropertiesSetter); err != nil {
		return errors.Wrapf(err, "ReconcileFwProps: failed to marshal device fw props setter, err: %v", err)
	} else {
		PublishToFwPropsMqttTopic(ctx, macAddress, QOS_1, buf, "set")
		if macAddress != "" {
			rq := FwUpdateReq{
				DeviceId: macAddress,
				FwProps:  fwProperties,
			}
			if e := SqlRepo.SetFwPropReq(ctx, &rq); e != nil {
				return errors.Wrapf(e, "ReconcileFwProps: failed to update fw_properties_req for device id %v: %v", rq.DeviceId, err)
			}
		}
		return nil
	}
}
