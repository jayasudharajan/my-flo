package main

import (
	"errors"
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"time"

	"github.com/mmcloughlin/geohash"

	"encoding/json"
	"strings"
)

type IWeatherProvider interface {
	SendRequest(path string, wr *WeatherReq) (*WeatherRes, error)
	CurrentInfo(lat, lon float32) (*Current, error)
}

type WeatherProviderCache struct {
	base        IWeatherProvider
	redis       *RedisConnection
	log         *Logger
	maxCallsHr  float64 //max Calls pr Hour
	cacheDataHr int     //how many hours to store the cached results from vendor
	latLonRe    *regexp.Regexp
}

const ENVVAR_WTRSTK_MAX_CALLS_HR = "FLO_WTRSTK_MAX_CALLS_HR"

func CreateWeatherProviderWithCache(base IWeatherProvider, redis *RedisConnection, log *Logger) *WeatherProviderCache {
	wc := WeatherProviderCache{
		base:        base,
		redis:       redis,
		log:         log.CloneAsChild("Wthr$"),
		maxCallsHr:  1,
		cacheDataHr: 24,
	}
	wc.latLonRe = regexp.MustCompile(`^-?\d+(\.\d+|),-?\d+(\.\d+|)$`)
	if cph, _ := strconv.ParseFloat(getEnvOrDefault(ENVVAR_WTRSTK_MAX_CALLS_HR, ""), 64); cph > 0 {
		wc.maxCallsHr = cph
	}
	wc.log.Notice("%v=%v", ENVVAR_WTRSTK_MAX_CALLS_HR, wc.maxCallsHr)
	return &wc
}

//returns a new instance of normalized input, original is left un-touched
func (c *WeatherProviderCache) normalizeReq(path string, w *WeatherReq) (string, *WeatherReq) {
	if c == nil || path == "" || w == nil {
		return "", nil
	}
	path = strings.TrimSpace(path)
	if path[0:1] == "/" {
		path = path[1:len(path)]
	}
	if pl := len(path); path[pl-1:pl] == "/" {
		path = path[0 : pl-1]
	}

	n := WeatherReq{
		Query:        strings.TrimSpace(w.Query),
		Unit:         strings.TrimSpace(w.Unit),
		StartDate:    strings.TrimSpace(w.StartDate),
		EndDate:      strings.TrimSpace(w.EndDate),
		ForecastDays: w.ForecastDays,
		Hourly:       w.Hourly,
		Interval:     w.Interval,
	}
	if hl := len(w.HistoricalDates); hl > 0 {
		arr := make([]string, hl)
		copy(arr, w.HistoricalDates)
		for i, d := range arr {
			arr[i] = strings.TrimSpace(d)
		}
		sort.Slice(arr, func(i, j int) bool {
			return strings.Compare(arr[i], arr[j]) < 0
		})
		n.HistoricalDates = arr
	}
	return path, &n
}

func (c *WeatherProviderCache) hashKey(path string, wr *WeatherReq) (string, error) {
	if c == nil {
		return "", BOUND_REF_NIL
	}
	if path == "" || wr == nil {
		return "", c.log.Error("hashKey: path & request required. p=%v | %v", path, wr)
	}
	nPath, nr := c.normalizeReq(path, wr)
	js, e := json.Marshal(nr)
	if e != nil {
		return "", c.log.Warn("hashKey: can't unmarshal request | %v", nr)
	}
	str := strings.ToLower(nPath + "|" + string(js))
	mh, e := mh3(str)
	if e != nil {
		return "", c.log.Warn("hashKey: can't mh3 str | %v", str)
	}
	dur := time.Duration(60/c.maxCallsHr) * time.Minute
	if wr.NoCache {
		dur = time.Minute //only good for 1min
	}
	dts := time.Now().UTC().Truncate(dur).Format("20060102_1504")
	return fmt.Sprintf("weather:stack:req:{%v}:{%v}", mh, dts), nil
}

func (c *WeatherProviderCache) SendRequest(path string, wr *WeatherReq) (*WeatherRes, error) {
	k, err := c.hashKey(path, wr)
	if err == nil && k != "" { //proceed
		dur := time.Duration(60/c.maxCallsHr) * time.Minute
		if wr.NoCache {
			dur = time.Minute
		}
		durS := int(dur.Seconds())
		ok, _ := c.redis.SetNX(k, time.Now().Format(time.RFC3339), durS)
		if ok { //fetch from source
			res, e := c.base.SendRequest(path, wr)
			if e != nil { //attempt from cache
				return c.fetch(k) //no need to log, base class should already log the problem
			} else {
				go c.store(k, res) //save the cache
				go c.storeCurrentInRes(wr, res)
				return res, nil
			}
		} else { //fetch from cache
			res, e := c.fetch(k)
			if c.log.isDebug {
				go c.storeCurrentInRes(wr, res)
			}
			return res, e
		}
	} else { //falls through to fetch from source, but warn before doing so bc we can't get a key
		c.log.Warn("SendRequest: can't obtain hash key, will forward request on as is | %v -> %v", path, wr)
		res, e := c.base.SendRequest(path, wr)
		if e == nil {
			go c.storeCurrentInRes(wr, res)
		}
		return res, e
	}
}

