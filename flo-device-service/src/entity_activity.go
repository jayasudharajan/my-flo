package main

import (
	"context"
	"device-service/models"
	"encoding/json"

	"github.com/pkg/errors"
)

const deviceActivityType = "device"
const logCode = "ProcessEntityActivityKafkaMessage"

func ProcessEntityActivityTopic(ctx context.Context, payload []byte) {
	entityActivity, err := unmarshallEntityActivity(payload)
	if err != nil {
		logError("%s: failed to unmarshall entity activity for payload %s: %v", logCode, payload, err)
		return
	}

	switch entityActivity.ActivityType {
	case deviceActivityType:
		handleDeviceActivity(ctx, entityActivity)
	}
}

func handleDeviceActivity(ctx context.Context, entityActivity *models.EntityActivity) {
	switch entityActivity.ActivityAction {
	case "deleted":
		handleUnpairing(ctx, entityActivity)
	case "created":
		handlePairing(ctx, entityActivity)
	case "updated":
		handleDeviceChange(ctx, entityActivity)
	}
}

func handleDeviceChange(ctx context.Context, entityActivity *models.EntityActivity) {
	d, err := unmarshallDeviceEntityActivity(entityActivity.Item)
	if err != nil {
		logError("%s: failed to marshall device id %s - %v", logCode, entityActivity.DeviceId, err)
		return
	}
	if d.LTEPaired == nil {
		return
	}
	err = Dsh.SqlRepo.SetMobileState(ctx, d.MacAddress, *d.LTEPaired)
	if err != nil {
		logError("%s: failed to update device id %s: %v", logCode, entityActivity.DeviceId, err)
	}
}

func handleUnpairing(ctx context.Context, entityActivity *models.EntityActivity) {
	err := Arsh.SqlRepo.DeleteActionRulesByTarget(entityActivity.DeviceId)
	if err != nil {
		logError("%s: failed to remove action rules for device id %s: %v", logCode, entityActivity.DeviceId, err)
	} else {
		logInfo("%s: Action rules deleted for unpaired device id: %s", logCode, entityActivity.DeviceId)
	}
	d, err := unmarshallDeviceEntityActivity(entityActivity.Item)
	if err != nil {
		logError("%s: failed to marshall device id %s - %v", logCode, entityActivity.DeviceId, err)
		return
	}

	err = Dsh.SqlRepo.ArchiveDevice(d.MacAddress, entityActivity.DeviceId, d.Location.Id)
	if err != nil {
		logError("%s: failed to archive info for device id %s: %v", logCode, entityActivity.DeviceId, err)
	} else {
		logInfo("%s: archived device id: %s", logCode, entityActivity.DeviceId)
	}
}

func handlePairing(ctx context.Context, entityActivity *models.EntityActivity) {
	d, err := unmarshallDeviceEntityActivity(entityActivity.Item)
	if err != nil {
		logError("%s: failed to marshall device id %s - %v", logCode, entityActivity.DeviceId, err)
		return
	}

	macAddress := d.MacAddress
	err = ValidateDeviceFwPropertiesCapabilities(ctx, macAddress, minFwValueFirstPairing, noFwValue)
	if err != nil {
		logWarn("%s: %v", logCode, err.Error())
		return
	}

	device, err := Dsh.SqlRepo.GetDevice(ctx, macAddress)
	if err != nil {
		logError("%s: failed to get device data for %v - %v", logCode, macAddress, err)
		return
	}

	pps, err := Dsh.SqlRepo.RetrieveDefaultFirmwareValues(*device.Make, *device.Model)
	if err != nil {
		logError("%s: failed to get device data for %v - %v", logCode, macAddress, err)
		return
	}
	propsToSend := make(map[string]interface{})
	for _, p := range pps {
		if p.Provisioning.OnPairing != nil {
			continue
		}
		if ok, err := p.Provisioning.OnPairing.Validate(macAddress); err != nil || !ok {
			logWarn("%s: Could not validate fw property %s, %v", logCode, p.Key, err)
			continue
		}
		propsToSend[p.Key] = p.Value
	}
	if err = sendPropsToDevice(ctx, macAddress, propsToSend, Dsh.SqlRepo); err != nil {
		logWarn("%s: Could not send fw properties to device %v", logCode, macAddress)
		return
	}
}

func unmarshallEntityActivity(data []byte) (*models.EntityActivity, error) {
	if len(data) < 2 {
		return nil, errors.New("empty entity activity payload")
	}

	entityActivity := new(models.EntityActivity)
	err := json.Unmarshal(data, &entityActivity)
	if err != nil {
		return nil, err
	}

	return entityActivity, nil
}

func unmarshallDeviceEntityActivity(itemMap interface{}) (*models.DeviceEntityActivityItem, error) {
	if itemMap == nil {
		return nil, errors.New("empty entity activity payload")
	}

	e := new(models.DeviceEntityActivityItem)
	buf, err := json.Marshal(itemMap)
	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(buf, &e)
	return e, err
}
