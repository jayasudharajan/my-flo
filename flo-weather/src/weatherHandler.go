package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"sort"
	"strings"
	"sync/atomic"
	"time"

	"github.com/mmcloughlin/geohash"
)

type IWeatherHandler interface {
	AddressTemp(w http.ResponseWriter, r *http.Request)
	GeoTemp(w http.ResponseWriter, r *http.Request)

	fetchAddr(req *AddressReq) (*TempHistoryResp, error)
	fetchCoords(req *GeoCodeReq) (*TempHistoryResp, error)
}

type weatherHandler struct {
	web         *WebServer
	weather     IWeatherSource
	repo        IWeatherRepository
	preCsh      func(loc *Location, cachePolicy string) error
	geo         IGeoCoderCache
	log         *Logger
	cacheOnly   bool //if true, we ONLY serve from cache, meant for roll out & empty cache builds + system protection
	swapCurTemp bool //if true, will replace current temp with last temp in collection returned if element matches now
}

const (
	ENVVAR_CACHE_ONLY    = "FLO_CACHE_ONLY"
	ENVVAR_SWAP_CUR_TEMP = "FLO_SWAP_CUR_TEMP"
)

var _handlerCacheOnlyWarn int32 = 0

func CreateWeatherHandler(
	ws *WebServer,
	geo IGeoCoderCache,
	weather IWeatherSource,
	repo IWeatherRepository,
	preCsh func(l *Location, policy string) error,
	log *Logger,
) *weatherHandler {

	h := weatherHandler{
		web:         ws,
		geo:         geo,
		weather:     weather,
		repo:        repo,
		preCsh:      preCsh,
		log:         log.CloneAsChild("Hndlr"),
		cacheOnly:   strings.EqualFold(getEnvOrDefault(ENVVAR_CACHE_ONLY, ""), "true"),
		swapCurTemp: strings.EqualFold(getEnvOrDefault(ENVVAR_SWAP_CUR_TEMP, ""), "true"),
	}
	if atomic.CompareAndSwapInt32(&_handlerCacheOnlyWarn, 0, 1) {
		h.log.Notice("%v=%v", ENVVAR_CACHE_ONLY, h.cacheOnly)
		h.log.Notice("%v=%v", ENVVAR_SWAP_CUR_TEMP, h.swapCurTemp)
	}
	return &h
}

func (h *weatherHandler) toParams(v interface{}) map[string]interface{} {
	js, e := json.Marshal(&v)
	if e != nil {
		return nil
	}
	r := map[string]interface{}{}
	e = json.Unmarshal(js, &r)
	if e != nil {
		h.log.IfWarn(e)
		return nil
	}
	return r
}

func (h *weatherHandler) GeoTemp(w http.ResponseWriter, r *http.Request) {
	if h == nil {
		return
	}
	h.log.PushScope("GeoTemp")
	defer h.log.PopScope()

	req := new(GeoCodeReq)
	he := h.web.HttpReadQuery(w, r, req)
	if he != nil {
		return
	} else {
		req.NormalizeDates()
	}
	resp, _ := h.fetchCoords(req)
	h.web.HttpWrite(w, 200, resp)
}

func (h *weatherHandler) fetchCoords(req *GeoCodeReq) (*TempHistoryResp, error) {
	h.log.PushScope("coords")
	defer h.log.PopScope()

	var rr IReq = req
	og := &ogData{Start: rr.StartDt(), End: rr.EndDt()}
	if !req.UseLocalDt {
		og.Start, og.End = rr.OverFetchForUTC()
	}

	var l *Location //fetch & cache location data
	if geoRes, e := h.geo.Code(&Location{_lat: &req.Lat, _lon: &req.Lon}, req.Cache); e == nil && len(geoRes) != 0 {
		l = geoRes[0]
		if cacheOkRead(rr.CachePolicy()) { //attempt cache fetch
			cached, e := h.tryCache(rr, og, geoRes)
			if e == nil && cached != nil {
				if h.preCsh != nil && cacheForcedWrite(rr.CachePolicy()) { //force cache rebuild
					go h.preCsh(l, rr.CachePolicy())
				}
				return cached, e //cache OK!
			}
		}
	} else {
		return h.makeHistResp(rr, og), nil
	}
	fetchSrc := func() (*WeatherRes, error) { //fetch everything from source & cache res. SLOW!
		return h.weather.HistoricalRangeByCoordinates(req)
	}
	return h.rangeFrmSrc(rr, og, l, fetchSrc)
}

