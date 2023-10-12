package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/pkg/errors"
)

// SEE: https://github.com/smcquay/jsonds
// SEE: https://github.com/grafana/grafana/blob/master/docs/sources/plugins/developing/datasources.md
// SEE: https://github.com/grafana/simple-json-backend-datasource

// GrafanaWebHandler api handler logic
type GrafanaWebHandler struct {
	s3Reader   *GrafanaS3FileReader
	s3MaxDur   time.Duration //max allowed hours queried via s3
	tsReader   *GrafanaTimeScaleReader
	dtDurMax   time.Duration //maximum allowed range of date per query
	columns    map[string]ColumnValue
	defaultMac string //v8: 0cae7dc5bdba" or Gabe's 2 v7: 0cae7dc582ea 0cae7dc535f9
	secret     string
	rqSyncMap  sync.Map //force duplicate request to wait so cache has a chance
	s3rmDays   int      //now - this value gives you when the s3 files are deleted (and earlier)
	s3AbsCut   time.Time
}
type ColumnValue struct {
	key   string //key name
	vtype string //value type
	ix    int    //default sort ordering
	hide  bool   //if true, do not return as a data target
}
type ColumnPair struct {
	Name  string
	Value ColumnValue
}

const ENVVAR_GRAFANA_DEFAULT_DID = "FLO_GRAFANA_DEFAULT_DID"
const ENVVAR_GRAFANA_S3_MAX_DUR = "FLO_GRAFANA_S3_MAX_DUR"
const ENVVAR_GRAFANA_S3_RM_DAYS = "FLO_GRAFANA_S3_RM_DAYS" //s3 files before this date is removed
const ENVVAR_GRAFANA_REQ_MAX_DUR = "FLO_GRAFANA_REQ_MAX_DUR"
const ENVVAR_GRAFANA_SECRET = "FLO_GRAFANA_SECRET"

func CreateGrafanaWebHandler(s3 *GrafanaS3FileReader, ts *GrafanaTimeScaleReader) *GrafanaWebHandler {
	s3MaxDur, ok := tryParseDurationEnv(ENVVAR_GRAFANA_S3_MAX_DUR, "13h")
	if !ok {
		os.Exit(10)
	}
	hrsInAYear := fmt.Sprintf("%vh", 24*93) //~3 months
	reqMaxDur, ok := tryParseDurationEnv(ENVVAR_GRAFANA_REQ_MAX_DUR, hrsInAYear)
	if !ok {
		os.Exit(10)
	}

	g := GrafanaWebHandler{
		s3Reader:   s3,
		s3MaxDur:   s3MaxDur,
		tsReader:   ts,
		dtDurMax:   reqMaxDur,
		secret:     getEnvOrDefault(ENVVAR_GRAFANA_SECRET, ""),
		defaultMac: getEnvOrDefault(ENVVAR_GRAFANA_DEFAULT_DID, ""),
		s3rmDays:   30 * 6,                                      //180
		s3AbsCut:   time.Date(2021, 6, 1, 0, 0, 0, 0, time.UTC), //NOTE: 5-18 is when we started to push data into the new path of ./tlm-{last-2-mac}/...
		columns: map[string]ColumnValue{
			"Time":          ColumnValue{key: "ts", vtype: "time", ix: 0, hide: true},
			"Device Id":     ColumnValue{key: "did", vtype: "string", ix: 1, hide: true},
			"Wifi Strength": ColumnValue{key: "rssi", vtype: "number", ix: 2, hide: true},
			"Valve State":   ColumnValue{key: "v", vtype: "number", ix: 3},
			"System Mode":   ColumnValue{key: "sm", vtype: "number", ix: 4},
			"Pressure":      ColumnValue{key: "p", vtype: "number", ix: 5},
			"Temperature":   ColumnValue{key: "t", vtype: "number", ix: 6},
			"Flow Rate":     ColumnValue{key: "wf", vtype: "number", ix: 7},
			"Used Gallons":  ColumnValue{key: "f", vtype: "number", ix: 8},
		},
	}
	if rmd, e := strconv.Atoi(getEnvOrDefault(ENVVAR_GRAFANA_S3_RM_DAYS, "")); e == nil && rmd > 31 { //min of 1 month! for safety
		g.s3rmDays = rmd
	}
	return &g
}

