package main

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/hashicorp/go-retryablehttp"
	"github.com/labstack/gommon/log"
)

func makeHttpRequest(ctx context.Context, method, relativePath, body string, headers map[string]string) (*http.Response, error) {
	url := fmt.Sprintf("%s%s", FloApiUrl, relativePath)

	if _logMinLevel == 0 {
		started := time.Now()
		defer func(st time.Time, verb, path string) {
			logTrace("makeHttpRequest: %v %v Took %vms", method, relativePath, time.Since(st).Milliseconds())
		}(started, method, relativePath)
	}
	req, reqErr := retryablehttp.NewRequestWithContext(ctx, method, url, strings.NewReader(body))
	if reqErr != nil {
		return nil, reqErr
	}
	if headers != nil {
		for k, v := range headers {
			req.Header.Add(k, v)
		}
	}

	// add default headers
	if token != EmptyString {
		req.Header.Add("authorization", token)
	}
	req.Header.Add("content-type", "application/json")

	res, errRes := httpClient.Do(req)
	if errRes != nil {
		statusCode := 0
		if res != nil {
			statusCode = res.StatusCode
		}
		log.Errorf("failed http %s request to %s with status %d, err: %v", method, url, statusCode, errRes)
	}

	return res, errRes
}

func makeHttpFullPathRequest(ctx context.Context, method, fullpath, body string, headers map[string]string) (*http.Response, error) {
	if _logMinLevel == 0 {
		started := time.Now()
		defer func(st time.Time, verb, path string) {
			logTrace("makeHttpRequest: %v %v Took %vms", method, fullpath, time.Since(st).Milliseconds())
		}(started, method, fullpath)
	}
	url := fmt.Sprintf("%s", fullpath)
	req, reqErr := retryablehttp.NewRequestWithContext(ctx, method, url, strings.NewReader(body))
	if reqErr != nil {
		return nil, reqErr
	}
	if headers != nil {
		for k, v := range headers {
			req.Header.Add(k, v)
		}
	}

	// add default headers
	if token != EmptyString {
		req.Header.Add("authorization", token)
	}
	req.Header.Add("content-type", "application/json")

	res, errRes := httpClient.Do(req)
	if errRes != nil {
		statusCode := 0
		if res != nil {
			statusCode = res.StatusCode
		}
		log.Errorf("failed http %s request to %s with status %d, err: %v", method, url, statusCode, errRes)
	}

	return res, errRes
}
