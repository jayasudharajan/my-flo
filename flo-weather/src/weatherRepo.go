package main

import (
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/go-redis/redis"

	"github.com/mmcloughlin/geohash"
)

type IWeatherRepository interface {
	Put(res *TempHistoryResp, dirty []*TempTime)
	FetchNearby(countryRegionKey string, lat, lon float32, rr IReq) (resp *TempHistoryResp, err error)
	FetchCoords(lat, lon float32, rr IReq) (resp *TempHistoryResp, err error)
}

type weatherRepo struct {
	redis *RedisConnection
	log   *Logger
}

func CreateWeatherRepository(redis *RedisConnection, log *Logger) IWeatherRepository {
	wc := weatherRepo{
		redis: redis,
		log:   log.CloneAsChild("WthRpo"),
	}
	return &wc
}

func (_ *weatherRepo) makeDailyTemps(dirty []*TempTime) (dtm map[string][]*float32) { //day -> 24hrs temp array
	dtm = make(map[string][]*float32)
	for _, tt := range dirty {
		var dt time.Time
		if tt.Time != nil {
			dt = *tt.Time
		} else {
			dt = time.Unix(tt.UnixTime, 0)
		}
		k := dt.Format("20060102")
		if _, ok := dtm[k]; !ok {
			dtm[k] = make([]*float32, 24)
		}
		dtm[k][dt.Hour()] = &tt.Temp
	}
	return dtm
}
func (_ *weatherRepo) makeDailyCsv(dtm map[string][]*float32) (csvm map[string]interface{}, strln int) { //day -> csv temps
	csvm = make(map[string]interface{})
	for k, arr := range dtm {
		sb := strings.Builder{}
		var f *float32
		i, al := 0, len(arr)-1
		for i, f = range arr {
			if f != nil {
				s := fmt.Sprint(*f)
				sb.WriteString(s)
			}
			if i < al {
				sb.WriteString(",")
			}
		}
		csv := sb.String()
		buf, _ := toGzip([]byte(csv))
		strln += len(buf)
		csvm[k] = buf
	}
	return csvm, strln
}

func (h *weatherRepo) Put(res *TempHistoryResp, dirty []*TempTime) {
	if res == nil || res.Location == nil || dirty == nil {
		return
	}
	dtStart := time.Now()
	h.log.PushScope("Put")
	defer h.log.PopScope()

	key := h.locTempKey(res.Location.Lat, res.Location.Lon)
	dtCsv, strln := h.makeDailyCsv(h.makeDailyTemps(dirty)) //day -> 24hrs temp csv
	dtCsv["timeZone"] = res.Location.TimeZone
	dtCsv["utcOffset"] = res.Location.UtcOffset
	_, e := h.redis.HMSet(key, dtCsv, 0)
	h.log.IfError(e)

	dts := make([]string, 0, len(dtCsv))
	for d, _ := range dtCsv {
		dts = append(dts, d)
	}
	h.log.Debug("OK %vms %v strln=%v | %v", time.Since(dtStart).Milliseconds(), key, strln, dts)
}

func (h *weatherRepo) logFetch(resp *TempHistoryResp, lat, lon float32, rr IReq, k string, start time.Time) {
	s := "HIT"
	if resp.isInvalid() {
		s = "MISS"
	}
	fmt := "%v %vms r=%v (%v,%v) %v | %v - %v"
	took := time.Since(start).Milliseconds()
	ll := LL_DEBUG
	if took > 500 {
		ll = LL_NOTICE
		fmt = "SLOW " + fmt
	} else if took > 100 {
		ll = LL_INFO
	}
	items := 0
	if resp != nil {
		items = len(resp.Items)
	}
	h.log.Log(ll, fmt, s, took, items, lon, lat, k, rr.StartDt().Format(time.RFC3339), rr.EndDt().Format(time.RFC3339))
}

func (h *weatherRepo) FetchNearby(countryRegionKey string, lat, lon float32, rr IReq) (resp *TempHistoryResp, err error) {
	workStart := time.Now()
	h.log.PushScope("FetchNear")
	defer h.log.PopScope()

	if !(lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
		return nil, errors.New(fmt.Sprintf("invalid lat %v lon %v", lat, lon))
	}
	q := redis.GeoRadiusQuery{
		Radius:    4,
		Unit:      "mi",
		WithCoord: true,
		WithDist:  true,
		Count:     5,
		Sort:      "ASC",
	}
	cmd := h.redis._client.GeoRadiusRO(countryRegionKey, float64(lat), float64(lon), &q)
	if locs, e := cmd.Result(); e == nil && len(locs) != 0 {
		for _, l := range locs {
			resp, err = h.FetchCoords(float32(l.Latitude), float32(l.Longitude), rr)
			if err == nil && resp.isInvalid() {
				break
			}
		}
	}
	h.logFetch(resp, lat, lon, rr, countryRegionKey, workStart)
	return resp, err
}

func (_ *weatherRepo) locTempKey(lat, lon float32) string {
	gh5 := geohash.EncodeWithPrecision(float64(lat), float64(lon), 5)
	k := fmt.Sprintf("weather:geo:temp:{%v}", gh5)
	return k
}