func (h *GrafanaWebHandler) Search(w http.ResponseWriter, r *http.Request) {
	started := time.Now()
	sq := GSearchReq{}
	if he := httpReadBody(w, r, &sq); he != nil {
		return
	}
	switch strings.ToLower(sq.Type) {
	case "", "table", "timeserie", "timeseries":
		h.searchResponseAsNames(w, sq, started)
	default:
		httpError(w, 400, "GrafanaWebHandler.Search: Bad type; supported: table, timeserie", nil)
		return
	}
	logTrace("%vms %v %v", time.Since(started).Milliseconds(), r.Method, r.URL.Path)
}

func (h *GrafanaWebHandler) searchResponseAsNames(w http.ResponseWriter, sq GSearchReq, started time.Time) {
	sr := make([]string, len(h.columns))
	j := 0
	for _, p := range h.getSortedColumnPairs() {
		if p.Value.hide {
			continue
		}
		sr[j] = p.Name
		j++
	}
	httpWrite(w, 200, sr[0:j], started)
}

func (h *GrafanaWebHandler) getSortedColumnPairs() []ColumnPair {
	res := make([]ColumnPair, len(h.columns))
	i := 0
	for k, v := range h.columns {
		res[i] = ColumnPair{Name: k, Value: v}
		i++
	}
	sort.Slice(res, func(i, j int) bool {
		return res[i].Value.ix < res[j].Value.ix
	})
	return res
}

func (h *GrafanaWebHandler) extractDeviceId(rq *GtQueryReq) (string, error) {
	if mac, err := h.extractScopeVar(rq, "did"); err == nil && isValidMacAddress(mac) {
		return strings.ToLower(mac), nil
	} else if mac, err := h.extractAdHocKey(rq, "did", ""); err == nil && isValidMacAddress(mac) {
		return strings.ToLower(mac), nil
	} else {
		if h.defaultMac == "" {
			return "", err
		} else {
			return h.defaultMac, nil //this way we always have some data when setting up a test
		}
	}
}

func (h *GrafanaWebHandler) extractSecret(rq *GtQueryReq) (string, error) {
	return h.extractScopeVar(rq, "secret")
}

func (h *GrafanaWebHandler) extractScopeVar(rq *GtQueryReq, key string) (string, error) {
	if sv, ok := rq.ScopedVars[key]; ok && sv.Text != "" {
		return sv.Text, nil
	} else {
		return "", errors.Errorf("GrafanaWebHandler.extractScopeVar: %v missing or empty", key)
	}
}

func (h *GrafanaWebHandler) extractAdHocKey(rq *GtQueryReq, key string, op string) (string, error) {
	if qf := rq.GetQueryFilter(key); qf != nil && qf.Value != "" {
		if op == "" {
			return qf.Value, nil
		} else {
			switch qf.Operator {
			case op:
				return qf.Value, nil
			default:
				return "", errors.Errorf("GrafanaWebHandler.extractAdHocKey: %v operator %v not supported", qf.Key, qf.Operator)
			}
		}
	} else {
		return "", errors.Errorf("GrafanaWebHandler.extractAdHocKey: %v missing or empty", key)
	}
}

func (h *GrafanaWebHandler) isRequestTooLarge(rq *GtQueryReq) (dtr time.Duration, ok bool) {
	dtr = rq.Range.To.Sub(rq.Range.From)
	if dtr > h.dtDurMax {
		return dtr, true
	}
	return dtr, false
}

func (h *GrafanaWebHandler) cleanDates(rq *GtQueryReq) (start time.Time, end time.Time) {
	start = rq.Range.From.UTC()
	end = rq.Range.To.UTC()
	if start.After(end) {
		start, end = end, start
	}
	start = start.Truncate(time.Minute * 5)
	end = end.Truncate(time.Minute * 5).Add(time.Minute * 5)
	return start, end
}