func (h *weatherHandler) AddressTemp(w http.ResponseWriter, r *http.Request) {
	if h == nil {
		return
	}
	h.log.PushScope("AddressTemp")
	defer h.log.PopScope()

	req := new(AddressReq)
	he := h.web.HttpReadQuery(w, r, req)
	if he != nil {
		return
	} else {
		req.NormalizeDates()
		req.NormalizeAddress()
	}
	resp, _ := h.fetchAddr(req)
	h.web.HttpWrite(w, 200, resp)
}

type LocSort struct {
	Loc   *Location
	Index int
}

func (h *weatherHandler) normalizeCoords(geoRes []*Location) []*Location {
	if len(geoRes) < 2 {
		return geoRes
	}
	lm := make(map[string]LocSort)
	for i, l := range geoRes {
		if !l.ValidLatLon() {
			continue
		}
		k5 := geohash.EncodeWithPrecision(float64(l.Lat()), float64(l.Lon()), 5)
		if _, ok := lm[k5]; !ok {
			lm[k5] = LocSort{l, i}
		}
	}
	sortable := make([]LocSort, len(lm))
	j := 0
	for _, v := range lm {
		sortable[j] = v
		j++
	}
	sort.Slice(sortable, func(i, j int) bool {
		return sortable[i].Index < sortable[j].Index
	})
	res := make([]*Location, len(sortable))
	for i, v := range sortable {
		res[i] = v.Loc
	}
	return res
}

func (h *weatherHandler) coordsCache(rr IReq, og *ogData, l *Location) (cached *TempHistoryResp, err error) {
	if h == nil {
		return nil, BOUND_REF_NIL
	}
	h.log.PushScope("coords$")
	defer h.log.PopScope()

	if cached, err = h.repo.FetchCoords(l.Lat(), l.Lon(), rr); err != nil {
		return nil, err
	}
	cached.Location.Combine(l)
	if !cached.isInvalid() {
		cached.Items = h.cleanResults(og, rr, cached.Location.TimeZone, cached.Items)
		h.appendCurrentTemp(rr, og, l, cached)

		cached.Params = h.makeHistResp(rr, og).Params
		cached.Params["cache"] = "partial"
		if h.isResComplete(rr, og, cached.Location.TimeZone, cached.Items) {
			cached.Params["cache"] = "full"
		}
		return cached, nil
	} else if cached != nil && cached.Current == 0 {
		h.appendCurrentTemp(rr, og, l, cached)
		cached.Params = h.makeHistResp(rr, og).Params
		cached.Params["cache"] = "partial"
		if cached.Current == 0 {
			cached.Params["cache"] = "missing"
		}
	}
	return cached, err
}

type partialRes struct {
	Candidate []*TempTime
	Location  *Location
	Cached    *TempHistoryResp
}

func (h *weatherHandler) nearbyCache(rr IReq, og *ogData, regMap map[string][]*Location) (*partialRes, error) {
	if h == nil {
		return nil, BOUND_REF_NIL
	}
	if len(regMap) == 0 {
		return nil, errors.New("regMap input empty")
	}
	h.log.PushScope("near$")
	defer h.log.PopScope()

	var (
		es = make([]error, 0)
		e  error
		pr = partialRes{}
	)
	for k, locs := range regMap {
		if len(locs) == 0 {
			continue
		}
		l := locs[0]
		lat, lon := l.NormalizeLatLonCenter()
		pr.Cached, e = h.repo.FetchNearby(k, lat, lon, rr)
		if e != nil {
			es = append(es, e)
			continue
		} else if pr.Cached == nil {
			continue
		}

		if !pr.Cached.isInvalid() {
			pr.Cached.Location.Combine(l)
			pr.Cached.Items = h.cleanResults(og, rr, pr.Cached.Location.TimeZone, pr.Cached.Items)
			h.appendCurrentTemp(rr, og, l, pr.Cached)
			pr.Cached.Params = h.makeHistResp(rr, og).Params
			pr.Cached.Params["cache"] = "partial"
			if h.isResComplete(rr, og, pr.Cached.Location.TimeZone, pr.Cached.Items) {
				pr.Cached.Params["cache"] = "full"
			}
			pr.Location = l
			return &pr, nil
		} else if pr.Cached != nil && pr.Cached.Current == 0 {
			h.appendCurrentTemp(rr, og, l, pr.Cached)
			pr.Cached.Params = h.makeHistResp(rr, og).Params
			pr.Cached.Params["cache"] = "partial"
			if pr.Cached.Current == 0 {
				pr.Cached.Params["cache"] = "missing"
			}
			pr.Location = l
		}
	}
	if pr.Cached != nil && len(pr.Cached.Items) != 0 {
		return &pr, nil
	}
	return nil, wrapErrors(es)
}

