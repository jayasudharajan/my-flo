package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"
)

func getDeviceInfo(macAddress string) (DeviceApiModel, error) {
	if !isValidMacAddress(macAddress) {
		return DeviceApiModel{}, logError("getDeviceInfo: invalid mac address")
	}

	url := _apiUrl + "/api/v2/devices?macAddress=" + macAddress + "&expand=location"

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return DeviceApiModel{}, logError("getDeviceInfo: request error. %v", err.Error())
	}
	req.Header.Set("Authorization", "Bearer "+_apiToken)

	c := http.Client{}

	// resp, err := c.Do(req)
	resp, err := _instana.TracingHttpRequest("GetDeviceInfo", req, req, c)
	if err != nil {
		return DeviceApiModel{}, logError("getDeviceInfo: response error. %v", err.Error())
	}
	defer resp.Body.Close()

	respData, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return DeviceApiModel{}, logError("getDeviceInfo: reading body error. %v", err.Error())
	}

	if resp.StatusCode >= 400 {
		return DeviceApiModel{}, logError("getDeviceInfo: api bad status code %v %v", macAddress, resp.StatusCode)
	}

	temp := DeviceApiModel{}
	err = json.Unmarshal(respData, &temp)
	if err != nil {
		return DeviceApiModel{}, logError("getDeviceInfo: parsing body error. %v", err.Error())
	}

	return temp, nil
}

type DeviceApiModel struct {
	Id            string `json:"id"`
	MacAddress    string `json:"macAddress"`
	IsConnected   bool
	FwVersion     string
	DeviceModel   string
	DeviceType    string
	Location      LocationApiModel
	SystemMode    SystemModeModel
	InstallStatus struct {
		IsInstalled bool      `json:"isInstalled"`
		InstallDate time.Time `json:"installDate"`
	} `json:"installStatus"`
}

type AccountApiModel struct {
	Id string `json:"id"`
}

type LocationApiModel struct {
	Id         string `json:"id"`
	Timezone   string `json:"timezone"`
	SystemMode SystemModeModel
	Devices    []DeviceApiModel `json:"devices"`
	Account    AccountApiModel  `json:"account"`
}

type SystemModeModel struct {
	IsLocked      bool   `json:"isLocked"`
	ShouldInherit bool   `json:"shouldInherit"`
	LastKnown     string `json:"lastKnown"`
	Target        string `json:"target"`
	RevertMode    string `json:"revertMode"`
	RevertMinutes int    `json:"revertMinutes"`
}

func sendScheduleDirective(icdId string, item *PesHardwareDirectiveModel) error {
	if len(icdId) < 32 {
		return logError("invalid icdId")
	}
	if item == nil || len(item.SystemMode) == 0 {
		return logError("empty payload")
	}

	data, err := json.Marshal(item)
	if err != nil {
		return logError("error marshaling to json: %v %v %v", icdId, item, err.Error())
	}

	logDebug("PESSCHEDULE: %v", string(data))

	return sendDirective(icdId, "setpesschedule", data)
}

func sendDirective(icdId string, directive string, body []byte) error {
	if len(icdId) < 32 {
		return logError("sendDirective: icdId appears invalid")
	}
	if len(directive) < 4 {
		return logError("sendDirective: directive appears invalid")
	}
	if len(body) < 2 {
		return logError("sendDirective: body appears invalid")
	}

	buffer := bytes.NewBuffer(body)
	url := _apiUrl + "/api/v1/directives/icd/" + icdId + "/" + directive
	req, err := http.NewRequest("POST", url, buffer)
	if err != nil {
		return logError("sendDirective: request error. %v", err.Error())
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+_apiToken)

	c := http.Client{}

	//resp, err := c.Do(req)
	resp, err := _instana.TracingHttpRequest("SendNewDirective", req, req, c)
	if err != nil {
		return logError("sendDirective: response error. %v", err.Error())
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return logError("sendDirective: reading body error. %v", err.Error())
	}

	if resp.StatusCode >= 400 {
		return logError("sendDirective: %v %v %v %v", icdId, directive, resp.StatusCode, string(data))
	}

	return nil
}