func (h *GrafanaWebHandler) Query(w http.ResponseWriter, r *http.Request) {
	started := time.Now()
	rq := GtQueryReq{}
	if he := httpReadBody(w, r, &rq); he != nil {
		return
	}
	mac, e := h.extractDeviceId(&rq)
	if e != nil {
		httpError(w, 400, "exactDeviceId failed: "+e.Error(), nil)
		_log.Debug("NO_DID scopeVars: %v", rq.ScopedVars)
		_log.Debug("NO_DID adHocFilters: %v", rq.AdHocFilters)
		return
	} else if h.secret != "" {
		if pwd, e := h.extractSecret(&rq); e != nil {
			httpError(w, 401, e.Error(), nil)
			return
		} else if pwd != h.secret {
			httpError(w, 403, "GrafanaWebHandler.Query: Invalid secret", nil)
			return
		}
	}
	if dtr, ok := h.isRequestTooLarge(&rq); ok {
		httpError(w, 400, fmt.Sprintf("GrafanaWebHandler.Query: Date range is too large %v. Max is %v", fmtDuration(dtr), fmtDuration(h.dtDurMax)), nil)
	}

	flat, useTs, e := h.getRange(mac, &rq)
	if e != nil {
		httpError(w, 500, e.Error(), e)
		return
	}
	var minBucketSec int64 = 1
	if useTs {
		minBucketSec = SEC_IN_5MIN
	}
	if rq.AnyTypeIs("table") {
		h.queryResponseAsTable(w, rq, flat, minBucketSec, started)
	} else {
		h.queryResponseAsTimeSeries(w, rq, flat, minBucketSec, started)
	}
	logInfo("%vs %v %v mac=%v %v - %v", float32(time.Since(started).Milliseconds())/1000, r.Method, r.URL.Path, mac, rq.Range.From.Format(DT_FORMAT_XML), rq.Range.To.Format(DT_FORMAT_XML))
}

func (h *GrafanaWebHandler) getRange(mac string, rq *GtQueryReq) (flat []TelemetryData, useTs bool, e error) {
	var (
		start, end = h.cleanDates(rq)
		s3cutOff   = time.Duration(h.s3rmDays) * DUR_1_DAY
	)
	useTs = start.Before(h.s3AbsCut) || time.Since(start).Truncate(DUR_1_DAY) > s3cutOff || end.Sub(start) > h.s3MaxDur

	sk := fmt.Sprintf("%v:%v:%v", mac, start.Unix(), end.Unix())
	sv, _ := h.rqSyncMap.LoadOrStore(sk, &sync.Mutex{}) //give cache a chance w/o slowing down unique requests
	defer h.rqSyncMap.Delete(sk)
	mx := sv.(*sync.Mutex)

	if useTs { // use timescale, faster but missing valve state & system mode
		mx.Lock()
		defer mx.Unlock()
		flat, e = h.tsReader.GetRange(mac, start, end)
		if e != nil {
			e = errors.Wrapf(e, "GrafanaWebHandler.Query: getRange ts failed %v - %v", rq.Range.From.Format(DT_FORMAT_XML), rq.Range.To.Format(DT_FORMAT_XML))
			return flat, useTs, e
		}
	} else { // use s3, all the 1s data but very slow
		var arr []S3Result
		mx.Lock()
		defer mx.Unlock()
		arr, e = h.s3Reader.GetRange(mac, start, end)
		if e != nil {
			e = errors.Wrapf(e, "GrafanaWebHandler.Query: getRange s3 failed %v - %v", rq.Range.From.Format(DT_FORMAT_XML), rq.Range.To.Format(DT_FORMAT_XML))
			return flat, useTs, e
		}
		flat = h.flattenS3Results(arr)
	}
	return flat, useTs, nil
}

func (_ *GrafanaWebHandler) flattenS3Results(arr []S3Result) []TelemetryData {
	mLen := 0
	for _, r := range arr {
		mLen += len(r.Telemetry)
	}
	raw := make([]TelemetryData, mLen)
	x := 0
	for _, r := range arr {
		for _, t := range r.Telemetry {
			raw[x] = t
			x++
		}
	}
	return raw
}

