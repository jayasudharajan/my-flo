package main

import (
	"context"
	"time"
)

type HttpUtilRetry = HttpUtil

// httpUtilRetry is a decorator to HttpUtil
type httpUtilRetry struct {
	base      HttpUtil
	retry     canRetryFunc
	retryWait time.Duration
	log       *Logger
}

type canRetryFunc = func(e error, reAttempts int32) (bool, time.Duration)

func CreateHttpUtilRetry(base HttpUtil, retry canRetryFunc, log *Logger) HttpUtilRetry {
	hr := httpUtilRetry{
		base:      base,
		retry:     retry,
		retryWait: time.Duration(222) * time.Millisecond,
		log:       log.CloneAsChild("htuRetry"),
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
			case 503, 423:
				return true, hr.retryWait * 2
			}
		}
	}
	return false, 0
}

func (hr *httpUtilRetry) GetAuth() string {
	return hr.base.GetAuth()
}

func (hr *httpUtilRetry) SetAuth(auth string) HttpUtil {
	return hr.base.SetAuth(auth)
}

func (hr *httpUtilRetry) Do(ctx context.Context, method, url string, req interface{}, okStatus func(int) bool, resp interface{}, headers ...StringPairs) error {
	defer panicRecover(hr.log, "httpUtilRetry.Do(%q, %q, %v,...)", method, url, req)
	var (
		e error
		i int32 = 0
	)
	for {
		e = hr.base.Do(ctx, method, url, req, okStatus, resp, headers...)
		if e == nil {
			break
		}
		if ok, wt := hr.retry(e, i); ok {
			hr.logRetry(e, i, false, method, url)
			i++
			if wt > 0 {
				time.Sleep(wt)
			}
		} else {
			hr.logRetry(e, i, true, method, url)
			break
		}
	}
	return e
}

func (hr *httpUtilRetry) logRetry(e error, attempts int32, last bool, method, url string) {
	if last {
		if he, ok := e.(*HttpErr); ok && he != nil && he.Code > 0 && he.Code < 500 {
			hr.log.IfWarnF(e, "Retry %v failed, NO_RETRY | %v %v", attempts, method, url)
		} else {
			hr.log.IfErrorF(e, "Retry %v failed, NO_RETRY | %v %v", attempts, method, url)
		}
	} else {
		hr.log.IfWarnF(e, "Retry %v failed, RETRY_AGAIN | %v %v", attempts, method, url)
	}
}