func (h *weatherHandler) tryCache(rr IReq, og *ogData, geoRes []*Location) (*TempHistoryResp, error) {
	h.log.PushScope("try$")
	defer h.log.PopScope()

	geoRes = h.normalizeCoords(geoRes) //always normalize
	var (
		pr     = &partialRes{}
		regMap = make(map[string][]*Location)
		err    error
	)
	for i, l := range geoRes {
		pr.Cached, err = h.coordsCache(rr, og, l)
		if !pr.Cached.isInvalid() {
			pr.Location = l
			break
		}

		rk := h.geo.LocKey(l.Country, l.Region)
		if arr, ok := regMap[rk]; ok {
			regMap[rk] = append(arr, l)
		} else {
			regMap[rk] = []*Location{l}
		}
		if i == 5 { //at most 5x retries
			break
		}
	}
	if pr.Cached.isInvalid() && len(regMap) != 0 { //try nearby
		var t *partialRes
		t, err = h.nearbyCache(rr, og, regMap)
		if t != nil {
			pr = t
		}
	}
	//if pr.Cached.isInvalid() || !h.isResComplete(rr, og, pr.Cached.Items) { //try to fill in the incomplete data from source, hopefully it's small
	if pr.Cached.isInvalid() {
		if h.cacheOnly {
			go h.partialFetch(rr, og, pr)
		} else {
			pr.Cached, err = h.partialFetch(rr, og, pr)
		}
	}
	if h.cacheOnly {
		pr.Cached, err = h.cacheOnlyResp(rr, og, geoRes, pr)
	} else if pr.Cached == nil && err == nil { //normal case
		err = errors.New("not found")
	}
	return pr.Cached, err
}

type ttMapRes struct {
	arrMap map[int64]*TempTime
	minF   float32
	maxF   float32
	zeros  int
}

func (h *weatherHandler) tempTimeMap(isUnixTime bool, tzl *time.Location, arr []*TempTime) *ttMapRes {
	r := ttMapRes{arrMap: make(map[int64]*TempTime)}
	for _, tt := range arr {
		if tt.Temp > 0 {
			if tt.Temp < r.minF {
				r.minF = tt.Temp
			}
			if tt.Temp > r.maxF {
				r.maxF = tt.Temp
			}
		} else {
			r.zeros++
		}
		if tt.Time == nil || isUnixTime {
			r.arrMap[tt.UnixTime] = tt
		} else {
			r.arrMap[tt.Time.In(tzl).Unix()] = tt
		}
	}
	return &r
}

