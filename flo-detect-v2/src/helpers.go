package main

import (
	"net/http"
	"strconv"
	"strings"
)

var _minReportGallons float64
var _minReportDuration float64

func init() {
	s1 := getEnvOrDefault("FLO_MIN_GALLONS", "0.0")
	if len(s1) == 0 {
		s1 = "0"
	}
	x1, _ := strconv.ParseFloat(s1, 64)
	_minReportGallons = x1

	s2 := getEnvOrDefault("FLO_MIN_DURATION", "3.0")
	if len(s2) == 0 {
		s2 = "0"
	}
	x2, _ := strconv.ParseFloat(s2, 64)
	_minReportDuration = x2
}

func reportMinGallons(r *http.Request) float64 {
	if r == nil {
		return 0
	}

	minStr := strings.Join(r.URL.Query()["minGallons"], "")
	if len(minStr) == 0 {
		return _minReportGallons
	}

	x, e := strconv.ParseFloat(minStr, 64)
	if e != nil {
		return _minReportGallons
	}

	return x
}

func reportMinDuration(r *http.Request) float64 {
	if r == nil {
		return 0
	}

	minStr := strings.Join(r.URL.Query()["minDuration"], "")
	if len(minStr) == 0 {
		return _minReportDuration
	}

	x, e := strconv.ParseFloat(minStr, 64)
	if e != nil {
		return _minReportDuration
	}

	return x
}

func httpQueryGetInt64(r *http.Request, param string, defValue int64) int64 {
	if r == nil {
		return 0
	}

	x := strings.Join(r.URL.Query()[param], "")
	if len(x) == 0 {
		return defValue
	}

	g, e := strconv.ParseInt(x, 10, 64)
	if e != nil {
		return defValue
	}

	return g
}
