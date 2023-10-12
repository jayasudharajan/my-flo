package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	instana "github.com/instana/go-sensor"

	"github.com/hashicorp/go-retryablehttp"
	"github.com/labstack/gommon/log"
	"github.com/pkg/errors"
)

type httpAdaptor struct {
	client *retryablehttp.Client
}

func (og *httpAdaptor) Do(req *http.Request) (*http.Response, error) {
	if shim, e := retryablehttp.FromRequest(req); e != nil {
		e = errors.Wrap(e, "httpAdaptor.Do")
		log.Warn(e)
		return nil, e
	} else {
		return og.client.Do(shim)
	}
}

type IGenericHttpClient interface {
	Do(req *http.Request) (*http.Response, error)
}

type httpUtil struct {
	auth string
	hc   IGenericHttpClient
}

var _defaultHttpClient = &http.Client{
	Timeout: time.Second * 9,
}

func InitHttpUtilClient() {
	_defaultHttpClient.Transport = PanicWrapRoundTripper("HttpUtilClient", instana.RoundTripper(_instana, nil))
}

func CreateHttpUtil(auth string, httpClient IGenericHttpClient) *httpUtil {
	if httpClient == nil {
		httpClient = _defaultHttpClient
	}
	u := httpUtil{
		auth: auth,
		hc:   httpClient,
	}
	return &u
}

func (h *httpUtil) Do(ctx context.Context, method, url string, req interface{}, okStatus func(int) bool, resp interface{}) (uuid.UUID, error) {

	var rdr io.Reader
	if req != nil {
		switch t := req.(type) {
		case string:
			rdr = strings.NewReader(t)
		case []byte:
			rdr = bytes.NewBuffer(t)
		default:
			if buf, e := json.Marshal(req); e != nil {
				e = errors.Wrapf(e, "req json | %v", req)
				log.Error(e)
				return uuid.Nil, e
			} else {
				rdr = bytes.NewBuffer(buf)
			}
		}
	}
	if r, rid, e := h.jsonReq(ctx, method, url, rdr); e != nil {
		return rid, e
	} else if e := h.jsonResp(r, okStatus, resp); e != nil {
		return rid, e
	} else {
		return rid, nil
	}
}

func (h *httpUtil) jsonReq(ctx context.Context, method, url string, rr io.Reader) (*http.Response, uuid.UUID, error) {
	if req, e := http.NewRequestWithContext(ctx, method, url, rr); e != nil {
		e = errors.Wrap(e, "mk req")
		log.Error(e)
		return nil, uuid.Nil, e
	} else {
		var rid uuid.UUID
		if h.auth != "" {
			req.Header.Set("Authorization", h.auth)
		}
		req.Header.Add("Content-Type", "application/json")
		if uuid, e := uuid.NewUUID(); e == nil {
			req.Header.Set("x-request-id", uuid.String())
			rid = uuid
		} else {
			req.Header.Set("x-request-id", fmt.Sprintf("ux%v", time.Now().Unix()))
		}
		if resp, e := h.hc.Do(req); e != nil {
			if resp != nil {
				defer resp.Body.Close()
				e = errors.Wrapf(e, "resp -> %v %v", resp.StatusCode, resp.Status)
				log.Warn(e)
				return nil, rid, e
			} else {
				e = errors.Wrap(e, "resp -> nil")
				log.Warn(e)
				return nil, rid, e
			}
		} else if resp == nil {
			e = errors.New("resp => nil")
			log.Error(e)
			return nil, rid, e
		} else {
			return resp, rid, nil
		}
	}
}

func (_ *httpUtil) jsonResp(resp *http.Response, okStatus func(int) bool, out interface{}) error {
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
				log.Warnf("jsonResp %v %v | %v", he.Code, resp.Status, he.Message)
				return &he
			}
		}
		e = errors.Errorf("jsonResp %v %v | %v", resp.StatusCode, resp.Status, string(buf))
		log.Warn(e)
		return e
	} else if out == nil {
		return nil
	} else if buf, e := ioutil.ReadAll(resp.Body); e != nil {
		e = errors.Wrap(e, "jsonResp read")
		log.Warn(e)
		return e
	} else if e := json.Unmarshal(buf, out); e != nil {
		e = errors.Wrap(e, "jsonResp unmarshal")
		log.Warn(e)
		return e
	} else {
		return nil
	}
}

type HttpErr struct {
	Code    int    `json:"code,omitempty"`
	Message string `json:"message,omitempty"`
	Trace   string `json:"developer,omitempty"`
}

func (e *HttpErr) Error() string { //should fit generic error interface
	if e == nil {
		return ""
	}
	return e.Message
}
