package main

import (
	"context"
	"fmt"
)

type deviceService struct {
	log        *Logger
	url        string
	httpClient *httpUtil
}

func CreateDeviceService(log *Logger, httpClient *httpUtil, url string) *deviceService {
	return &deviceService{
		log:        log.CloneAsChild("deviceService"),
		httpClient: httpClient,
		url:        url,
	}
}
func (ds *deviceService) getAllDevices(ctx context.Context, mobilePaired bool, offset int) (*DevicesApi, error) {

	resp := DevicesApi{}
	queryParam := fmt.Sprintf("?offset=%d", offset)
	if mobilePaired {
		queryParam += "&mobile=true"
	}

	err := ds.httpClient.Do(ctx, "GET", ds.url+"/v1/devices"+queryParam, nil, nil, &resp)

	if err != nil {
		return nil, ds.log.Error("getDevice: request error. %v", err.Error())
	}

	return &resp, nil
}

func (ds *deviceService) getDevice(ctx context.Context, macAddress string) (*DeviceApi, error) {
	if !isValidMacAddress(macAddress) {
		return nil, ds.log.Error("getDevice: invalid mac address")
	}

	var (
		resp = DeviceApi{}
		err  = ds.httpClient.Do(ctx, "GET", ds.url+"/v1/devices/"+macAddress, nil, nil, &resp)
	)
	if err != nil {
		return nil, ds.log.Error("getDevice: request error. %v", err.Error())
	}

	return &resp, nil
}

func (ds *deviceService) updateHwThresholds(ctx context.Context, macAddress string, hwThresholds *HardwareThresholdPayload) error {
	if !isValidMacAddress(macAddress) {
		return ds.log.Error("updateHwThresholds: invalid mac address")
	}
	payload := DeviceApiPayload{
		HardwareThresholds: hwThresholds,
	}
	err := ds.httpClient.Do(ctx, "POST", ds.url+"/v1/devices/"+macAddress, payload, nil, nil)
	if err != nil {
		return ds.log.Error("updateHwThresholds: request error. %v", err.Error())
	}

	return nil
}

func (ds *deviceService) setDeviceFwProperties(ctx context.Context, macAddress string, properties *FWPropertiesUpdatePayload) error {
	if !isValidMacAddress(macAddress) {
		return ds.log.Error("setDeviceFwProperties: invalid mac address")
	}

	err := ds.httpClient.Do(ctx, "POST", ds.url+"/v1/devices/"+macAddress+"/fwproperties", properties, nil, nil)

	if err != nil {
		return ds.log.Error("setDeviceFwProperties: request error. %v", err.Error())
	}

	return nil
}
