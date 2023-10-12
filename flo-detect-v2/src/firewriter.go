package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	instana "github.com/instana/go-sensor"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

func fireWriterDevice(ctx context.Context, macAddress string, item interface{}) error {
	if !isValidMacAddress(macAddress) {
		return errors.New("invalid mac address")
	}
	if item == nil {
		return errors.New("item is nil")
	}

	httpClient := http.Client{
		Timeout: time.Duration(10 * time.Second),
	}
	// add context propagation
	httpClient.Transport = tracing.PanicWrapRoundTripper("AdapterHttpClient", instana.RoundTripper(tracing.Instana, httpClient.Transport))

	body, e := json.Marshal(item)
	if e != nil {
		return e
	}

	url := fmt.Sprintf("%v/v1/firestore/devices/%v", _fireWriterUrl, macAddress)
	req, reqErr := http.NewRequestWithContext(ctx, "POST", url, strings.NewReader(string(body)))
	if reqErr != nil {
		return reqErr
	}

	req.Header.Add("content-type", "application/json")

	res, errRes := httpClient.Do(req)
	if errRes != nil {
		statusCode := 0
		if res != nil {
			statusCode = res.StatusCode
		}
		logError("fireWriterDevice: %v %v err: %v", macAddress, statusCode, errRes)
		return errRes
	}

	logDebug("fireWriterDevice: %v %v %v", res.StatusCode, macAddress, string(body))
	return nil
}
