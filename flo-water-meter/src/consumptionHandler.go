package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"sort"
	"strings"
	"sync/atomic"
	"time"

	"github.com/gorilla/mux"
)

type ConsumptionRequest struct {
	MacAddressList []string `json:"macAddressList,omitempty"`
	StartDate      string   `json:"startDate,omitempty"`
	EndDate        string   `json:"endDate,omitempty"`
	Interval       string   `json:"interval,omitempty"`
	TimeZone       string   `json:"tz,omitempty"`
	realFrom       time.Time
	realTo         time.Time
	realTimezone   *time.Location
	HideMissing    bool `json:"hideMissing,omitempty"`
}

type ConsumptionResponse struct {
	Params RequestModel   `json:"params"`
	Items  []*ReportModel `json:"items"`
}

type RequestModel struct {
	MacAddressList []string `json:"macAddressList"`
	StartDate      string   `json:"startDate,omitempty"`
	EndDate        string   `json:"endDate,omitempty"`
	Interval       string   `json:"interval,omitempty"`
	TimeZone       string   `json:"timezone,omitempty"`
}

type ReportModel struct {
	MacAddress string        `json:"macAddress,omitempty"`
	Items      []*WaterUsage `json:"items"`
}

type WaterUsage struct {
	Date    time.Time `json:"date"`
	Used    float64   `json:"used,omitempty"`
	Rate    float64   `json:"rate"`
	PSI     float64   `json:"psi,omitempty"`
	Temp    float64   `json:"temp,omitempty"`
	Missing bool      `json:"missing,omitempty"`
}

type SourceReq struct {
	MacAddress string    `json:"macAddress"`
	StartDate  time.Time `json:"startDate"`
	EndDate    time.Time `json:"endDate"`
}

func (s *SourceReq) ParseRequest(r *http.Request) error {
	var (
		vars    = mux.Vars(r)
		queries = r.URL.Query()
	)
	if s.MacAddress = vars["id"]; !isValidMacAddress(s.MacAddress) {
		return errors.New("macAddress is invalid: " + s.MacAddress)
	} else if startArg, ok := queries["startDate"]; !ok || len(startArg) == 0 {
		return errors.New("startDate is required")
	} else if s.StartDate, _ = time.ParseInLocation("2006-01-02T15:04:05Z", startArg[0], time.UTC); s.StartDate.Year() < 2000 {
		return errors.New("startDate is invalid: " + startArg[0])
	} else if endArg, ok := queries["endDate"]; !ok || len(endArg) == 0 {
		return errors.New("endDate is required")
	} else if s.EndDate, _ = time.ParseInLocation("2006-01-02T15:04:05Z", endArg[0], time.UTC); s.EndDate.Year() < 2000 {
		return errors.New("endDate is invalid: " + endArg[0])
	} else {
		s.StartDate = s.StartDate.UTC()
		s.EndDate = s.EndDate.UTC()
		return nil
	}
}

type SourceResp struct {
	Params  *SourceReq    `json:"params"`
	Results []*WaterUsage `json:"results"`
}

// Fetch data from the source: TimeScaleDB
func getSrcDataHandler(w http.ResponseWriter, r *http.Request) {
	var (
		start = time.Now()
		req   = SourceReq{}
	)
	if err := req.ParseRequest(r); err != nil {
		httpError(w, 400, err.Error(), nil)
	} else if res, e := tsWaterReader.GetWaterHourly(req.MacAddress, req.StartDate, req.EndDate, true); e != nil {
		if strings.Contains("not found", strings.ToLower(e.Error())) {
			httpError(w, 404, "macAddress not found: "+req.MacAddress, e)
		} else {
			httpError(w, 500, "something went wrong", e)
		}
	} else {
		resp := SourceResp{&req, make([]*WaterUsage, 0, len(res))}
		for _, r := range res {
			if o := r.ToWaterUsage(); o != nil {
				resp.Results = append(resp.Results, o)
			}
		}
		httpWrite(w, 200, &resp, start)
	}
}

var _httpUtil *httpUtil

func init() {
	_httpUtil = CreateHttpUtil("", time.Second*9)
}

type TokenInfo struct {
	IsActive bool   `json:"is_active"`
	IsAdmin  bool   `json:"is_system_user"`
	Email    string `json:"email"`
	Id       string `json:"id"`
}

