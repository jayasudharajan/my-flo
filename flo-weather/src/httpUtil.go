package main

import (
	"bytes"
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"
	"time"
)

const (
	ENVVAR_HTTP_TIMEOUT_S = "FLO_HTTP_TIMEOUT_S"
)

type httpUtil struct {
	auth string
	hc   *http.Client
	log  *Logger
}

func CreateHttpUtil(auth string, log *Logger, timeout time.Duration) *httpUtil {
	if timeout < 0 {
		sec, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_HTTP_TIMEOUT_S, ""))
		if sec < 0 {
			sec = 4
		}
		timeout = time.Duration(int64(sec)) * time.Second
	}
	u := httpUtil{
		auth: auth,
		hc:   &http.Client{Timeout: timeout},
		log:  log.CloneAsChild("httpU"),
	}
	return &u
}

func (p *httpUtil) Do(method, url string, req interface{}, okStatus func(int) bool, resp interface{}) error {
	p.log.PushScope(method, url)
	defer p.log.PopScope()

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
				return p.log.IfErrorF(e, "req json | %v", req)
			} else {
				rr = bytes.NewBuffer(buf)
			}
		}
	}
	if r, e := p.jsonReq(method, url, rr); e != nil {
		return e
	} else if e := p.jsonResp(r, okStatus, resp); e != nil {
		return e
	} else {
		return nil
	}
}

func (p *httpUtil) jsonReq(method, url string, rr io.Reader) (*http.Response, error) {
	if req, e := http.NewRequest(method, url, rr); e != nil {
		return nil, p.log.IfErrorF(e, "mk req")
	} else {
		if p.auth != "" {
			req.Header.Add("Authorization", p.auth)
		}
		req.Header.Add("Content-Type", "application/json")
		if resp, e := p.hc.Do(req); e != nil {
			if resp != nil {
				return nil, p.log.IfWarnF(e, "resp -> %v %v", resp.StatusCode, resp.Status)
			} else {
				return nil, p.log.IfWarnF(e, "resp -> nil")
			}
		} else if resp == nil {
			return nil, p.log.Error("resp => nil")
		} else {
			return resp, nil
		}
	}
}

func (p *httpUtil) jsonResp(resp *http.Response, okStatus func(int) bool, out interface{}) error {
	if resp == nil {
		return nil
	} else if resp.Body != nil {
		defer resp.Body.Close()
	}

	if (okStatus == nil && resp.StatusCode >= 300) || (okStatus != nil && !okStatus(resp.StatusCode)) {
		buf, e := ioutil.ReadAll(resp.Body)
		if e == nil { //attempts to deserialize anyway
			he := HttpErr{Code: resp.StatusCode}
			if e := json.Unmarshal(buf, &he); e == nil {
				p.log.Warn("jsonResp %v %v | %v", he.Code, resp.Status, he.Message)
				return &he
			}
		}
		return p.log.Warn("jsonResp %v %v | %v", resp.StatusCode, resp.Status, string(buf))
	} else if out == nil {
		return nil
	} else if buf, e := ioutil.ReadAll(resp.Body); e != nil {
		return p.log.IfWarnF(e, "jsonResp read")
	} else if e := json.Unmarshal(buf, out); e != nil {
		return p.log.IfWarnF(e, "jsonResp unmarshal")
	} else {
		return nil
	}
}