func (c *WeatherProviderCache) CurrentInfo(lat, lon float32) (*Current, error) {
	if c == nil {
		return nil, BOUND_REF_NIL
	}
	c.log.PushScope("cur$Inf", lat, lon)
	defer c.log.PopScope()
	if !(lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
		return nil, c.log.Warn("invalid coordinates")
	}

	gh5 := geohash.EncodeWithPrecision(float64(lat), float64(lon), 5)
	k := fmt.Sprintf("weather:geo:{%v}:current", gh5)
	if gz, e := c.redis.Get(k); e == nil && len(gz) != 0 {
		var cur Current
		e = jsonUnMarshalGz([]byte(gz), &cur)
		return &cur, c.log.IfWarn(e)
	} else if e != nil && e.Error() != "redis: nil" {
		return nil, c.log.IfWarn(e)
	}
	go func() { //bg fetch & store, don't call base as it would void the cache
		wr := WeatherReq{Query: fmt.Sprintf("%v,%v", lat, lon)}
		res, e := c.SendRequest("/current", &wr)
		if e == nil && res != nil && res.Current.TimeStr != "" {
			gh5 := geohash.EncodeWithPrecision(float64(lat), float64(lon), 5)
			e = c.storeCurrent(gh5, &res.Current)
		}
		if e != nil && (c.log.isDebug || e.Error() != "redis: nil") {
			c.log.IfWarn(e)
		}
	}()
	return nil, nil
}

func (c *WeatherProviderCache) storeCurrentInRes(wr *WeatherReq, res *WeatherRes) error {
	started := time.Now()
	if c == nil {
		return BOUND_REF_NIL
	}
	c.log.PushScope("savCurRes")
	defer c.log.PopScope()
	if wr == nil || res == nil || res.Current.TimeStr == "" {
		return c.log.Warn("wr is nil or res is blank | %v", wr)
	}
	defer panicRecover(c.log, "storeCurrentInRes: %v", wr)

	km := make(map[string]float32)
	if res.Location.ValidLatLon() {
		gh5 := geohash.EncodeWithPrecision(float64(res.Location.Lat()), float64(res.Location.Lon()), 5)
		km[gh5] = res.Current.Temperature
	}
	if c.latLonRe.MatchString(wr.Query) {
		arr := strings.Split(wr.Query, ",")
		if len(arr) == 2 {
			if lat, e := strconv.ParseFloat(arr[0], 64); e == nil && lat >= -90 && lat <= 90 {
				if lon, e := strconv.ParseFloat(arr[1], 64); e == nil && lon >= -180 && lon <= 180 {
					gh5 := geohash.EncodeWithPrecision(lat, lon, 5)
					km[gh5] = res.Current.Temperature
				}
			}
		}
	}
	es := make([]error, 0)
	for gh5, _ := range km {
		e := c.storeCurrent(gh5, &res.Current)
		es = append(es, e)
	}
	c.log.Debug("%vms | %v", time.Since(started).Milliseconds(), km)
	return c.log.IfWarn(wrapErrors(es))
}

func (c *WeatherProviderCache) storeCurrent(gh5 string, cur *Current) error {
	if c == nil {
		return BOUND_REF_NIL
	}
	c.log.PushScope("savCur", gh5)
	defer c.log.PopScope()
	if gh5 == "" || cur == nil {
		return errors.New("gh5 is blank or cur is nil")
	}

	k := fmt.Sprintf("weather:geo:{%v}:current", gh5)
	gz, e := jsonMarshalGz(cur)
	if e == nil {
		exp := 121 * 60 //over 2hrs
		_, e = c.redis.Set(k, gz, exp)
	}
	return e
}

func (c *WeatherProviderCache) keyWithoutDates(k string) string {
	if len(k) < 3 {
		return ""
	}
	ix := strings.LastIndex(k, ":")
	nk := k[0:ix]
	return nk
}

func (c *WeatherProviderCache) store(hashKey string, res *WeatherRes) error {
	if c == nil {
		return BOUND_REF_NIL
	}
	defer panicRecover(c.log, "store: %v", hashKey)
	c.log.PushScope("store")
	defer c.log.PopScope()
	if res == nil {
		return c.log.Warn("res is nil")
	}

	k := c.keyWithoutDates(hashKey)
	if k == "" {
		return c.log.Warn("can't extract key w/o dates nil input for key %v", hashKey)
	}
	gz, e := jsonMarshalGz(res)
	if e != nil {
		return c.log.IfWarnF(e, "can't gz result from %v | %v", hashKey, res)
	}
	exp := (c.cacheDataHr * 60 * 60) + 60
	_, e = c.redis.Set(k, gz, exp)
	return c.log.IfErrorF(e, "can't save to redis %v | %v", k, gz)
}

func (c *WeatherProviderCache) fetch(hashKey string) (*WeatherRes, error) {
	c.log.PushScope("fetch")
	defer c.log.PopScope()
	k := c.keyWithoutDates(hashKey)
	if k == "" {
		return nil, c.log.Warn("can't extract key w/o dates nil input for key %v", hashKey)
	}

	gz, e := c.redis.Get(k)
	if e != nil {
		if e.Error() == "redis: nil" {
			return nil, e
		}
		return nil, c.log.Warn("can't fetch key %v", k)
	}
	var wr WeatherRes
	e = jsonUnMarshalGz([]byte(gz), &wr)
	if e != nil {
		return nil, c.log.IfWarnF(e, "can't un-gzip result from redis key %v | %v", k, gz)
	}
	return &wr, nil
}
