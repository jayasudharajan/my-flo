package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	instana "github.com/instana/go-sensor"
	"github.com/labstack/gommon/log"
	"github.com/pkg/errors"
)

const timeout = 5
const latencyThreshold = 1.0

// Firestore is struct to hold the data to write to the firestore
type Firestore struct {
	Value map[string]interface{} `json:"value"`
}

// FirestoreAuth is the struct to hold the data for authentication with firestore
type FirestoreAuth struct {
	Devices   []string `json:"devices" example:"[0c1c57aea625,0c1c57aec334]"`
	Locations []string `json:"locations" example:"[07f97c2f-81b1-42d9-ac2c-b4675810319e,06f97c2f-71b1-53d9-ac2c-b4675801210e]"`
	Users     []string `json:"users" example:"[08f97c2f-51b1-22d9-ac2c-b4675810310e,16f97c2f-01b1-53d9-ac2c-b4675801210a]"`
}

type FirestoreToken struct {
	Token string `json:"token" example:"tbd"`
}

var successStatusCodes = []int{http.StatusOK, http.StatusAccepted, http.StatusNoContent}

func UpdateFirestore(ctx context.Context, deviceId string, data map[string]interface{}) error {
	var err error
	relativePath := fmt.Sprintf("/v1/firestore/devices/%s", deviceId)
	bytes, err := json.Marshal(data)
	if err != nil {
		return err
	}
	body := string(bytes)
	log.Debugf("updating deviceId_%s real time data with %s", deviceId, body)
	res, err := makeHttpRequestFW(ctx, http.MethodPost, relativePath, body, nil)
	if err != nil {
		return err
	}
	if res != nil {
		defer res.Body.Close()
		if !ContainsInt(successStatusCodes, res.StatusCode) {
			return fmt.Errorf("failing %s %s request with status code %d", http.MethodPost, relativePath, res.StatusCode)
		}
		return nil
	}
	return fmt.Errorf("response from POST %s is nil", relativePath)
}

func GetDeviceRealTimeData(ctx context.Context, deviceId string) (bool, map[string]interface{}, error) {
	var result map[string]interface{}
	var err error

	relativePath := fmt.Sprintf("/v1/firestore/devices/%s", deviceId)
	log.Debugf("getting deviceId_%s real time data", deviceId)
	res, err := makeHttpRequestFW(ctx, http.MethodGet, relativePath, EmptyString, nil)
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
	errMsg := fmt.Sprintf("response from GET %s is nil", relativePath)
	return false, result, errors.New(errMsg)
}

func DeleteDeviceRealTimeData(ctx context.Context, deviceId string) (status int, err error) {
	relativePath := fmt.Sprintf("/v1/firestore/devices/%s", deviceId)
	log.Debugf("deleting deviceId_%s real time data", deviceId)
	res, err := makeHttpRequestFW(ctx, http.MethodDelete, relativePath, EmptyString, nil)
	if err != nil {
		return http.StatusInternalServerError, err
	}
	if res != nil {
		defer res.Body.Close()
		if !ContainsInt(successStatusCodes, res.StatusCode) {
			return res.StatusCode, nil
		}
		return http.StatusNoContent, nil
	}
	errMsg := fmt.Sprintf("response from DELETE %s is nil", relativePath)
	return http.StatusInternalServerError, errors.New(errMsg)
}

func CreateDeviceStub(ctx context.Context, deviceId string) (status int, err error) {
	relativePath := fmt.Sprintf("/v1/firestore/devices/%s?sync=true", deviceId)
	body := Firestore{
		Value: map[string]interface{}{
			"deviceId": deviceId,
		},
	}

	bodyBytes, err := json.Marshal(body)
	if err != nil {
		return http.StatusInternalServerError, err
	}
	res, err := makeHttpRequestFW(ctx, http.MethodPost, relativePath, string(bodyBytes), nil)
	if err != nil {
		return http.StatusInternalServerError, err
	}
	defer res.Body.Close()
	return res.StatusCode, nil
}

var _fwHttpCli = http.Client{
	Timeout: time.Duration(timeout * time.Second),
}

func InitFireWriterHttpClient() {
	_fwHttpCli.Transport = PanicWrapRoundTripper("FWHttpClient", instana.RoundTripper(_instana, nil))
}

func makeHttpRequestFW(ctx context.Context, method, relativePath, body string, headers map[string]string) (*http.Response, error) {
	url := fmt.Sprintf("%s%s", FirewriterUrl, relativePath)

	timeStart := time.Now()
	if _logMinLevel == 0 {
		defer func(ts time.Time, verb, path string) {
			logTrace("makeHttpRequestFW: %v %v Took %vms", verb, path, time.Since(ts).Milliseconds())
		}(timeStart, method, relativePath)
	}

	req, reqErr := http.NewRequestWithContext(ctx, method, url, strings.NewReader(body))
	if reqErr != nil {
		return nil, reqErr
	}
	if headers != nil {
		for k, v := range headers {
			req.Header.Add(k, v)
		}
	}
	req.Header.Add("content-type", "application/json")

	res, errRes := _fwHttpCli.Do(req)
	if errRes != nil {
		statusCode := 0
		if res != nil {
			statusCode = res.StatusCode
		}
		log.Errorf("failed http %s request to %s with status %d, err: %v", method, url, statusCode, errRes)
	}
	timeStop := time.Now()
	diff := timeStop.Sub(timeStart).Seconds()
	if diff > latencyThreshold {
		log.Warnf("latency has increased, it took %f seconds to complete %s to %s", diff, method, url)
	}

	return res, errRes
}
