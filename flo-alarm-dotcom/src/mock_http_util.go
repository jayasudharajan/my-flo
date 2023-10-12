package main

import (
	"errors"
	"github.com/google/uuid"
	"net/http"
	"reflect"
	"strings"
	"time"
)

type mockInput = func(method, url string, req interface{}, headers ...StringPairs) (interface{}, error)

type mockHttpUtil struct {
	real   HttpUtil
	log    Log
	ioFunc mockInput
}

func CreateMockHttpUtil(real HttpUtil, log Log, ioFunc mockInput) HttpUtil {
	return &mockHttpUtil{real, log, ioFunc}
}

func AdcMockEndPoints(method, url string, req interface{}, headers ...StringPairs) (interface{}, error) {
	if req != nil && strings.EqualFold(method, "POST") {
		if strings.Contains(url, "/OAuth2/Token.ashx") {
			return OAuthResponse{
				AccessToken: strings.ReplaceAll(uuid.New().String(), "-", ""),
				TokenType:   "Bearer",
				ExpiresIn:   3600,
				IssuedAt:    int(time.Now().Unix()),
			}, nil
		} else if strings.Contains(url, "/ReportStateListener.ashx") {
			hasAuth := false
			for _, h := range headers {
				if strings.EqualFold(h.Name, AUTH_HEADER) {
					hasAuth = true
					break
				}
			}
			if hasAuth {
				return map[string]interface{}{
					"message": "OK",
				}, nil
			}
		}
	}
	return nil, &HttpErr{401, "Forbidden", nil}
}

func (mh *mockHttpUtil) passThrough(url string) bool {
	floApi := getEnvOrDefault("FLO_API_URL", "")
	if floApi != "" && strings.Index(url, floApi) == 0 {
		return true
	}
	return false
}

func (mh *mockHttpUtil) Form(
	method, url string, req map[string]interface{},
	okStatus func(int, http.Header) bool, resp interface{}, headers ...StringPairs) (e error) {

	if mh.passThrough(url) {
		return mh.real.Form(method, url, req, okStatus, resp, headers...)
	}
	var (
		ll                = LL_DEBUG
		note  interface{} = "OK"
		dummy interface{}
	)
	if dummy, e = mh.ioFunc(method, url, req, headers...); e != nil {
		ll = LL_WARN
		note = e
	} else {
		mh.assignPtr(dummy, resp)
	}
	mh.log.Log(ll, "Form: %v %v | %v | %v -> %v", method, url, headers, req, note)
	return e
}

func (mh *mockHttpUtil) assignPtr(dummy, resp interface{}) error {
	if dummy != nil {
		val := reflect.ValueOf(resp)
		if val.Kind() != reflect.Ptr {
			return errors.New("resp: check must be a pointer")
		}
		val.Elem().Set(reflect.ValueOf(dummy))
	}
	return nil
}

func (mh *mockHttpUtil) Do(
	method, url string, req interface{},
	okStatus func(int, http.Header) bool, resp interface{}, headers ...StringPairs) (e error) {

	if mh.passThrough(url) {
		return mh.real.Do(method, url, req, okStatus, resp, headers...)
	}
	var (
		ll                = LL_DEBUG
		note  interface{} = "OK"
		dummy interface{}
	)
	if dummy, e = mh.ioFunc(method, url, req, headers...); e != nil {
		ll = LL_WARN
		note = e
	} else if dummy != nil {
		mh.assignPtr(dummy, resp)
	}
	mh.log.Log(ll, "Do: %v %v | %v | %v -> %v", method, url, headers, req, note)
	return e
}

func (mh *mockHttpUtil) WithLogs() HttpUtil {
	return mh
}

func (mh *mockHttpUtil) Logger() Log {
	return mh.log
}

func (mh *mockHttpUtil) CanLogErr() bool {
	return true
}
