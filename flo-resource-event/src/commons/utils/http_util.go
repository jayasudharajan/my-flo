package utils

import (
	"bytes"
	"encoding/json"
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

type HttpUtil struct {
	auth   string
	hc     *http.Client
	log    *Logger
	logErr bool
}

type HttpErr struct {
	Code    int    `json:"code,omitempty"`
	Message string `json:"message,omitempty"`
	Trace   string `json:"developer,omitempty"`
}

func (e *HttpErr) Error() string {
	if e == nil {
		return ""
	}
	return e.Message
}

func (e HttpErr) String() string {
	return TryToJson(e)
}

func CreateHttpUtil(auth string, log *Logger, timeout time.Duration) *HttpUtil {
	if timeout < 0 {
		sec, _ := strconv.Atoi(GetEnvOrDefault(ENVVAR_HTTP_TIMEOUT_S, ""))
		if sec < 0 {
			sec = 4
		}
		timeout = time.Duration(int64(sec)) * time.Second
	}
	u := HttpUtil{
		auth: auth,
		hc:   &http.Client{Timeout: timeout},
		log:  log.CloneAsChild("httpU"),
	}
	return &u
}

//chain this method on create to enable logging on error
func (p *HttpUtil) WithLogs() *HttpUtil {
	p.logErr = true
	return p
}

type StringPairs struct {
	Name  string
	Value string
}

func (p *HttpUtil) Do(method, url string, req interface{}, okStatus func(int) bool, resp interface{}, headers ...StringPairs) error {
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
	if r, e := p.jsonReq(method, url, rr, headers); e != nil {
		return e
	} else if e := p.jsonResp(r, okStatus, resp); e != nil {
		return e
	} else {
		return nil
	}
}

func (p *HttpUtil) jsonReq(method, url string, rr io.Reader, headers []StringPairs) (resp *http.Response, err error) {
	ll := LL_ERROR
	if req, e := http.NewRequest(method, url, rr); e != nil {
		err = errors.Wrap(e, "mk req")
	} else {
		if p.auth != "" {
			req.Header.Add(AUTH_HEADER, p.auth)
		}
		req.Header.Add("Content-Type", "application/json")
		for _, h := range headers {
			if h.Value == "" {
				req.Header.Del(h.Name)
			} else {
				req.Header.Add(h.Name, h.Value)
			}
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

func (p *HttpUtil) jsonResp(resp *http.Response, okStatus func(int) bool, out interface{}) (err error) {
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
				err = &he
			}
		}
		if err == nil {
			err = errors.Errorf("jsonResp %v %v | %v", resp.StatusCode, resp.Status, string(buf))
		}
	} else if out == nil {
		//do nothing
	} else if buf, e := ioutil.ReadAll(resp.Body); e != nil {
		err = errors.Wrap(e, "jsonResp read")
	} else if e := json.Unmarshal(buf, out); e != nil {
		err = errors.Wrap(e, "jsonResp unmarshal")
	}
	if err != nil && p.logErr {
		p.log.Warn(err.Error())
	}
	return err
}

func JsonMap(input, output interface{}) error {
	if input == nil {
		return errors.New("input is nil")
	} else if output == nil {
		return errors.New("output is nil")
	} else if buf, e := json.Marshal(input); e != nil {
		return e
	} else {
		return json.Unmarshal(buf, &output)
	}
}
