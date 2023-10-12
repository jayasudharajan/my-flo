package main

import (
	"net/http"
	"time"
)

// httpUtilRetry is a decorator to HttpUtil
type httpUtilRetry struct {
	base      HttpUtil
	retry     canRetryFunc
	retryWait time.Duration
}
type canRetryFunc = func(e error, reAttempts int32) (bool, time.Duration)

func CreateHttpUtilRetry(base HttpUtil, retry canRetryFunc) HttpUtil {
	hr := httpUtilRetry{
		base:      base,
		retry:     retry,
		retryWait: time.Duration(222) * time.Millisecond,
	}
	if dr, _ := time.ParseDuration(getEnvOrDefault("HTTP_REQ_RETRY_SLEEP", "")); dr > 0 {
		hr.retryWait = dr
	}
	if hr.retry == nil {
		hr.retry = hr.retryOnce //default logic
	}
	return &hr
}

// only retry for 502 or 503 once, don't retry on any other http errors
func (hr *httpUtilRetry) retryOnce(e error, reAttempts int32) (bool, time.Duration) {
	if reAttempts == 0 {
		if he, ok := e.(*HttpErr); ok && he != nil {
			switch he.Code {
			case 502:
				return true, hr.retryWait
			case 503:
				return true, hr.retryWait * 2
			}
		}
	}
	return false, 0
}

func (hr *httpUtilRetry) Form(method, url string, req map[string]interface{}, okStatus func(int, http.Header) bool, resp interface{}, headers ...StringPairs) error {
	defer panicRecover(hr.Logger(), "httpUtilRetry.Form(%q, %q, %v,...)", method, url, req)
	var (
		e error
		i int32 = 0
	)
	for {
		e = hr.base.Form(method, url, req, okStatus, resp, headers...)
		if e == nil {
			break
		}
		if ok, wt := hr.retry(e, i); ok {
			hr.logRetry(e, i, false)
			i++
			if wt > 0 {
				time.Sleep(wt)
			}
		} else {
			hr.logRetry(e, i, true)
			break
		}
	}
	return e
}

func (hr *httpUtilRetry) Do(method, url string, req interface{}, okStatus func(int, http.Header) bool, resp interface{}, headers ...StringPairs) error {
	defer panicRecover(hr.Logger(), "httpUtilRetry.Do(%q, %q, %v,...)", method, url, req)
	var (
		e error
		i int32 = 0
	)
	for {
		e = hr.base.Do(method, url, req, okStatus, resp, headers...)
		if e == nil {
			break
		}
		if ok, wt := hr.retry(e, i); ok {
			hr.logRetry(e, i, false)
			i++
			if wt > 0 {
				time.Sleep(wt)
			}
		} else {
			hr.logRetry(e, i, true)
			break
		}
	}
	return e
}

func (hr *httpUtilRetry) logRetry(e error, attempts int32, last bool) {
	if hr.CanLogErr() {
		if last {
			hr.Logger().Error("Retry %v failed, NO_RETRY", attempts)
		} else {
			hr.Logger().Warn("Retry %v failed, RETRY_AGAIN", attempts)
		}
	}
}

func (hr *httpUtilRetry) WithLogs() HttpUtil {
	hr.base.WithLogs()
	return hr
}

func (hr *httpUtilRetry) Logger() Log {
	var l Log
	if hr != nil && hr.base != nil {
		l = hr.base.Logger()
	}
	if l == nil {
		l = _log
	}
	return l
}

func (hr *httpUtilRetry) CanLogErr() bool {
	if hr != nil && hr.base != nil {
		return hr.base.CanLogErr()
	}
	return false
}
