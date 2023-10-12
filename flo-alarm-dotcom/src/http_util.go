package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	url2 "net/url"
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
	Form(method, url string, req map[string]interface{},
		okStatus func(int, http.Header) bool, resp interface{}, headers ...StringPairs) error
	Do(method, url string, req interface{},
		okStatus func(int, http.Header) bool, resp interface{}, headers ...StringPairs) error

	WithLogs() HttpUtil
	Logger() Log
	CanLogErr() bool
}

type httpUtil struct {
	auth   string
	hc     *http.Client
	log    Log
	logErr bool
}

func CreateHttpUtil(auth string, log Log, timeout time.Duration) *httpUtil {
	return CreateHttpUtilFromClient(auth, log, timeout, nil)
}

func CreateHttpUtilFromClient(auth string, log Log, timeout time.Duration, hc *http.Client) *httpUtil {
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
		log:  log,
	}
	return &u
}

//WithLogs chain this method on create to enable logging on error
func (p *httpUtil) WithLogs() HttpUtil {
	p.logErr = true
	return p
}

func (p *httpUtil) Logger() Log {
	return p.log
}

func (p *httpUtil) CanLogErr() bool {
	return p.logErr
}

type StringPairs struct {
	Name  string
	Value string
}

const (
	contentType = "Content-Type"
	formEnc     = "application/x-www-form-urlencoded"
	jsonApp     = "application/json"
)

func (p *httpUtil) Form(method, url string, req map[string]interface{}, okStatus func(int, http.Header) bool, resp interface{}, headers ...StringPairs) error {
	frm := url2.Values{}
	for k, v := range req {
		switch arr := v.(type) {
		case []interface{}:
			for _, o := range arr {
				frm.Add(k, fmt.Sprint(o))
			}
		default:
			frm.Set(k, fmt.Sprint(v))
		}
	}
	var (
		str   = frm.Encode()
		hasCt = false
	)
	for _, h := range headers {
		if strings.EqualFold(h.Name, contentType) {
			hasCt = true
			break
		}
	}
	if !hasCt {
		headers = append(headers, StringPairs{contentType, formEnc})
	}
	return p.Do(method, url, str, okStatus, resp, headers...)
}

func (p *httpUtil) Do(method, url string, req interface{}, okStatus func(int, http.Header) bool, resp interface{}, headers ...StringPairs) error {
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
	if r, e := p.reqBuf(method, url, rr, headers); e != nil {
		return e
	} else if e = p.jsonResp(r, okStatus, resp); e != nil {
		return e
	} else {
		return nil
	}
}

func (p *httpUtil) reqBuf(method, url string, rr io.Reader, headers []StringPairs) (resp *http.Response, err error) {
	ll := LL_ERROR
	if req, e := http.NewRequest(method, url, rr); e != nil {
		err = errors.Wrap(e, "mk req")
	} else {
		if p.auth != "" {
			req.Header.Add(AUTH_HEADER, p.auth)
		}
		for _, h := range headers {
			if h.Value == "" {
				req.Header.Del(h.Name)
			} else {
				req.Header.Set(h.Name, h.Value)
			}
		}
		if cts, found := req.Header[contentType]; !found || len(cts) == 0 || cts[0] == "" {
			req.Header[contentType] = []string{jsonApp} //default to JSON content type if not known but allow overrides
		}
		if resp, e = p.hc.Do(req); e != nil {
			ll = LL_WARN
			if resp != nil {
				err = errors.Wrapf(e, "resp -> %v %v", resp.StatusCode, resp.Status)
			} else {
				err = errors.Wrapf(e, "resp -> nil")
			}
		} else if resp == nil {
			err = errors.New("resp => nil")
		}
	}
	if err != nil && p.logErr {
		p.log.Log(ll, err.Error())
	}
	return resp, err
}

func (p *httpUtil) jsonResp(resp *http.Response, okStatus func(int, http.Header) bool, out interface{}) (err error) {
	if resp == nil {
		return nil
	} else if resp.Body != nil {
		defer resp.Body.Close()
	}
	if (okStatus == nil && resp.StatusCode >= 300) || (okStatus != nil && !okStatus(resp.StatusCode, resp.Header.Clone())) {
		buf, e := ioutil.ReadAll(resp.Body)
		if e == nil { //attempts to deserialize anyway
			he := HttpErr{Code: resp.StatusCode}
			if e = json.Unmarshal(buf, &he); e == nil {
				if he.Message == "" {
					he.Message = httpCodeToRing(resp.StatusCode)
				}
				he.Trace = errors.New(string(buf))
				err = &he
			}
		}
		if err == nil {
			var (
				eStr   = string(buf)
				ct     = strings.ToLower(resp.Header.Get("Content-Type"))
				isText = false
			)
			if ct == "" {
				ct = strings.ToLower(resp.Header.Get("content-type"))
			}
			if ct == "" {
				if bl := len(eStr); bl > 2 && eStr[0] == '{' && eStr[bl-1] == '}' {
					//is json
				} else {
					isText = true
				}
			} else if !strings.Contains(ct, "json") {
				isText = true
			}
			if isText {
				eStr = strEscapeNewLines(eStr)
			}
			err = errors.Errorf("jsonResp %v %v | %v", resp.StatusCode, resp.Status, eStr)
		}
	} else if out == nil {
		//do nothing
	} else if buf, e := ioutil.ReadAll(resp.Body); e != nil {
		err = errors.Wrap(e, "jsonResp read")
	} else if bl := len(buf); bl != 0 {
		if e = json.Unmarshal(buf, out); e != nil {
			err = errors.Wrap(e, "jsonResp unmarshal")
		}
	}

	if err != nil && p.logErr {
		p.log.Warn(err.Error())
	}
	return err
}

func strEscapeNewLines(s string) string {
	if s != "" {
		s = strings.ReplaceAll(s, "\t", "\\t")
		s = strings.ReplaceAll(s, "\r", "\\r")
		s = strings.ReplaceAll(s, "\n", "\\n")
	}
	return s
}