//NOTE: if temperature has too many 0 and range is too great in avg, we mark it as incomplete (IE: jumps between 80F & 0F implies the 0F is missing data
// not a true complete check, more like "nearly complete" or else it would trigger too many on demand cache refreshes. Only for the worst cases
func (h *weatherHandler) isResComplete(rr IReq, og *ogData, tz string, arr []*TempTime) bool {
	var (
		hr  = rr.IntervalHours()
		dur = time.Duration(hr) * time.Hour
		tzl = time.UTC
	)
	if rr.UseLocalTz() {
		if l, _ := time.LoadLocation(tz); l != nil {
			tzl = l
		}
	}
	var (
		start, _ = time.ParseInLocation(DT_FMT_NO_TZ, og.Start.Format(DT_FMT_NO_TZ), tzl) //just take face values
		end, _   = time.ParseInLocation(DT_FMT_NO_TZ, og.End.Format(DT_FMT_NO_TZ), tzl)
	)
	start = start.Truncate(dur)
	end = end.Truncate(dur)
	if now := time.Now().In(tzl).Truncate(dur); end.After(now) {
		end = now
	}
	count := int(math.Floor(end.Sub(start).Hours() / float64(hr)))
	if count == 0 {
		return true
	}
	const (
		minPct      = 0.9
		maxZeros    = 0.2
		maxTempDiff = 50
	)
	if al := len(arr); al < count {
		if foundPct := float32(al) / float32(count); foundPct < minPct {
			h.log.Debug("isResComplete: FALSE %v items found outside instead of min %v of %v | %v", al, minPct, count, rr)
			return false
		}
	}

	var (
		tm           = h.tempTimeMap(rr.UnixTime(), tzl, arr)
		_, hasStart1 = tm.arrMap[start.Unix()]
		_, hasStart2 = tm.arrMap[start.Add(dur).Unix()]
		_, hasEnd1   = tm.arrMap[end.Unix()]
		_, hasEnd2   = tm.arrMap[end.Add(-dur).Unix()]
	)
	var (
		cur   = start
		found = 0
	)
	for !cur.After(end) {
		if _, ok := tm.arrMap[cur.Unix()]; ok {
			found++
		}
		cur = cur.Add(dur)
	}
	if foundPct := float32(found) / float32(count); foundPct < minPct {
		h.log.Debug("isResComplete: FALSE %v items found inside instead of min %v of %v | %v", found, minPct, count, rr)
		return false
	}
	if zpct := float32(tm.zeros) / float32(found); zpct > maxZeros && tm.maxF-tm.minF > maxTempDiff {
		h.log.Debug("isResComplete: FALSE %v zero items exceed %v pct of %v found at %v AND minF %v maxF %v exceeds tempDiff %v | %v", tm.zeros, maxZeros, found, zpct, tm.minF, tm.maxF, maxTempDiff, rr)
		return false
	}
	if !((hasStart1 || hasStart2) && (hasEnd1 || hasEnd2)) {
		h.log.Debug("isResComplete: FALSE start & end items (%v - %v) are both not found in res, at least 1 is required | %v", start.Format(time.RFC3339), end.Format(time.RFC3339), rr)
		return false
	}
	return true
}

func (h *weatherHandler) findByTimeInArr(dt time.Time, arr []*TempTime) *TempTime {
	dtUx := dt.Unix()
	for _, tt := range arr {
		if tt.Time == nil {
			if tt.UnixTime == dtUx {
				return tt
			}
		} else {
			if tt.Time.Equal(dt) {
				return tt
			}
		}
	}
	return nil
}

//if possible, copy or add current temp to the item in result (only if request is within range)
func (h *weatherHandler) copyCurrentToLastTemp(rr IReq, og *ogData, loc *Location, res *TempHistoryResp) {
	if !h.swapCurTemp || res.Current == 0 {
		return //nothing to do
	}
	var (
		hr    = rr.IntervalHours()
		dur   = time.Duration(hr) * time.Hour
		nowDt = time.Now().UTC().Truncate(dur)
		isUx  = rr.UnixTime() //is unix time
		edt   = og.End.Truncate(dur).Add(dur - time.Second)
	)
	if rr.UseLocalTz() {
		if tz := loc.TimeZoneLocation(); tz != nil {
			nowDt = nowDt.In(tz)
		}
	}
	if !edt.Before(nowDt) { //do nothing, end rage before now :. last item can't be swap or added to by current temp
		var (
			nowUx = nowDt.Unix()
			cur   = h.findByTimeInArr(nowDt, res.Items) //current temp found in res
		)
		if cur == nil { //not found! but we an add entry
			cur = &TempTime{}
			if isUx {
				cur.UnixTime = nowUx
			} else {
				cur.Time = &nowDt
			}
			res.Items = append(res.Items, cur)
		}
		if cur != nil { //copy current value over
			cur.Temp = res.Current
		}
	}
}

func (h *weatherHandler) appendCurrentTemp(rr IReq, og *ogData, loc *Location, res *TempHistoryResp) (*TempHistoryResp, error) {
	if h == nil {
		return nil, BOUND_REF_NIL
	} else if !loc.ValidLatLon() || res == nil || len(res.Items) == 0 {
		return nil, errors.New("invalid loc, or blank res")
	}
	h.log.PushScope("addCur")
	defer h.log.PopScope()
	var err error
	if res.Current == 0 {
		if cur, e := h.weather.CurrentInfo(loc.Lat(), loc.Lon()); e != nil {
			err = e
		} else if cur != nil && cur.TimeStr != "" {
			if rr.TempC() {
				res.Current = tempFtoC(cur.Temperature)
			} else {
				res.Current = cur.Temperature
			}
		}
	}
	h.copyCurrentToLastTemp(rr, og, loc, res)
	return res, err
}

