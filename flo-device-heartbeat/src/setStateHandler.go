package main

import (
	"net/http"
)

func setStateHandler(w http.ResponseWriter, r *http.Request) {
	reqBody := SetStateRequestModel{}
	e := httpGetExpectedBody(r, &reqBody)

	if e != nil {
		httpError(w, 400, e.Error(), nil)
		return
	}

	if len(reqBody.Items) > 20 {
		httpError(w, 400, "items property limited to 20 items", nil)
		return
	}

	// If we have a single item
	if len(reqBody.MacAddress) == 12 {
		trySetDeviceOnlineState(reqBody.MacAddress, reqBody.IsConnected, reqBody.Force, true)
	}

	// If we filled in an item list of records
	for _, d := range reqBody.Items {
		trySetDeviceOnlineState(d.MacAddress, d.IsConnected, reqBody.Force, true)
	}

	httpWrite(w, 200, nil)
}

type SetStateRequestModel struct {
	Force       bool               `json:"force"`
	MacAddress  string             `json:"macAddress,omitempty"`
	IsConnected bool               `json:"isConnected,omitempty"`
	Items       []StateDeviceModel `json:"items,omitempty"`
}

type StateDeviceModel struct {
	MacAddress  string `json:"macAddress,omitempty"`
	IsConnected bool   `json:"isConnected,omitempty"`
}