func (_ *GrafanaWebHandler) buildMapArr(rq GtQueryReq, flat []TelemetryData, minBucketSec int64) (int, []map[string]interface{}) {
	mLen := 0
	intervalSec := rq.IntervalMs / 1000
	var raw []TelemetryData
	if intervalSec > minBucketSec {
		condenseStart := time.Now()
		ta := CreateTelemetryAggregator(intervalSec)
		ta.Append(flat)
		raw = ta.Results()
		mLen = len(raw)
		logDebug("GrafanaWebHandler.buildMapArr: condensed %v -> %v rows w/ %vs interval | took %vms", ta.InputRows, mLen, intervalSec, time.Since(condenseStart).Milliseconds())
	} else {
		raw = flat
		mLen = len(raw)
	}
	mapArr := make([]map[string]interface{}, mLen)
	i := 0
	for _, t := range raw {
		var js []byte
		var e error
		if js, e = json.Marshal(t); e != nil {
			continue
		}
		m := make(map[string]interface{})
		if e = json.Unmarshal(js, &m); e != nil {
			continue
		}
		mapArr[i] = m
		i++
	}
	return i, mapArr[0:i]
}

func (h *GrafanaWebHandler) queryResponseAsTimeSeries(w http.ResponseWriter, rq GtQueryReq, flat []TelemetryData, minBucketSec int64, started time.Time) {
	mLen, mapArr := h.buildMapArr(rq, flat, minBucketSec)
	cols := make([]GtTargetResp, len(rq.Targets))
	k := 0
	for _, t := range rq.Targets {
		cl := GtTargetResp{
			Target:     t.Target,
			DataPoints: make([][]interface{}, mLen),
		}
		j := 0
		for _, m := range mapArr {
			if ts, ok := m["ts"]; ok {
				var n string
				if cd, ok := h.columns[t.Target]; !ok {
					n = t.Target
				} else {
					if cd.hide {
						continue
					}
					n = cd.key
				}
				if n == "ts" {
					continue
				}
				if v, ok := m[n]; ok {
					cl.DataPoints[j] = []interface{}{v, ts}
					j++
				}
			}
		}
		cl.DataPoints = cl.DataPoints[0:j] //trim the fat
		if len(cl.DataPoints) > 0 {
			cols[k] = cl
			k++
		}
	}
	cols = cols[0:k] //trim the fat
	httpWrite(w, 200, cols, started)
}

func (h *GrafanaWebHandler) queryResponseAsTable(w http.ResponseWriter, rq GtQueryReq, flat []TelemetryData, minBucketSec int64, started time.Time) {
	cLen := len(h.columns) //build column results
	cols := make([]GtColumn, cLen)
	z := 0
	for _, p := range h.getSortedColumnPairs() {
		if p.Value.key != "ts" && p.Value.hide {
			continue
		}
		cols[z] = GtColumn{Text: p.Name, Type: p.Value.vtype, Sort: p.Value.key == "ts"}
		z++
	}
	cols = cols[0:z]
	cLen = z

	rCount, mapArr := h.buildMapArr(rq, flat, minBucketSec) //convert to map array for column lookup
	rs := GtTableResp{
		Type:    "table",
		Columns: cols,
		Rows:    make([][]interface{}, rCount),
	}
	i := 0 //build response body
	for _, m := range mapArr {
		row := make([]interface{}, cLen)
		for j, cl := range cols {
			if cv, ok := h.columns[cl.Text]; ok {
				row[j] = m[cv.key]
			}
		}
		rs.Rows[i] = row
		i++
	}
	rs.Rows = rs.Rows[0:i] //trim the fat
	httpWrite(w, 200, []GtTableResp{rs}, started)
}

func (h *GrafanaWebHandler) Annotations(w http.ResponseWriter, r *http.Request) {
	started := time.Now()
	rq := GAnnotationReq{}
	if he := httpReadBody(w, r, &rq); he != nil {
		return
	}

	rs := GAnnotationResp{
		Annotation: rq.Annotation,
		Text:       "A user's water usage average over time",
		Time:       rq.Range.From.UTC().Unix() * 1000,
		TimeEnd:    rq.Range.To.UTC().Unix() * 1000,
	}
	httpWrite(w, 200, []GAnnotationResp{rs}, started)
	logTrace("%vms %v %v", time.Since(started).Milliseconds(), r.Method, r.URL.Path)
}

func (h *GrafanaWebHandler) TagKeys(w http.ResponseWriter, r *http.Request) {
	started := time.Now()
	rq := make(map[string]interface{})
	if he := httpReadBody(w, r, &rq); he != nil {
		return
	}

	rs := GTagKeyResp{Type: "string", Text: "did"}
	httpWrite(w, 200, []GTagKeyResp{rs}, started)
	logTrace("%vms %v %v", time.Since(started).Milliseconds(), r.Method, r.URL.Path)
}