func sendFwProperties(macAddress string, floSenseShutoffLevel int) error {

	payload := fmt.Sprintf("{\"flosense_shut_off_level\":%v}", floSenseShutoffLevel)

	buffer := bytes.NewBuffer([]byte(payload))
	url := _dsApiUrl + "/v1/devices/" + macAddress + "/fwproperties"
	req, err := http.NewRequest("POST", url, buffer)
	if err != nil {
		return logError("sendFwProperties: request error. %v", err.Error())
	}
	req.Header.Set("Content-Type", "application/json")

	c := http.Client{}
	resp, err := c.Do(req)
	if err != nil {
		return logError("sendFwProperties: response error. %v", err.Error())
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return logError("sendFwProperties: reading body error. %v", err.Error())
	}

	if resp.StatusCode >= 400 {
		return logError("sendFwProperties: %v %v %v %v", macAddress, floSenseShutoffLevel, resp.StatusCode, string(data))
	}

	return nil
}

func dsSendFwProperties(macAddress string, props map[string]interface{}) error {
	if len(props) == 0 {
		return logError("dsSendFwProperties: empty properties")
	}

	payload, err := json.Marshal(props)
	if err != nil {
		return logError("dsSendFwProperties: unable to serialize properties. %v %v", macAddress, err.Error())
	}

	buffer := bytes.NewBuffer(payload)
	url := _dsApiUrl + "/v1/devices/" + macAddress + "/fwproperties"
	req, err := http.NewRequest("POST", url, buffer)
	if err != nil {
		return logError("dsSendFwProperties: request error. %v", err.Error())
	}
	req.Header.Set("Content-Type", "application/json")

	c := http.Client{}
	resp, err := c.Do(req)
	if err != nil {
		return logError("dsSendFwProperties: response error. %v", err.Error())
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return logError("dsSendFwProperties: reading body error. %v", err.Error())
	}

	if resp.StatusCode >= 400 {
		return logError("dsSendFwProperties: %v %v %v", macAddress, resp.StatusCode, string(data))
	}

	return nil
}

func dsSyncDevice(macAddress string) error {
	logDebug("dsSyncDevice: %v", macAddress)

	buffer := bytes.NewBuffer([]byte{})
	url := _dsApiUrl + "/v1/devices/" + macAddress + "/sync"
	req, err := http.NewRequest("POST", url, buffer)
	if err != nil {
		return logError("dsSyncDevice: request error. %v", err.Error())
	}
	req.Header.Set("Content-Type", "application/json")

	c := http.Client{}

	resp, err := _instana.TracingHttpRequest("PostDeviceSync", req, req, c)
	if err != nil {
		return logError("dsSyncDevice: response error. %v", err.Error())
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return logError("dsSyncDevice: reading body error. %v", err.Error())
	}

	if resp.StatusCode >= 400 {
		return logError("dsSyncDevice: %v %v %v", macAddress, resp.StatusCode, string(data))
	}

	return nil
}

func UnlockDeviceSystemMode(id string) (status int, err error) {
	status = 0
	relativePath := fmt.Sprintf("/api/v2/devices/%s/systemMode", id)
	data := map[string]interface{}{
		"isLocked": false,
		"target":   "sleep",
	}

	d, err := json.Marshal(data)
	if err != nil {
		return status, err
	}

	buffer := bytes.NewBuffer(d)
	url := _apiUrl + relativePath
	req, err := http.NewRequest("POST", url, buffer)
	req.Header.Set("Authorization", "Bearer "+_apiToken)
	req.Header.Set("Content-Type", "application/json")

	c := http.Client{}

	resp, err := _instana.TracingHttpRequest("PostFirmwareProperties", req, req, c)
	if err != nil {
		return status, err
	}
	status = resp.StatusCode
	return status, nil
}

func SetDeviceTargetSystemMode(id string, systemMode string) (status int, err error) {
	status = 0
	relativePath := fmt.Sprintf("/api/v2/devices/%s/systemMode", id)
	data := map[string]interface{}{
		"target": systemMode,
	}

	d, err := json.Marshal(data)
	if err != nil {
		return status, err
	}

	buffer := bytes.NewBuffer(d)
	url := _apiUrl + relativePath
	req, err := http.NewRequest("POST", url, buffer)
	req.Header.Set("Authorization", "Bearer "+_apiToken)
	req.Header.Set("Content-Type", "application/json")

	c := http.Client{}

	resp, err := _instana.TracingHttpRequest("PostFirmwareProperties", req, req, c)
	if err != nil {
		return status, err
	}
	status = resp.StatusCode
	return status, nil
}