func (h *weatherRepo) hashDates(startDt, endDt time.Time) []string {
	startDt = startDt.Add(time.Hour * -24)
	endDt = endDt.Add(time.Hour * 24)
	totalDays := int(math.Ceil(endDt.Sub(startDt).Hours() / 24))
	res := make([]string, 2, totalDays+2)
	res[0] = "utcOffset"
	res[1] = "timeZone"
	for curDt := startDt; curDt.Before(endDt); {
		ds := curDt.Format("20060102")
		res = append(res, ds)
		curDt = curDt.Add(time.Hour * 24)
	}
	return res
}

func (h *weatherRepo) FetchCoords(lat, lon float32, rr IReq) (resp *TempHistoryResp, err error) {
	workStart := time.Now()
	h.log.PushScope("FetchXY")
	defer h.log.PopScope()

	k := h.locTempKey(lat, lon)
	dateKeys := h.hashDates(rr.StartDt(), rr.EndDt())
	resp, err = h.temps(k, dateKeys)

	h.logFetch(resp, lat, lon, rr, k, workStart)
	return resp, err
}

const WTR_TEMPS_FETCH_BATCH = 70

func (h *weatherRepo) rmNilArr(arr []interface{}) []interface{} {
	res := make([]interface{}, 0, len(arr))
	for _, v := range arr {
		if v != nil {
			res = append(res, v)
		}
	}
	return res
}

func (h *weatherRepo) temps(k string, hashKeys []string) (resp *TempHistoryResp, err error) {
	h.log.PushScope("temps", k)
	defer h.log.PopScope()

	var (
		hashLen    = len(hashKeys)
		batchCount = int(math.Ceil(float64(hashLen) / float64(WTR_TEMPS_FETCH_BATCH)))
		es         = make([]error, 0)
	)
	resp = &TempHistoryResp{
		Items:    make([]*TempTime, 0, (len(hashKeys)-2)*24),
		Location: &LocResp{},
	}
	for i := 0; i < batchCount; i++ {
		endIx := (i + 1) * WTR_TEMPS_FETCH_BATCH
		if endIx > hashLen {
			endIx = hashLen
		}
		batch := hashKeys[i*WTR_TEMPS_FETCH_BATCH : endIx]

		cmd := h.redis._client.HMGet(k, batch...)
		if vals, er := cmd.Result(); er != nil {
			es = append(es, errors.New(h.log.Debug("Can't find %v | %v", hashKeys, er.Error())))
		} else if clean := h.rmNilArr(vals); len(clean) != 0 {
			resp, er = h.parseValues(clean, batch, resp)
			es = append(es, h.log.IfWarnF(er, "%v", hashKeys))
		}
	}
	return resp, wrapErrors(es)
}

func (h *weatherRepo) parseValues(vals []interface{}, hashKeys []string, resp *TempHistoryResp) (*TempHistoryResp, error) {
	var (
		es   = make([]error, 0)
		tz   *time.Location
		seek = 2
	)
	if resp.Location != nil && resp.Location.TimeZone != "" {
		tz, _ = time.LoadLocation(resp.Location.TimeZone)
	}
	if tz == nil {
		for i, v := range vals {
			if v == nil {
				continue
			}
			if kk := hashKeys[i]; kk == "utcOffset" {
				resp.Location.UtcOffset = fmt.Sprintf("%v", v)
				seek--
			} else if kk == "timeZone" {
				resp.Location.TimeZone = fmt.Sprintf("%v", v)
				tz, _ = time.LoadLocation(resp.Location.TimeZone)
				seek--
			}
			if seek == 0 {
				break
			}
		}
	}
	if tz == nil {
		tz = time.UTC
	}
	for i, v := range vals {
		if v == nil {
			continue
		}
		if kk := hashKeys[i]; len(kk) > 2 && kk[:2] == "20" {
			if dt, ee := time.ParseInLocation("20060102", kk, tz); ee != nil {
				h.log.IfWarnF(ee, "buildRes")
				continue
			} else {
				e := h.appendCsv(v, resp, dt)
				es = append(es, e)
			}
		}
	}
	return resp, wrapErrors(es)
}

func (_ *weatherRepo) appendCsv(v interface{}, resp *TempHistoryResp, dt time.Time) error {
	gzBuf := []byte(v.(string))
	if csvBuf, be := fromGzip(gzBuf); be == nil && len(csvBuf) != 0 {
		if csv := strings.Split(string(csvBuf), ","); len(csv) == 24 { // build result items here...
			for j, tmp := range csv {
				var (
					temp, _ = strconv.ParseFloat(tmp, 32)
					secs    = int64(j) * 60 * 60
					ut      = dt.Add(time.Duration(secs) * time.Second)
				)
				item := TempTime{
					Temp:     float32(temp),
					UnixTime: dt.Unix() + secs,
					Time:     &ut,
				}
				resp.Items = append(resp.Items, &item)
			}
		} else {
			return errors.New("Csv len != 24")
		}
	}
	return nil
}