func checkAdminToken(r *http.Request) error {
	if auth := r.Header.Get(AUTH_HEADER); auth == "" {
		return errors.New("missing auth header")
	} else if strings.Count(auth, ".") != 2 {
		return errors.New("jwt missing 3 parts")
	} else if root := getEnvOrDefault("FLO_API_URL", ""); strings.Index(root, "http") != 0 {
		return errors.New("FLO_API_URL env var is missing")
	} else {
		var (
			tk  = TokenInfo{}
			ap  = StringPairs{AUTH_HEADER, auth}
			url = fmt.Sprintf("%s/api/v1/users/me", root)
		)
		if e := _httpUtil.Do("GET", url, nil, nil, &tk, ap); e != nil {
			return e
		} else if !(tk.IsAdmin && tk.IsActive && tk.Id != "" && strings.Contains(tk.Email, "@")) {
			return errors.New("admin token is not supplied or is invalid")
		}
	}
	return nil
}

func parseRemoveDataReq(w http.ResponseWriter, r *http.Request) *RemoveDataReq {
	if e := checkAdminToken(r); e != nil {
		httpError(w, 401, "admin token required: "+e.Error(), e)
		return nil
	}
	var (
		vars = mux.Vars(r)
		rq   = RemoveDataReq{DryRun: true}
	)
	if macAddr, ok := vars["id"]; !ok {
		httpError(w, 400, "id is not found in path", nil)
		return nil
	} else if !isValidMacAddress(macAddr) {
		httpError(w, 400, "id is not a valid macAddr: "+macAddr, nil)
		return nil
	} else if e := httpReadBody(w, r, &rq); e != nil {
		return nil
	} else if !(rq.StartDate.Year() > 2000 || rq.EndDate.Year() > 2000) {
		httpError(w, 400, "a valid start or end date is required", nil)
		return nil
	} else {
		rq.MacAddr = macAddr
		if rq.StartDate.Year() < 2000 {
			rq.StartDate, _ = time.Parse(FMT_DAY_ONLY, "2015-01-01")
		}
		if rq.EndDate.Year() < 2000 {
			rq.EndDate = time.Now().UTC()
		}
		return &rq
	}
}

type RemoveDataRes struct {
	Params       *RemoveDataReq `json:"params"`
	SqlRowsRm    int            `json:"sqlRowsRem"`
	CacheItemsRm int            `json:"cacheItemsRem"`
	Status       string         `json:"status"`
}

func (r RemoveDataRes) String() string {
	return tryToJson(r)
}

func removeOldDataHandler(w http.ResponseWriter, r *http.Request) {
	var (
		started = time.Now()
		match   = r.URL.Query().Get("match")
		wc      = CreateWaterCacheWriter(_cache, _log.CloneAsChild("HNDLR"))
	)
	go wc.RemoveOldCache(match)
	httpWrite(w, 202, nil, started)
}

func removeDataHandler(w http.ResponseWriter, r *http.Request) {
	var (
		start = time.Now()
		rq    = parseRemoveDataReq(w, r)
		res   = RemoveDataRes{Params: rq}
		code  = 200
	)
	if rq == nil {
		return
	}
	if rq.DryRun {
		code = 202
	}
	if atomic.LoadInt32(&kfWaterConsumer.state) == 0 {
		kfWaterConsumer.writer.Open() //force open, just in case it's not
	}
	if n, e := kfWaterConsumer.writer.Remove(rq); e != nil { //remove data from TSDB first
		httpError(w, 500, "removeDataHandler: failed", e)
		return
	} else { //continue to remove all the redis data
		res.SqlRowsRm = n
		wc := CreateWaterCacheWriter(_cache, _log.CloneAsChild("Hndlr"))
		if res.CacheItemsRm, e = wc.Remove(rq); e != nil {
			res.Status = e.Error()
			code = 500
		} else {
			res.Status = "OK"
		}
		if !rq.DryRun {
			ll := LL_NOTICE
			if code >= 400 {
				ll = LL_WARN
			}
			_log.Log(ll, "removeDataHandler: %v | %v", time.Since(start).String(), res)
		}
		httpWrite(w, code, &res, start)
	}
}

func consumptionHandler(w http.ResponseWriter, r *http.Request) {
	startReqTime := time.Now()
	req := parseRequest(r)
	if err := req.Validate(); err != nil {
		httpError(w, 400, err.Error(), nil)
		return
	}

	if rv, err := _report.Consumption(&req); rv == nil {
		httpError(w, 500, "Something went wrong", err)
	} else {
		if req.HideMissing {
			for _, o := range rv.Items {
				filter := make([]*WaterUsage, 0, len(o.Items))
				for _, u := range o.Items {
					if !u.Missing {
						filter = append(filter, u)
					}
				}
				o.Items = filter
			}
		}
		httpWrite(w, 200, rv, startReqTime)
	}
}