type SubscriptionApiModel struct {
	Id       string           `json:"id"`
	Location LocationApiModel `json:"location"`
	IsActive bool             `json:"isActive"`
}

type SubscriptionApiPage struct {
	Items []SubscriptionApiModel `json:"items"`
	Next  string                 `json:"nextIterator"`
}

func getSubscriptions(next string, fields []string) (SubscriptionApiPage, error) {
	url := _apiUrl + "/api/v2/subscriptions"
	queryParams := []string{"size=50"}

	if next != "" {
		queryParams = append(queryParams, "next="+next)
	}

	if len(fields) > 0 {
		expandParam := "fields=" + strings.Join(fields, ",")
		queryParams = append(queryParams, expandParam)
	}

	if len(queryParams) > 0 {
		url += "?" + strings.Join(queryParams, "&")
	}

	req, err := http.NewRequest("GET", url, nil)

	if err != nil {
		return SubscriptionApiPage{}, err
	}

	req.Header.Set("Authorization", "Bearer "+_apiToken)
	req.Header.Set("Content-Type", "application/json")

	httpClient := http.Client{}

	resp, err := _instana.TracingHttpRequest("getSubscriptions", req, req, httpClient)

	if err != nil {
		return SubscriptionApiPage{}, err
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		return SubscriptionApiPage{}, err
	} else if resp.StatusCode != 200 {
		return SubscriptionApiPage{}, fmt.Errorf("failed with status code %v", resp.StatusCode)
	}

	page := SubscriptionApiPage{}
	err = json.Unmarshal(body, &page)

	if err != nil {
		return SubscriptionApiPage{}, err
	}

	return page, nil
}

func getSubscription(id string, fields []string) (SubscriptionApiModel, error) {
	url := _apiUrl + "/api/v2/subscriptions/" + id
	var queryParams []string

	if len(fields) > 0 {
		expandParam := "fields=" + strings.Join(fields, ",")
		queryParams = append(queryParams, expandParam)
	}

	if len(queryParams) > 0 {
		url += "?" + strings.Join(queryParams, "&")
	}

	req, err := http.NewRequest("GET", url, nil)

	if err != nil {
		return SubscriptionApiModel{}, err
	}

	req.Header.Set("Authorization", "Bearer "+_apiToken)
	req.Header.Set("Content-Type", "application/json")

	httpClient := http.Client{}

	resp, err := _instana.TracingHttpRequest("getSubscription", req, req, httpClient)

	if err != nil {
		return SubscriptionApiModel{}, err
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		return SubscriptionApiModel{}, err
	} else if resp.Status != "200" {
		return SubscriptionApiModel{}, fmt.Errorf("failed with status code %v", resp.StatusCode)
	}

	sub := SubscriptionApiModel{}
	err = json.Unmarshal(body, &sub)

	if err != nil {
		return SubscriptionApiModel{}, err
	}

	return sub, nil
}

func SetDeviceSystemMode(id string, systemMode *SystemModeModel) (status int, err error) {
	status = 0
	relativePath := fmt.Sprintf("/api/v2/devices/%s/systemMode", id)
	data := map[string]interface{}{
		"target": systemMode.Target,
		"isLocked": systemMode.IsLocked,
	}

	if systemMode.RevertMinutes > 0 {
		data["revertMinutes"] = systemMode.RevertMinutes
	}
	if len(systemMode.RevertMode) > 0 {
		data["revertMode"] = systemMode.RevertMode
	}

	d, err := json.Marshal(data)
	if err != nil {
		return status, err
	}

	buffer := bytes.NewBuffer(d)
	url := _apiUrl + relativePath
	req, err := http.NewRequest("POST", url, buffer)
	req.Header.Set("Authorization", "Bearer "+_apiToken)
	req.Header.Set("Content-Type", "application/json")

	c := http.Client{}

	resp, err := _instana.TracingHttpRequest("SetDeviceSystemMode", req, req, c)
	if err != nil {
		return status, err
	}
	status = resp.StatusCode
	return status, nil
}