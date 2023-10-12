package main

import (
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/mmcloughlin/geohash"
)

type IWeatherSource interface {
	HistoricalRangeByCoordinates(req *GeoCodeReq) (*WeatherRes, error)
	HistoricalDaysCoordinates(lat, lon float32, noCache bool, days ...string) (*WeatherRes, error)
	CurrentInfo(lat, lon float32) (*Current, error)
}

type weatherSource struct {
	provider IWeatherProvider
	log      *Logger
}

const ENVVAR_WEATHER_STACK_KEY = "FLO_WEATHER_STACK_KEY"
const ENVVAR_WEATHER_API_ROOT = "FLO_WEATHER_API_ROOT"
const WTR_STK_MAX_DAYS = 59

func CreateWeatherSource(redis *RedisConnection, log *Logger) *weatherSource {
	w := weatherSource{
		log: log.CloneAsChild("WtrSrc"),
	}
	w.provider = CreateWeatherStackProvider(w.log)
	w.provider = CreateWeatherProviderWithCache(w.provider, redis, w.log) //decorator pattern
	return &w
}

func (w *weatherSource) CurrentInfo(lat, lon float32) (*Current, error) {
	if w == nil {
		return nil, BOUND_REF_NIL
	}
	if !(lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
		e := errors.New(fmt.Sprintf("bad coords [%v,%v]", lon, lat))
		w.log.Debug("CurrentInfo: %v", e.Error())
		return nil, e
	}
	gh5 := geohash.EncodeWithPrecision(float64(lat), float64(lon), 5)
	lat2, lon2 := geohash.DecodeCenter(gh5)
	lat, lon = float32(lat2), float32(lon2) //normalize coords
	return w.provider.CurrentInfo(lat, lon)
}

func (w *weatherSource) HistoricalDaysCoordinates(lat, lon float32, noCache bool, days ...string) (*WeatherRes, error) {
	if w == nil {
		return nil, BOUND_REF_NIL
	}
	if !(lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
		e := errors.New(fmt.Sprintf("bad coords [%v,%v]", lon, lat))
		w.log.Trace("HistoricalDaysCoordinates: %v", e.Error())
		return nil, e
	}
	w.log.PushScope("HstDaysCor")
	defer w.log.PopScope()

	days = uniqueStr(days)
	sort.Slice(days, func(i, j int) bool {
		return strings.Compare(days[i], days[j]) > 1
	})
	totalDays := len(days)
	lastPos := totalDays
	batchCount := int(math.Ceil(float64(totalDays) / WTR_STK_MAX_DAYS))

	gh5 := geohash.EncodeWithPrecision(float64(lat), float64(lon), 5)
	lat2, lon2 := geohash.DecodeCenter(gh5)
	lat, lon = float32(lat2), float32(lon2) //normalize coords
	wr := WeatherReq{
		Query: fmt.Sprintf("%v,%v", lat, lon),
		NoCache: noCache,
	}
	var res *WeatherRes
	es := make([]error, 0)
	for i := 0; i < batchCount; i++ { //request in batch of max allowed days
		x := i * WTR_STK_MAX_DAYS
		y := (i + 1) * WTR_STK_MAX_DAYS
		if y > lastPos {
			y = lastPos
			if x == y {
				break
			}
		}
		wr.HistoricalDates = days[x:y]
		batch, e := w.provider.SendRequest("/historical", &wr)
		if e != nil {
			es = append(es, e)
			continue
		}
		if i == 0 {
			res = batch
			if res.Error != nil && res.Error.Code > 0 {
				break //end the loop here...
			}
			continue
		}
		if len(batch.Historical) != 0 { //append
			for k, v := range batch.Historical {
				res.Historical[k] = v
			}
		}
	}
	return res, w.log.IfError(wrapErrors(es))
}

func (w *weatherSource) HistoricalRangeByCoordinates(req *GeoCodeReq) (*WeatherRes, error) {
	if w == nil {
		return nil, BOUND_REF_NIL
	}
	w.log.PushScope("HstRngXY")
	defer w.log.PopScope()

	wr := WeatherReq{}
	err := wr.setCoordinates(req)
	if err != nil {
		w.log.Trace(err.Error())
		return nil, err
	}
	wr.NoCache = strings.EqualFold(req.Cache, "writeOnly")
	return w.historyBatch(&wr, req.Start, req.End)
}

func (w *weatherSource) historyBatch(wr *WeatherReq, start, end time.Time) (*WeatherRes, error) {
	w.log.PushScope("hstBatch")
	defer w.log.PopScope()

	dtBatch := w.splitMaxDays(start, end)
	var res = &WeatherRes{Historical: make(map[string]*Daily)}
	es := make([]error, 0)
	for i, p := range dtBatch {
		wr.StartDate = p.Start.UTC().Format("2006-01-02")
		wr.EndDate = p.End.UTC().Format("2006-01-02")
		batch, e := w.provider.SendRequest("/historical", wr)
		if e != nil {
			es = append(es, e)
			continue
		}
		if i == 0 {
			if res.Error != nil && res.Error.Code > 0 {
				break //end the loop here...
			}
			if batch != nil && batch.Historical != nil {
				res = batch
			}
			continue
		}
		if len(batch.Historical) != 0 { //append
			if res != nil && res.Historical == nil {
				res.Historical = make(map[string]*Daily)
			}
			for k, v := range batch.Historical {
				res.Historical[k] = v
			}
		}
	}
	return res, w.log.IfWarn(wrapErrors(es))
}

type datePair struct {
	Start time.Time
	End   time.Time
}

func (_ *weatherSource) splitMaxDays(start, end time.Time) []datePair {
	daysDiff := math.Ceil(end.Sub(start).Hours() / 24)
	pairs := math.Ceil(daysDiff / WTR_STK_MAX_DAYS)
	arr := make([]datePair, 0, int(pairs))

	if pairs > 1 { //split
		maxDur := time.Duration(time.Hour*24) * WTR_STK_MAX_DAYS
		cur := start
		for cur.Before(end) {
			tail := cur.Add(maxDur)
			if tail.After(end) {
				tail = end
			}
			arr = append(arr, datePair{cur, tail})
			cur = tail.Add(time.Hour * 24)
		}
	} else {
		arr = append(arr, datePair{start, end})
	}
	return arr
}
