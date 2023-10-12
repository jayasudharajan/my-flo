package main

import (
	"context"
	"fmt"
)

type pubGwService struct {
	log        *Logger
	url        string
	httpClient *httpUtil
	auth       StringPairs
}

func CreatePubGwService(log *Logger, httpClient *httpUtil, url string, apiToken string) *pubGwService {
	return &pubGwService{
		log:        log.CloneAsChild("pubGwService"),
		httpClient: httpClient,
		url:        url,
		auth: StringPairs{
			Name:  AUTH_HEADER,
			Value: apiToken,
		},
	}
}

func (pgs *pubGwService) getDevice(ctx context.Context, macAddress string, expand string) (*Device, error) {
	if !isValidMacAddress(macAddress) {
		return nil, pgs.log.Error("getDevice: invalid mac address")
	}

	expandStr := ""
	if len(expand) > 0 {
		expandStr = "&expand=" + expand
	}

	var (
		resp = Device{}
		err  = pgs.httpClient.Do(ctx, "GET", pgs.url+"/api/v2/devices?macAddress="+macAddress+expandStr, nil, nil, &resp, pgs.auth)
	)
	if err != nil {
		return nil, pgs.log.Error("getDevice: request error. %v", err.Error())
	}

	return &resp, nil
}

func (pgs *pubGwService) setDeviceSystemMode(ctx context.Context, deviceId string, payload *SystemModePayload) error {
	relativePath := fmt.Sprintf("/api/v2/devices/%s/systemMode", deviceId)
	body := make(map[string]interface{})
	if payload.IsLocked != nil {
		body["isLocked"] = &payload.IsLocked
	}
	if payload.Target != nil {
		body["target"] = &payload.Target
	}
	if payload.RevertMode != nil {
		body["revertMode"] = &payload.RevertMode
	}
	if payload.RevertMinutes != nil {
		body["revertMinutes"] = &payload.RevertMinutes
	}

	err := pgs.httpClient.Do(ctx, "POST", pgs.url+relativePath, body, nil, nil, pgs.auth)
	if err != nil {
		return pgs.log.Error("setDeviceSystemMode: request error. %v", err.Error())
	}
	return nil
}
