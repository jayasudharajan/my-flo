package main

import (
	"bytes"
	"errors"
	"io/ioutil"
	"net/http"
	"time"
)

func httpCall(url string, method string, payload []byte, headers map[string]string) (int, []byte, error) {
	httpClient := http.Client{
		Timeout: 20 * time.Second,
	}

	// Create the request object
	var req *http.Request
	var reqErr error

	// If payload is nil or empty, then untyped nil is required to prevent panic
	if payload != nil && len(payload) > 0 {
		body := bytes.NewBufferString(string(payload))
		req, reqErr = http.NewRequest(method, url, body)
	} else {
		req, reqErr = http.NewRequest(method, url, nil)
	}

	if reqErr != nil {
		return 500, nil, reqErr
	}

	// If there are headers, add them to the request
	req.Header.Set("content-type", "application/json")
	if len(headers) > 0 {
		for k, v := range headers {
			req.Header.Add(k, v)
		}
	}

	res, errRes := httpClient.Do(req)
	if errRes != nil {
		statusCode := 0
		if res != nil {
			statusCode = res.StatusCode
		}
		logError("failed http %s request to %s with status %d, err: %v", method, url, statusCode, errRes)
	}

	if res == nil {
		return 500, nil, errors.New("empty response object")
	}

	var rv []byte

	if res.Body != nil {
		defer res.Body.Close()
		delta, err := ioutil.ReadAll(res.Body)

		if err != nil {
			logError("error reading body. %v", err.Error())
		} else {
			rv = delta
		}
	}

	return res.StatusCode, rv, nil
}
