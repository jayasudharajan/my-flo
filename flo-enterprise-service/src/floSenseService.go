package main

import "context"

type floSenseService struct {
	log        *Logger
	url        string
	httpClient *httpUtil
}

func CreateFloSenseService(log *Logger, httpClient *httpUtil, url string) *floSenseService {
	return &floSenseService{
		log:        log.CloneAsChild("floSenseService"),
		httpClient: httpClient,
		url:        url,
	}
}

func (fs *floSenseService) getDevice(ctx context.Context, macAddress string) (*FloSenseDevice, error) {
	if !isValidMacAddress(macAddress) {
		return nil, fs.log.Error("getDevice: invalid mac address")
	}

	var (
		resp = FloSenseDevice{}
		err  = fs.httpClient.Do(ctx, "GET", fs.url+"/devices/"+macAddress, nil, nil, &resp)
	)
	if err != nil {
		return nil, fs.log.Error("getDevice: request error. %v", err.Error())
	}

	return &resp, nil
}

func (fs *floSenseService) update(ctx context.Context, macAddress string, payload *UpdateFloSensePayload) error {
	if len(payload.MacAddress) == 0 {
		payload.MacAddress = macAddress
	}
	err := fs.httpClient.Do(ctx, "POST", fs.url+"/devices/"+macAddress, payload, nil, nil)
	if err != nil {
		return fs.log.Error("update: request error. %v", err.Error())
	}
	return nil
}