func parseRequest(r *http.Request) ConsumptionRequest {
	if r == nil {
		return ConsumptionRequest{}
	}

	model := ConsumptionRequest{}
	values := r.URL.Query()
	model.MacAddressList = parseMacAddressList(values["macAddress"])
	model.Interval = strings.TrimSpace(strings.ToLower(strings.Join(values["interval"], "")))
	model.HideMissing = strings.EqualFold(strings.Join(values["hideMissing"], ""), "true")

	if len(model.MacAddressList) > 1 {
		sort.Strings(model.MacAddressList)
	}

	startDateStr := strings.Join(values["startDate"], ",")
	endDateStr := strings.Join(values["endDate"], ",")
	model.realFrom = tryParseDate(startDateStr).Truncate(time.Hour)
	model.realTo = tryParseDate(endDateStr).Truncate(time.Hour)

	now := time.Now().UTC().Truncate(time.Minute)
	if model.realTo.After(now) {
		model.realTo = now
	}

	// Timezone Parsing
	tzString := strings.Join(values["tz"], "")
	if len(tzString) > 0 {
		tz, err := time.LoadLocation(tzString)
		if err != nil {
			logWarn("parseRequest: Unable to parse timezone '%v'. %v", tzString, err.Error())
			model.realTimezone = time.UTC
		} else {
			model.realTimezone = tz
		}
	} else {
		model.realTimezone = time.UTC
	}

	const FMT_NO_TZ = "2006-01-02T15:04:05"
	convLocal := model.realTimezone != time.UTC && !(strings.Contains(startDateStr, "Z") || strings.Contains(endDateStr, "Z"))
	if model.realFrom.Year() < 1900 {
		model.realFrom = time.Now().UTC().Truncate(24 * time.Hour)
	} else if convLocal { //face value in tz provided
		model.realFrom, _ = time.ParseInLocation(FMT_NO_TZ, model.realFrom.Format(FMT_NO_TZ), model.realTimezone)
	}
	if model.realTo.Year() < 1900 {
		model.realTo = time.Now().UTC().Truncate(time.Hour * 24).Add(time.Hour * 24)
	} else if convLocal { //face value in tz provided
		model.realTo, _ = time.ParseInLocation(FMT_NO_TZ, model.realTo.Format(FMT_NO_TZ), model.realTimezone)
	}

	model.StartDate = model.realFrom.Format(time.RFC3339)
	model.EndDate = model.realTo.Format(time.RFC3339)

	diff := model.realTo.Sub(model.realFrom)
	switch model.Interval {
	case "1d":
		// Do nothing
	case "1h":
		// Do nothing
	case "1m":
		// Do nothing
	case "":
		if diff.Hours() <= 24*7 {
			model.Interval = "1h"
		} else {
			model.Interval = "1d"
		}
	}
	if model.Interval != "1m" && diff.Hours() >= 24*31*13 {
		model.Interval = "1m"
	} else if model.Interval != "1d" && diff.Hours() >= 24*31*3 {
		model.Interval = "1d"
	}
	return model
}

func (req *ConsumptionRequest) Validate() error {
	if len(req.MacAddressList) == 0 {
		return errors.New("macAddress query param is missing or invalid")
	}

	earliestDate := time.Now().Add(time.Duration((MAX_DAYS_REPORT-1)*24*-1) * time.Hour).Truncate(time.Hour * 24)
	latestDate := time.Now().Add(time.Hour * 24 * 31).Truncate(time.Minute)

	if req.realFrom.Before(earliestDate) || req.realFrom.After(latestDate) {
		return errors.New(
			fmt.Sprintf("startDate query param is missing or invalid, valid range is %v to %v",
				earliestDate.Format("2006-01-02"),
				latestDate.Format("2006-01-02"),
			),
		)
	}

	if req.realTo.Before(earliestDate) || req.realTo.After(latestDate) {
		return errors.New(
			fmt.Sprintf("endDate query param is missing or invalid, valid range is %v and %v",
				earliestDate.Format("2006-01-02"),
				latestDate.Format("2006-01-02"),
			),
		)
	}

	if req.realFrom.After(req.realTo) || req.realFrom.Equal(req.realTo) {
		return errors.New(
			fmt.Sprintf("startDate cannot be equal or after endDate, start=%v end=%v",
				req.realFrom.Format(time.RFC3339),
				req.realTo.Format(time.RFC3339),
			),
		)
	}

	if !strings.EqualFold(req.Interval, "1h") &&
		!strings.EqualFold(req.Interval, "1d") &&
		!strings.EqualFold(req.Interval, "1m") {
		return errors.New(
			fmt.Sprintf("interval query param is invalid, valid options are '' or '1h' or '1d' or '1m', provided %v",
				req.Interval,
			),
		)
	}

	return nil
}

func parseMacAddressList(arrayOfCsv []string) []string {
	cleanList := make([]string, 0)
	delta := parseListAndCsv(arrayOfCsv)

	if len(delta) == 0 {
		return cleanList
	}

	for _, d := range delta {
		clean := strings.TrimSpace(strings.ToLower(d))
		if len(clean) == 12 {
			cleanList = append(cleanList, clean)
		}
	}

	return cleanList
}

