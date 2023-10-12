package main

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/go-querystring/query"
)

const (
	ENVVAR_DEV_API = "FLO_DEV_API"
	ENVVAR_DEV_JWT = "FLO_DEV_JWT"
)

type deviceSvc struct {
	uri       string
	http      *httpUtil
	validator *Validator
	log       *Logger
}

func CreateDeviceSvc(validator *Validator, log *Logger) *deviceSvc {
	d := deviceSvc{
		validator: validator,
		uri:       getEnvOrDefault(ENVVAR_DEV_API, ""),
		log:       log.CloneAsChild("dev"),
	}
	if strings.Index(d.uri, "http") != 0 {
		d.log.Fatal("CreateDeviceSvc: invalid %v=%v", ENVVAR_DEV_API, d.uri)
		return nil
	}
	d.http = CreateHttpUtil(getEnvOrDefault(ENVVAR_DEV_JWT, ""), d.log, 0)
	return &d
}

type TailDeviceReq struct {
	DeviceId string `json:"deviceId,omitempty" url:"deviceId,omitempty" validate:"omitempty,len=12,hexadecimal"`
	Limit    int    `json:"limit,omitempty" url:"limit,omitempty" validate:"omitempty,min=1,max=500"`
}

func (t *TailDeviceReq) Normalize() *TailDeviceReq {
	if t.Limit < 1 {
		t.Limit = 100
	} else if t.Limit > 500 {
		t.Limit = 500
	}
	return t
}

// return batch of DeviceSummary for this request, if the end is reached, lastRowFetched will be set to true
type TailDeviceResp struct {
	Params         TailDeviceReq    `json:"params"`            //what was requested & cleaned by API
	LastRowFetched bool             `json:"lastRowFetched"`    //true if we've reach the end, effectively an EOF signal
	Devices        []*DeviceSummary `json:"devices,omitempty"` //what was found for the batch of data.  Client can also check for empty as a fail-safe for the above EOF
}

type DeviceSummary struct {
	DeviceId    string `json:"deviceId"`
	IsConnected bool   `json:"isConnected,omitempty"`
	IsInstalled bool   `json:"isInstalled,omitempty"`
	Make        string `json:"make,omitempty"`
	Model       string `json:"model,omitempty"`
}

func (p *deviceSvc) TailSummary(arg *TailDeviceReq) (*TailDeviceResp, error) {
	started := time.Now()
	p.log.PushScope("Tail")
	defer p.log.PopScope()

	if e := p.validator.Struct(arg.Normalize()); e != nil {
		return nil, p.log.IfWarnF(e, "arg validation failed")
	} else if ps, e := query.Values(arg); e != nil {
		return nil, p.log.IfWarnF(e, "arg param gen failed")
	} else {
		url := fmt.Sprintf("%v/v1/device-summary/tail?%v", p.uri, ps.Encode())
		res := TailDeviceResp{}
		if e := p.http.Do("GET", url, nil, nil, &res); e != nil {
			return nil, e
		} else {
			p.log.Debug("%vms found %v | %v", time.Since(started).Milliseconds(), len(res.Devices), res.Params)
			return &res, nil
		}
	}
}

type DeviceMacAddrBatch struct {
	Ids     []string
	HasMore bool
	LastId  string
}

func (p *deviceSvc) NextFlowDeviceIds(lastId string) (*DeviceMacAddrBatch, error) {
	p.log.PushScope("NextIds")
	defer p.log.PopScope()

	arg := TailDeviceReq{DeviceId: lastId, Limit: 500}
	if tr, e := p.TailSummary(&arg); e != nil {
		return nil, e
	} else {
		res := DeviceMacAddrBatch{
			HasMore: !tr.LastRowFetched && len(tr.Devices) != 0,
			Ids:     make([]string, 0),
		}
		for _, d := range tr.Devices {
			if strings.Index(d.Model, "flo_device_") == 0 && (d.IsConnected || d.IsInstalled) {
				res.Ids = append(res.Ids, d.DeviceId)
			}
			res.LastId = d.DeviceId
		}
		return &res, nil
	}
}

func (p *deviceSvc) Ping() error {
	e := p.http.Do("GET", p.uri+"/ping", nil, nil, nil)
	return p.log.IfWarnF(e, "Ping")
}