func (h *weatherHandler) cacheOnlyResp(
	rr IReq, og *ogData, geoRes []*Location, pr *partialRes) (*TempHistoryResp, error) {
	if h == nil {
		return nil, BOUND_REF_NIL
	}
	if pr == nil {
		return nil, errors.New("pr can not be nil")
	}
	h.log.PushScope("$onlyRes")
	defer h.log.PopScope()

	var l *Location
	if len(geoRes) != 0 {
		l = geoRes[0]
	}
	if l != nil && pr.Cached != nil && pr.Cached.Location != nil {
		l.TimeZone = pr.Cached.Location.TimeZone
		l.UtcOffset = pr.Cached.Location.UtcOffset
	}
	if pr.Location == nil {
		pr.Location = l
	} else {
		pr.Location.Combine(l)
	}

	needBgFlush := false
	arr := pr.Candidate
	if len(arr) == 0 && pr.Cached != nil {
		arr = pr.Cached.Items
	}
	if invalid, incomplete := pr.Cached.isInvalid(), !h.isResComplete(rr, og, pr.Location.TimeZone, arr); invalid || incomplete {
		needBgFlush = true
		if len(arr) != 0 {
			pr.Cached = h.makeHistResp(rr, og)
			if pr.Cached.Location == nil {
				pr.Cached.Location = &LocResp{}
				pr.Cached.Location.Combine(l)
			}
			pr.Cached.Params["cache"] = "partial"
			pr.Cached.Items = h.cleanResults(og, rr, pr.Cached.Location.TimeZone, arr)
			h.appendCurrentTemp(rr, og, pr.Location, pr.Cached)
		} else {
			pr.Cached.Params["cache"] = "missing"
		}
	}

	policy := NewPCachePolicy(rr.CachePolicy())
	if (policy >= PCP_FLUSH || needBgFlush) && l != nil {
		if policy < PCP_ALLOW {
			policy = PCP_NEXT
		}
		go h.bgFetcher(rr, og, l, policy.String()) // queue background
		if h.preCsh != nil {
			go h.preCsh(l, "fix")
		}
	}
	return pr.Cached, nil
}

func (h *weatherHandler) bgFetcher(rr IReq, og *ogData, l *Location, cachePolicy string) {
	if h == nil || rr == nil || l == nil {
		return
	}
	h.log.PushScope("bgF")
	defer h.log.PopScope()

	timeUnit, tempUnit, interval := "", "", fmt.Sprintf("%vh", rr.IntervalHours())
	if rr.UnixTime() {
		timeUnit = "unix"
	}
	if rr.TempC() {
		tempUnit = "c"
	}
	lat, lon := l.NormalizeLatLonCenter()
	if cachePolicy == "" {
		cachePolicy = rr.CachePolicy()
	}
	h.rangeFrmSrc(rr, og, l, func() (*WeatherRes, error) { //fetch everything from source & cache res. SLOW!
		gr := GeoCodeReq{
			rr.StartDt(), rr.EndDt(), rr.UseLocalTz(),
			lat, lon, timeUnit, tempUnit, interval, cachePolicy}
		return h.weather.HistoricalRangeByCoordinates(&gr)
	})
}

func (h *weatherHandler) partialFetch(rr IReq, og *ogData, pr *partialRes) (resp *TempHistoryResp, err error) {
	if h == nil {
		return nil, BOUND_REF_NIL
	}
	if rr == nil || og == nil || pr == nil {
		return nil, h.log.Warn("partialFetch: input nil error")
	}
	defer panicRecover(h.log, "partialFetch: %v", pr.Location)
	h.log.PushScope("partial")
	defer h.log.PopScope()

	var (
		loc       = pr.Location
		candidate = pr.Candidate
	)
	if !loc.ValidLatLon() {
		e := errors.New("loc with bad coordinates, skipping")
		h.log.Debug("%v | %v", e.Error(), loc)
		return nil, e
	}
	if len(candidate) == 0 && pr.Cached != nil { //manufacture the candidate here from cache
		candidate = make([]*TempTime, 0, len(pr.Cached.Items))
		for _, thc := range pr.Cached.Items {
			if thc.Temp == 0 {
				continue
			}
			tt := *thc             //makes an obj copy here
			tt.Time = &(*thc.Time) //de-ref & make a copy too
			candidate = append(candidate, &tt)
		}
	}

	ttMap := h.makeDayBuckets(rr, candidate)
	ttMap = h.ensureMissingDays(rr, ttMap)
	missing := h.getMissingDates(ttMap)
	if len(missing) > 0 { //fetch from src
		noCache := strings.EqualFold("writeOnly", rr.CachePolicy())
		wr, e := h.weather.HistoricalDaysCoordinates(loc.Lat(), loc.Lon(), noCache, missing...) //slow!
		if e != nil {
			return nil, h.log.IfWarn(e)
		}
		if wr == nil {
			return nil, h.log.Error("Can't fetch HistoricalDaysCoordinates for %v | nil res, no err!", loc)
		}
		wr.Location = *wr.Location.Combine(loc)
		src := h.toTempTime(wr, wr.Historical, rr.UnixTime())
		srcMap := h.makeDayBuckets(rr, src) //combine srcMap with candidate
		for k, arr := range srcMap {
			ttMap[k] = arr
		}
		candidate = h.flattenDayBucket(rr, ttMap)

		resp = h.makeHistResp(rr, og)
		resp.Params["cache"] = "partial"
		resp.Location = wr.Location.ToLocResp()
		resp.Items = h.cleanResults(og, rr, resp.Location.TimeZone, candidate)
		h.appendCurrentTemp(rr, og, loc, resp)

		if cacheOkWrite(rr.CachePolicy()) {
			go h.storeCache(resp, candidate) //cache the diffs
		}
	}
	return resp, err
}

