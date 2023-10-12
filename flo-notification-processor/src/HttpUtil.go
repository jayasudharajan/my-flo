package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/pkg/errors"
)

const (
	ENVVAR_HTTP_TIMEOUT_S = "FLO_HTTP_TIMEOUT_S"
	AUTH_HEADER           = "Authorization"
)

type HttpUtil interface {
	Do(method, url string, req interface{}, okStatus func(int) bool, resp interface{}, headers ...StringPairs) error
}

//simple wrapper to reduce code for http client
type httpUtil struct {
	auth   string
	hc     *http.Client
	logErr bool
}

func NewHttpUtil(auth string, timeout time.Duration) HttpUtil {
	return NewHttpUtilViaClient(auth, timeout, nil)
}

func NewHttpUtilViaClient(auth string, timeout time.Duration, hc *http.Client) HttpUtil {
	if hc == nil {
		if timeout < 0 {
			sec, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_HTTP_TIMEOUT_S, ""))
			if sec < 0 {
				sec = 4
			}
			timeout = time.Duration(int64(sec)) * time.Second
		}
		hc = &http.Client{Timeout: timeout}
	}
	u := httpUtil{
		auth: auth,
		hc:   hc,
	}
	return &u
}

type StringPairs struct {
	Name  string
	Value string
}

func (p *httpUtil) Do(method, url string, req interface{}, okStatus func(int) bool, resp interface{}, headers ...StringPairs) error {
	var rr io.Reader
	if req != nil {
		switch t := req.(type) {
		case string:
			rr = strings.NewReader(t)
			break
		case []byte:
			rr = bytes.NewBuffer(t)
			break
		default:
			if buf, e := json.Marshal(req); e != nil {
				return errors.Wrapf(e, "httpUtil %v %v | %v", method, url, req)
			} else {
				rr = bytes.NewBuffer(buf)
			}
		}
	}
	if r, e := p.jsonReq(method, url, rr, headers); e != nil {
		return p.wrapErr(e, method, url)
	} else if e = p.jsonResp(r, okStatus, resp); e != nil {
		return p.wrapErr(e, method, url)
	} else {
		return nil
	}
}

func (p *httpUtil) wrapErr(e error, method, url string) error {
	switch er := e.(type) {
	case *HttpErr:
		if ml := len(er.Message); ml >= 2 && er.Message[0] == '{' && er.Message[ml-1] == '}' {
			er.IsJSON = true
		}
		if er.Trace == nil {
			er.Trace = errors.Errorf("httpUtil %v %v -> %v", method, url, er.Message)
		}
		return httpErrWrap(er, er.Code)
	default:
		return errors.Wrapf(e, "httpUtil %v %v", method, url)
	}
}

func (p *httpUtil) jsonReq(method, url string, rr io.Reader, headers []StringPairs) (resp *http.Response, err error) {
	if req, e := http.NewRequest(method, url, rr); e != nil {
		err = errors.Wrap(e, "jsonReq build")
	} else {
		if p.auth != "" {
			req.Header.Add(AUTH_HEADER, p.auth)
		}
		req.Header.Add("Content-Type", "application/json")
		for _, h := range headers {
			if h.Value == "" {
				req.Header.Del(h.Name)
			} else {
				req.Header[h.Name] = []string{h.Value} //replace
			}
		}
		if resp, e = p.hc.Do(req); e != nil {
			err = errors.Wrapf(e, "jsonReq resp")
		} else if resp == nil {
			err = errors.New("jsonReq resp nil")
		}
	}
	return resp, err
}

func (p *httpUtil) jsonResp(resp *http.Response, okStatus func(int) bool, out interface{}) (err error) {
	if resp == nil {
		return nil
	} else if resp.Body != nil {
		defer resp.Body.Close()
	}
	if (okStatus == nil && resp.StatusCode >= 300) || (okStatus != nil && !okStatus(resp.StatusCode)) {
		buf, e := ioutil.ReadAll(resp.Body)
		if e == nil { //attempts to deserialize anyway
			he := HttpErr{Code: resp.StatusCode}
			if e := json.Unmarshal(buf, &he); e == nil && he.Message != "" {
				err = &he
			}
		}
		if err == nil {
			he := HttpErr{Code: resp.StatusCode}
			if len(buf) > 0 {
				he.Message = string(buf)
			} else {
				he.Message = fmt.Sprintf("Http Response %v %v", resp.StatusCode, resp.Status)
			}
			err = &he
		}
	} else if out == nil {
		//do nothing
	} else if buf, e := ioutil.ReadAll(resp.Body); e != nil {
		err = errors.Wrap(e, "jsonResp read")
	} else if e := json.Unmarshal(buf, out); e != nil {
		err = errors.Wrap(e, "jsonResp unmarshal")
	}
	return err
}
