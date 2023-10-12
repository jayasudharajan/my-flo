package main

import (
	"strings"
	"time"
)

// SEE: https://github.com/grafana/grafana/blob/master/docs/sources/plugins/developing/datasources.md
// SEE: https://github.com/grafana/simple-json-backend-datasource

// GtQueryReq Timeseries Query Request
type GtQueryReq struct {
	PanelId int64   `json:"panelId,omitempty"`
	Range   GtRange `json:"range"`
	//RangeRaw      map[string]interface{} `json:"rangeRaw,omitempty"`
	Targets       []GtTarget            `json:"targets"`
	IntervalMs    int64                 `json:"intervalMs"`
	Interval      string                `json:"interval,omitempty"`
	MaxDataPoints int64                 `json:"maxDataPoints,omitempty"`
	Format        string                `json:"format,omitempty"`
	AdHocFilters  []GtAdHocFilter       `json:"adhocFilters,omitempty"`
	ScopedVars    map[string]GtScopeVar `json:"scopedVars,omitempty"`
}
type GtScopeVar struct {
	Text  string      `json:"text,omitempty"`
	Value interface{} `json:"value,omitempty"`
}
type GtAdHocFilter struct {
	Key      string `json:"key"`
	Operator string `json:"operator"`
	Value    string `json:"value"`
}
type GtRange struct {
	From time.Time              `json:"from"`
	To   time.Time              `json:"to"`
	Raw  map[string]interface{} `json:"raw,omitempty"`
}
type GtTarget struct {
	Target string      `json:"target"`
	RefId  string      `json:"refId,omitempty"`
	Type   string      `json:"type,omitempty"` // timeseries | table
	Data   interface{} `json:"data,omitempty"`
}

func (rq *GtQueryReq) GetQueryFilter(key string) *GtAdHocFilter {
	if rq == nil || key == "" {
		return nil
	}
	for _, f := range rq.AdHocFilters {
		if f.Key == key {
			return &f
		}
	}
	return nil
}

func (rq *GtQueryReq) AnyTypeIs(tn string) bool {
	if rq == nil || tn == "" || len(rq.Targets) == 0 {
		return false
	}
	for _, t := range rq.Targets {
		if strings.ToLower(t.Type) == tn {
			return true
		}
	}
	return false
}

// GtTargetResp Timeseries Response
type GtTargetResp struct { //NOTE: Grafana Timeserie Query Response is []GtTargetResp
	Target     string          `json:"target"`
	DataPoints [][]interface{} `json:"datapoints"`
}
type GtTableResp struct { //NOTE: if GtQueryReq.Targets[i].Type == "table", Response is []GtTableResp
	Columns []GtColumn      `json:"columns"`
	Rows    [][]interface{} `json:"rows"`
	Type    string          `json:"type,omitempty"`
}
type GtColumn struct {
	Text string `json:"text"`
	Type string `json:"type"`
	Sort bool   `json:"sort,omitempty"`
	Desc bool   `json:"desc,omitempty"`
}

// GAnnotationReq Annotation Request
type GAnnotationReq struct {
	Range      GtRange                `json:"range,omitempty"`
	RangeRaw   map[string]interface{} `json:"rangeRaw,omitempty"`
	Annotation GAnnotation            `json:"annotation,omitempty"`
	Dashboard  map[string]interface{} `json:"dashboard,omitempty"`
}
type GAnnotation struct {
	Name       string `json:"name"`
	DataSource string `json:"dataSource"`
	IconColor  string `json:"iconColor,omitempty"`
	Enable     bool   `json:"enable,omitempty"`
	Query      string `json:"query,omitempty"`
}

// GAnnotationResp Annotation Response. NEED: CORS
/*
Access-Control-Allow-Headers:accept, content-type
Access-Control-Allow-Methods:POST
Access-Control-Allow-Origin:*
*/
type GAnnotationResp struct {
	Annotation GAnnotation `json:"annotation,omitempty"`
	Time       int64       `json:"time,omitempty"`
	TimeEnd    int64       `json:"timeEnd,omitempty"` // required if isRegion == true
	Title      string      `json:"title,omitempty"`
	Text       string      `json:"text,omitempty"`
	Tags       []string    `json:"tags,omitempty"`
	IsRegion   bool        `json:"isRegion,omitempty"`
}
type GSearchReq struct { // NOTE: response can simply be []string or []GSearchObjResp {Text:"",Value:any}
	Type   string `json:"type,omitempty"`
	Target string `json:"target,omitempty"`
}

type GTagKeyResp struct { //NOTE: request is an empty JSON
	Type string `json:"type,omitempty"`
	Text string `json:"text,omitempty"`
}

type GTagValueReq struct {
	Key string `json:"key,omitempty"`
}
type GTagValueResp struct { //NOTE: response is []GTagValueResp
	Text string `json:"text,omitempty"`
}