func (h *weatherHandler) storeCache(resp *TempHistoryResp, candidate []*TempTime) {
	if h == nil || resp == nil {
		return
	}
	defer panicRecover(h.log, "storeCache: %v", resp.Location.String())
	h.repo.Put(resp, candidate) //cache the diffs
}

func (h *weatherHandler) flattenDayBucket(rr IReq, ttMap map[string][]*TempTime) []*TempTime {
	res := make([]*TempTime, 0, len(ttMap)*24)
	for _, arr := range ttMap {
		res = append(res, arr...)
	}
	return res //NOTE: no need to sort, it will be flatten again
}

func (h *weatherHandler) getMissingDates(ttMap map[string][]*TempTime) []string {
	res := make([]string, 0, len(ttMap))
	for k, arr := range ttMap {
		if len(arr) < 24 {
			res = append(res, k)
		}
	}
	sort.Slice(res, func(i, j int) bool { //reverse date order
		return strings.Compare(res[i], res[j]) < 0
	})
	return res
}

func (h *weatherHandler) ensureMissingDays(rr IReq, ttMap map[string][]*TempTime) map[string][]*TempTime {
	start, end := rr.StartDt(), rr.EndDt()
	cur := start.Truncate(time.Hour * 24)
	for cur.Before(end) { //build required slots
		dts := cur.Format("2006-01-02")
		if _, ok := ttMap[dts]; !ok {
			ttMap[dts] = make([]*TempTime, 0, 24)
		}
		cur = cur.Add(time.Hour * 24)
	}
	return ttMap
}

func (h *weatherHandler) makeDayBuckets(rr IReq, candidate []*TempTime) map[string][]*TempTime {
	unixTime := rr.UnixTime()
	localTz := rr.UseLocalTz()
	ttMap := make(map[string][]*TempTime)
	for _, tt := range candidate {
		var dts string
		if unixTime {
			dts = time.Unix(tt.UnixTime, 0).Format("2006-01-02")
		} else if localTz {
			dts = tt.Time.UTC().Format("2006-01-02")
		} else {
			dts = tt.Time.Format("2006-01-02")
		}
		if arr, ok := ttMap[dts]; ok {
			ttMap[dts] = append(arr, tt)
		} else if tt.Temp != 0 {
			ttMap[dts] = make([]*TempTime, 1, 24)
			ttMap[dts][0] = tt
		}
	}
	return ttMap
}