type LastReq struct {
	MacAddress []string `json:"macAddress,omitempty"`
}

func (r *LastReq) ParseRequest(h *http.Request) error {
	if query := h.URL.Query(); query == nil {
		return errors.New("macAddress is required")
	} else if rawMacs, ok := query["macAddress"]; !ok || len(rawMacs) == 0 {
		return errors.New("macAddress is missing")
	} else if cleanMacs := parseMacAddressList(rawMacs); len(cleanMacs) == 0 {
		return errors.New("no valid macAddress provided")
	} else {
		sort.Strings(cleanMacs)
		r.MacAddress = cleanMacs
	}
	return nil
}

type LatestResp struct {
	Params  *LastReq           `json:"params,omitempty"`
	Now     string             `json:"now,omitempty"`
	Devices []*LatestTelemetry `json:"devices,omitempty"`
}

type LatestTelemetry struct {
	MacAddress string    `json:"macAddress"`
	TimeStamp  time.Time `json:"timestamp"`
	GPS        float32   `json:"gps,omitempty"`
	PSI        float32   `json:"psi,omitempty"`
	TempF      float32   `json:"tempF,omitempty"`
	ValveState int32     `json:"valveState"`
	SystemMode int32     `json:"systemMode"`
}

func (l *LatestTelemetry) redisKey() string {
	k := strings.ToLower(fmt.Sprintf("telemetry:{%v}:latest", l.MacAddress))
	if _log.isDebug && _noWrite {
		k += ":debug"
	}
	return k
}

func latestTelemetryHandler(w http.ResponseWriter, r *http.Request) {
	var (
		started = time.Now()
		req     = LastReq{}
	)
	if e := req.ParseRequest(r); e != nil {
		httpWrite(w, 400, e.Error(), started)
		return
	}
	var (
		res = LatestResp{Params: &req, Devices: make([]*LatestTelemetry, 0, len(req.MacAddress))}
		es  = make([]error, 0)
	)
	for _, macAddress := range req.MacAddress {
		var (
			t   = LatestTelemetry{MacAddress: strings.ToLower(macAddress)}
			k   = t.redisKey()
			cmd = _cache._client.ZRevRange(k, 0, 0)
		)
		if arr, e := cmd.Result(); e != nil {
			if e.Error() != "redis: nil" {
				es = append(es, _log.IfWarnF(e, "latestTelemetryHandler: ZRevRange %v", k))
			}
		} else if len(arr) != 0 && len(arr[0]) != 0 && arr[0][0] == '{' {
			if e = json.Unmarshal([]byte(arr[0]), &t); e != nil {
				es = append(es, _log.IfWarnF(e, "latestTelemetryHandler: json.Unmarshal %v", k))
			} else {
				res.Devices = append(res.Devices, &t)
			}
		}
	}
	res.Now = time.Now().UTC().Format(FMT_RED_MAP_LASTDT)
	httpWrite(w, 200, &res, started)
}

type aggRefreshReq struct {
	From string `json:"from,omitempty"`
	To   string `json:"to,omitempty"`
}

func (a *aggRefreshReq) FromDt() time.Time {
	if a != nil && a.From != "" {
		return tryParseDate(a.From)
	}
	return time.Time{}
}

func (a *aggRefreshReq) ToDt() time.Time {
	if a != nil && a.To != "" {
		return tryParseDate(a.To)
	}
	return time.Time{}
}

func (a *aggRefreshReq) Validate() error {
	if a == nil {
		return errors.New("nil binding")
	} else if frm := a.FromDt(); frm.Year() < 2000 {
		return errors.New("invalid from date")
	} else if !a.ToDt().After(frm) {
		return errors.New("invalid to date")
	}
	return nil
}

func aggRefresh(w http.ResponseWriter, r *http.Request) {
	var (
		started = time.Now()
		req     = aggRefreshReq{}
	)
	if e := httpReadBody(w, r, &req); e != nil { //preflight checks
		return
	}
	if e := req.Validate(); e != nil {
		httpError(w, 400, e.Error(), e)
		return
	}
	if kfWaterConsumer == nil || kfWaterConsumer.writer == nil {
		httpError(w, 503, "dependency missing", nil)
		return
	}

	if !kfWaterConsumer.writer.IsOpen() {
		kfWaterConsumer.writer.Open()
	}
	if e := kfWaterConsumer.writer.RefreshHourlyAggregates(req.FromDt(), req.ToDt()); e != nil {
		httpError(w, 500, e.Error(), e)
	} else {
		httpWrite(w, 204, nil, started)
	}
}
