package main

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/google/go-querystring/query"
)

type WeatherStackProvider struct {
	keys    []string
	hc      *httpUtil
	apiRoot string
	reqN    int64
	log     *Logger
}

var _wsHttpUtil *httpUtil
var _wsLock = sync.Mutex{}

func initWeatherStackHttpUtil(log *Logger) *httpUtil {
	if _wsHttpUtil == nil { //double check lock, lazy singleton
		_wsLock.Lock()
		defer _wsLock.Unlock()
		if _wsHttpUtil == nil {
			_wsHttpUtil = CreateHttpUtil("", log, time.Second*9)
		}
	}
	return _wsHttpUtil
}

func CreateWeatherStackProvider(log *Logger) *WeatherStackProvider {
	keys := strings.Split(getEnvOrDefault(ENVVAR_WEATHER_STACK_KEY, ""), " ")
	if len(keys) == 0 || keys[0] == "" {
		log.Fatal("%v is missing", ENVVAR_WEATHER_STACK_KEY)
		signalExit()
	}
	goodKeys := make([]string, 0, len(keys))
	for _, k := range keys {
		if k == "" {
			continue
		}
		goodKeys = append(goodKeys, k)
	}
	if len(goodKeys) == 0 {
		log.Fatal("%v is missing.", ENVVAR_WEATHER_STACK_KEY)
		signalExit()
	}
	apiRoot := getEnvOrDefault(ENVVAR_WEATHER_API_ROOT, "http://api.weatherstack.com")
	if apiRoot == "" {
		log.Fatal("Api root is missing")
		signalExit()
	}
	w := WeatherStackProvider{
		keys:    goodKeys,
		apiRoot: apiRoot,
		log:     log.CloneAsChild("WeatherStack"),
	}
	w.hc = initWeatherStackHttpUtil(log)
	return &w
}

func (w *WeatherStackProvider) get(path string, input, result interface{}, extraQuery string) error {
	w.log.PushScope("hGet", path)
	defer w.log.PopScope()

	if v, e := query.Values(input); e != nil {
		return w.log.IfError(e)
	} else {
		q := v.Encode()
		if extraQuery != "" {
			if len(q) == 0 {
				q = extraQuery
			} else {
				q += "&" + extraQuery
			}
		}
		url := fmt.Sprintf("%v%v?%v", w.apiRoot, path, q)
		return w.hc.Do("GET", url, nil, nil, result)
	}
}

func (w *WeatherStackProvider) SendRequest(path string, wr *WeatherReq) (*WeatherRes, error) {
	started := time.Now()
	if w == nil {
		return nil, BOUND_REF_NIL
	}
	w.log.PushScope("SendReq")
	defer w.log.PopScope()

	c := atomic.AddInt64(&w.reqN, 1)
	wr.Key = w.keys[int(c)%len(w.keys)] //load-balancing the API keys if there are more than 1 configured
	wr.Unit = "f"

	var r WeatherRes
	extraQuery := ""
	if len(wr.HistoricalDates) != 0 {
		sort.Strings(wr.HistoricalDates)
		extraQuery = "historical_date=" + strings.Join(wr.HistoricalDates, ";")
	}
	if extraQuery != "" || wr.StartDate != "" {
		wr.Hourly = 1
		wr.Interval = WI_1HOUR
	}
	if err := w.get(path, wr, &r, extraQuery); err != nil {
		return nil, w.log.IfWarnF(err, "api err | key %v", wr.Key[:3])
	} else if r.Error != nil && r.Error.Code > 0 {
		r.Error.Info += fmt.Sprintf(" | key %v", wr.Key[:3])
		w.logRequest(started, r, wr, r.Error)
		return nil, errors.New(fmt.Sprintf("api response | %v", r.Error))
	}
	w.logRequest(started, r, wr, nil)
	return &r, nil
}

func (w *WeatherStackProvider) logRequest(started time.Time, r WeatherRes, wr *WeatherReq, er *WeatherErr) {
	took := time.Since(started).Milliseconds()
	ll := LL_TRACE
	lm := "%vms (%v,%v) %v | %v - %v | t=%v h=%v f=%v"
	if took > 5_000 {
		lm = "SLOW " + lm
		ll = LL_NOTICE
	} else if took > 1_000 {
		ll = LL_INFO
	} else if took > 200 {
		ll = LL_DEBUG
	}
	if er != nil {
		ll = LL_WARN
		lm += " | API_ERROR " + fmt.Sprint(er)
	}
	var sd, ed string
	if wr != nil {
		if len(wr.HistoricalDates) != 0 {
			sd = strings.Join(wr.HistoricalDates, ";")
		} else {
			sd, ed = wr.StartDate, wr.EndDate
		}
	}
	w.log.Log(ll, lm,
		took,
		r.Location.Lon(), r.Location.Lat(),
		strJoinIfNotEmpty(", ", r.Location.Name, r.Location.Region, r.Location.PostCode),
		sd, ed,
		r.Current.Temp(), len(r.Historical), len(r.Forecast))
}

func (c *WeatherStackProvider) CurrentInfo(lat, lon float32) (*Current, error) {
	if c == nil {
		return nil, BOUND_REF_NIL
	}
	c.log.PushScope("curInf", lat, lon)
	defer c.log.PopScope()

	wr := WeatherReq{Query: fmt.Sprintf("%v,%v", lat, lon)}
	if res, e := c.SendRequest("/current", &wr); e == nil && res != nil && res.Current.TimeStr != "" {
		return &res.Current, nil
	} else {
		return nil, c.log.IfWarn(e)
	}
}