func (h *weatherHandler) fetchAddr(req *AddressReq) (*TempHistoryResp, error) {
	h.log.PushScope("addr")
	defer h.log.PopScope()

	var rr IReq = req
	og := &ogData{Start: rr.StartDt(), End: rr.EndDt()}
	if !req.UseLocalDt {
		og.Start, og.End = rr.OverFetchForUTC()
	}

	var l *Location //fetch & cache location data
	x := &Location{Name: req.City, Region: req.Region, Country: req.Country, PostCode: req.PostCode}
	if geoRes, e := h.geo.Code(x, req.Cache); e == nil && len(geoRes) != 0 {
		l = geoRes[0]
		if cacheOkRead(rr.CachePolicy()) { //attempt cache fetch
			cached, e := h.tryCache(rr, og, geoRes)
			if e == nil && cached != nil {
				if h.preCsh != nil && cacheForcedWrite(rr.CachePolicy()) { //force cache rebuild
					go h.preCsh(l, rr.CachePolicy())
				}
				return cached, e //cache HIT!
			}
		}
	} else { //can't geo code! return empty
		return h.makeHistResp(rr, og), nil
	}
	//falls through cache miss
	fetchSrc := func() (*WeatherRes, error) { //fetch everything from source & cache res. SLOW!
		lat, lon := l.NormalizeLatLonCenter()
		gr := GeoCodeReq{req.Start, req.End, req.UseLocalDt, lat, lon, req.TimeUnit, req.TempUnit, req.Interval, req.Cache}
		return h.weather.HistoricalRangeByCoordinates(&gr)
	}
	return h.rangeFrmSrc(rr, og, l, fetchSrc)
}

type ogData struct {
	Start time.Time
	End   time.Time
}

func (h *weatherHandler) makeHistResp(rr IReq, og *ogData) *TempHistoryResp {
	resp := TempHistoryResp{
		Params: h.toParams(rr),
		Items:  []*TempTime{},
	}
	resp.Params["interval"] = fmt.Sprintf("%vh", rr.IntervalHours())
	resp.Params["startDate"] = og.Start.Format(time.RFC3339)
	resp.Params["endDate"] = og.End.Format(time.RFC3339)
	resp.Items = []*TempTime{}
	return &resp
}

func (h *weatherHandler) rangeFrmSrc(
	rr IReq,
	og *ogData,
	coded *Location,
	getWeather func() (*WeatherRes, error),
) (*TempHistoryResp, error) {

	h.log.PushScope("rngFrmSrc")
	defer h.log.PopScope()

	resp := h.makeHistResp(rr, og)
	wr, err := getWeather()
	if err == nil && wr != nil {
		wr.Location = *wr.Location.Combine(coded)
		resp.Params["cache"] = "0"
		resp.Location = wr.Location.ToLocResp()
		dirty := h.toTempTime(wr, wr.Historical, rr.UnixTime())

		resp.Items = h.cleanResults(og, rr, resp.Location.TimeZone, dirty)
		h.appendCurrentTemp(rr, og, coded, resp)
		if cacheOkWrite(rr.CachePolicy()) {
			go h.storeCache(resp, dirty)
		}
	}
	if resp.Items == nil {
		resp.Items = []*TempTime{}
	}
	return resp, err
}

type tempAvg struct {
	Sum   float32
	Count int32
}

func (t *tempAvg) Avg() float32 {
	if t != nil && t.Count > 0 {
		return float32(math.Round(float64(t.Sum)*10/float64(t.Count)) / 10)
	}
	return 0
}

const DT_FMT_NO_TZ = "2006-01-02 15:04:05"

func (_ *weatherHandler) makeIntervalMap(res []*TempTime, intervalHrs int32, forceUTC bool) map[string]*tempAvg {
	imap := make(map[string]*tempAvg)
	dur := time.Duration(intervalHrs) * time.Hour
	for _, tt := range res {
		var k string
		if forceUTC && tt.UnixTime > 0 {
			dt := time.Unix(tt.UnixTime, 0).Truncate(dur)
			k = dt.Format(DT_FMT_NO_TZ)
		} else {
			dt := *tt.Time
			if forceUTC {
				dt = dt.UTC()
			}
			k = dt.Truncate(dur).Format(DT_FMT_NO_TZ)
		}
		if a, ok := imap[k]; ok {
			a.Sum += tt.Temp
			a.Count++
		} else {
			imap[k] = &tempAvg{Sum: tt.Temp, Count: 1}
		}
	}
	return imap
}

func (_ *weatherHandler) flattenIntervalMap(imap map[string]*tempAvg, tl *time.Location, forceUTC bool) []*TempTime {
	res := make([]*TempTime, 0, len(imap))
	for k, v := range imap {
		var dt time.Time
		if forceUTC {
			dt, _ = time.ParseInLocation(DT_FMT_NO_TZ, k, time.UTC)
		} else {
			dt, _ = time.ParseInLocation(DT_FMT_NO_TZ, k, tl)
		}
		tt := TempTime{
			Temp:     v.Avg(),
			UnixTime: dt.Unix(),
			Time:     &dt,
		}
		res = append(res, &tt)
	}
	sort.Slice(res, func(i, j int) bool {
		return res[i].UnixTime < res[j].UnixTime
	})
	return res
}

func (h *weatherHandler) extractTimezone(tz string) *time.Location {
	var (
		tl *time.Location
		e  error
	)
	if tz == "" {
		tl = time.UTC
	} else if tl, e = time.LoadLocation(tz); e != nil {
		h.log.IfWarnF(e, "convertTimezone: can't parse tz %v. Using UTC instead", tz)
		tl = time.UTC
	}
	return tl
}

func (h *weatherHandler) cleanResults(og *ogData, rr IReq, tz string, raw []*TempTime) []*TempTime {
	if len(raw) == 0 {
		if raw == nil {
			return []*TempTime{}
		}
		return raw
	}
	var (
		tl          = h.extractTimezone(tz)
		unixTime    = rr.UnixTime()
		forceUtc    = !rr.UseLocalTz()
		intervalHrs = rr.IntervalHours()
		intervalMap = h.makeIntervalMap(raw, intervalHrs, forceUtc)
		res         = h.flattenIntervalMap(intervalMap, tl, forceUtc)
		fixed       = make([]*TempTime, 0, len(res))
		start, end  time.Time
		n           = time.Now().Truncate(time.Hour)
	)
	if forceUtc {
		n = n.UTC()
		start, end = og.Start, og.End
		if end.After(n) {
			end = n
		}
	} else {
		n = n.In(tl)
		start, _ = time.ParseInLocation(DT_FMT_NO_TZ, og.Start.Format(DT_FMT_NO_TZ), tl)
		end, _ = time.ParseInLocation(DT_FMT_NO_TZ, og.End.Format(DT_FMT_NO_TZ), tl)
		if end.After(n) {
			end = n
		}
	}
	startUx, endUx := start.Unix(), end.Unix()

	for _, tt := range res {
		if tt.Temp == 0 {
			continue
		}
		if tt.UnixTime >= startUx && tt.UnixTime <= endUx {
			if unixTime {
				tt.Time = nil
			} else {
				tt.UnixTime = 0
			}
			fixed = append(fixed, tt)
		}
	}
	return h.convToReqUnit(rr, fixed)
}

func (h *weatherHandler) convToReqUnit(rr IReq, fixed []*TempTime) []*TempTime {
	if rr.TempC() {
		for _, tt := range fixed {
			tt.Temp = tempFtoC(tt.Temp)
		}
	}
	return fixed
}

func (h *weatherHandler) currentToTempTime(w *WeatherRes, unixTime, localTime bool) (*TempTime, error) {
	h.log.PushScope("cur2TempTime")
	defer h.log.PopScope()

	n := time.Now()
	dt, e := w.timeFromStr(n, w.Current.TimeStr)
	if e != nil {
		return nil, e
	}

	tt := TempTime{Temp: w.Current.Temperature}
	if unixTime { //always UTC bc no offset info
		tt.UnixTime = dt.UTC().Unix()
	} else if localTime {
		tt.Time = dt
	} else { //force UTC
		utc := dt.UTC()
		tt.Time = &utc
	}
	return &tt, nil
}

func (h *weatherHandler) toTempTime(w *WeatherRes, mm map[string]*Daily, unixTime bool) []*TempTime {
	if len(mm) == 0 {
		return []*TempTime{}
	}

	h.log.PushScope("2TempTime")
	defer h.log.PopScope()

	arrLen := 0
	for _, dateEl := range mm {
		arrLen += len(dateEl.Hourly)
	}
	res := make([]*TempTime, 0, arrLen) //exact fit to save RAM
	if arrLen == 0 {
		return res
	}
	for _, dateEl := range mm {
		localDt, e := w.timeLocal(dateEl.DateStr, w.Location.TimeZone)
		if e != nil {
			h.log.IfWarn(e)
			ux := time.Unix(dateEl.DateUnix, 0)
			localDt = &ux //not the greatest...
		}
		for _, v := range dateEl.Hourly {
			dr, e := v.Time()
			if e != nil {
				h.log.IfWarn(e)
				continue
			}
			dt := localDt.Add(dr)
			tt := TempTime{Temp: v.Temperature}
			if unixTime { //always UTC bc no offset info
				tt.UnixTime = dt.Unix()
			} else {
				tt.Time = &dt
			}
			res = append(res, &tt)
		}
	}
	return res
}
