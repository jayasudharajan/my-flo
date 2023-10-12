package main

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/mmcloughlin/geohash"
)

type IReq interface {
	StartDt() time.Time
	EndDt() time.Time
	UseLocalTz() bool
	UnixTime() bool
	TempC() bool
	CachePolicy() string

	IntervalHours() int32
	OverFetchForUTC() (ogStart, ogEnd time.Time)
	NormalizeDates()
}

type GeoCodeReq struct { //geo code request
	Start      time.Time `schema:"startDate" json:"startDate,omitempty" validate:"required"` //startswith=20
	End        time.Time `schema:"endDate" json:"endDate,omitempty" validate:"required"`
	UseLocalDt bool      `schema:"useLocalDt" json:"useLocalDt"` //if false, will normalize to UTC
	Lat        float32   `schema:"lat" json:"lat,omitempty" validate:"latitude"`
	Lon        float32   `schema:"lon" json:"lon,omitempty" validate:"longitude"`
	TimeUnit   string    `schema:"timeUnit" json:"unixTime,omitempty" validate:"omitempty,oneof=UNIX Unix unix ISO8610 Iso8610 iso8610 RFC3339 Rfc3339 rfc3339"`
	TempUnit   string    `schema:"tempUnit" json:"unixTime,omitempty" validate:"omitempty,oneof=F C f c"`
	Interval   string    `schema:"interval" json:"interval,omitempty" validate:"omitempty,regex=\\d+[dh]"`
	Cache      string    `schema:"cachePolicy" json:"cache,omitempty" validate:"omitempty"`
}

func (o *GeoCodeReq) StartDt() time.Time  { return o.Start }
func (o *GeoCodeReq) EndDt() time.Time    { return o.End }
func (o *GeoCodeReq) UseLocalTz() bool    { return o.UseLocalDt }
func (o *GeoCodeReq) UnixTime() bool      { return strings.ToLower(o.TimeUnit) == "unix" }
func (o *GeoCodeReq) TempC() bool         { return strings.ToLower(o.TempUnit) == "c" }
func (o *GeoCodeReq) CachePolicy() string { return o.Cache }

func (r *GeoCodeReq) IntervalHours() int32 {
	if r != nil {
		return intervalHrs(r.Interval)
	}
	return 1
}

//force to UTC & get -24 to +24 to save a query to geocode
func (r *GeoCodeReq) OverFetchForUTC() (ogStart, ogEnd time.Time) {
	if r == nil {
		return
	}
	ogStart, ogEnd = r.Start, r.End
	r.Start = ogStart.Add(time.Hour * -24).UTC()
	r.End = ogEnd.Add(time.Hour * 24).UTC()
	if n := time.Now().UTC().Truncate(time.Hour); r.End.After(n) {
		r.End = n
	}
	return ogStart, ogEnd
}
func (r *GeoCodeReq) NormalizeDates() {
	if r == nil {
		return
	}
	if r.End.Unix() < r.Start.Unix() {
		r.End, r.Start = r.Start, r.End
	}
	if n := time.Now().UTC(); r.End.UTC().After(n) { //attempt to preserve time zone
		r.End = n
	}
	offset := time.Duration(int64(r.IntervalHours())) * time.Hour
	r.Start = r.Start.Truncate(offset)
	dte := r.End.Truncate(offset)
	if dte.Before(r.End) {
		r.End = dte.Add(offset)
	}
}

type AddressReq struct { //address request
	Start      time.Time `schema:"startDate" json:"startDate,omitempty" validate:"required"` //startswith=20
	End        time.Time `schema:"endDate" json:"endDate,omitempty" validate:"required"`
	UseLocalDt bool      `schema:"useLocalDt" json:"useLocalDt"` //if false, will normalize to UTC
	Street     string    `schema:"street" json:"street,omitempty"`
	City       string    `schema:"city" json:"city,omitempty" validate:"required_without_all=PostCode Country"`
	Region     string    `schema:"region" json:"region,omitempty"`
	PostCode   string    `schema:"postCode" json:"postCode,omitempty" validate:"required_without_all=Street City Region"`
	Country    string    `schema:"country" json:"country,omitempty" validate:"required_without_all=Region PostCode"`
	TimeUnit   string    `schema:"timeUnit" json:"unixTime,omitempty" validate:"omitempty,oneof=UNIX Unix unix ISO8610 Iso8610 iso8610 RFC3339 Rfc3339 rfc3339"`
	TempUnit   string    `schema:"tempUnit" json:"unixTime,omitempty" validate:"omitempty,oneof=F C f c"`
	Interval   string    `schema:"interval" json:"interval,omitempty" validate:"omitempty,regex=\\d+[dh]"`
	Cache      string    `schema:"cachePolicy" json:"cache,omitempty" validate:"omitempty"`
}

func (o *AddressReq) StartDt() time.Time  { return o.Start }
func (o *AddressReq) EndDt() time.Time    { return o.End }
func (o *AddressReq) UseLocalTz() bool    { return o.UseLocalDt }
func (o *AddressReq) UnixTime() bool      { return strings.ToLower(o.TimeUnit) == "unix" }
func (o *AddressReq) TempC() bool         { return strings.ToLower(o.TempUnit) == "c" }
func (o *AddressReq) CachePolicy() string { return o.Cache }

func (r *AddressReq) IntervalHours() int32 {
	if r != nil {
		return intervalHrs(r.Interval)
	}
	return 1
}

func intervalHrs(interval string) int32 {
	if il := len(interval); il >= 2 {
		n, e := strconv.ParseInt(interval[0:il-1], 10, 32)
		if e == nil {
			var nn int32
			switch interval[il-1 : il] {
			case "d", "D":
				nn = 24 * int32(n)
			default: //h
				nn = int32(n)
			}
			if nn >= 24 {
				return 24
			} else if nn >= 12 {
				return 12
			} else if nn >= 6 {
				return 6
			} else if nn >= 3 {
				return 3
			}
		}
	}
	return 1
}

//force to UTC & get -24 to +24 to save a query to geocode
func (r *AddressReq) OverFetchForUTC() (ogStart, ogEnd time.Time) {
	if r == nil {
		return
	}
	ogStart, ogEnd = r.Start, r.End
	r.Start = ogStart.Add(time.Hour * -24).UTC()
	r.End = ogEnd.Add(time.Hour * 24).UTC()
	if n := time.Now().UTC().Truncate(time.Hour); r.End.After(n) {
		r.End = n
	}
	return ogStart, ogEnd
}
func (r *AddressReq) NormalizeDates() {
	if r == nil {
		return
	}
	if r.End.Unix() < r.Start.Unix() {
		r.End, r.Start = r.Start, r.End
	}
	if n := time.Now().UTC(); r.End.UTC().After(n) { //attempt to preserve time zone
		r.End = n
	}
	offset := time.Duration(r.IntervalHours()) * time.Hour
	r.Start = r.Start.Truncate(offset)
	dte := r.End.Truncate(offset)
	if dte.Before(r.End) {
		r.End = dte.Add(offset)
	}
}
func (r *AddressReq) NormalizeAddress() *AddressReq {
	if r == nil {
		return r
	}
	if r.City != "" {
		r.City = strings.ToLower(strings.TrimSpace(r.City))
	}
	if r.Region != "" {
		r.Region = strings.ToLower(strings.TrimSpace(r.Region))
	}
	if r.PostCode != "" {
		r.PostCode = strings.ToLower(strings.TrimSpace(r.PostCode))
	}
	if r.Country != "" {
		r.Country = strings.ToLower(strings.TrimSpace(r.Country))
	}
	return r
}

type LocResp struct { //location response
	Lat       float32 `json:"lat,omitempty"`
	Lon       float32 `json:"lon,omitempty"`
	GeoHash   string  `json:"geoHash,omitempty"`
	Name      string  `json:"city,omitempty"`
	Region    string  `json:"region,omitempty"`
	PostCode  string  `json:"postCode,omitempty"`
	Country   string  `json:"country,omitempty"`
	TimeZone  string  `json:"timeZone,omitempty"`
	UtcOffset string  `json:"utcOffset,omitempty"`
}

func (l *LocResp) String() string {
	if l == nil {
		return ""
	}
	loc := strJoinIfNotEmpty(",", l.Name, l.Region, l.PostCode, l.Country)
	gc := geohash.EncodeWithPrecision(float64(l.Lat), float64(l.Lon), 5)
	return fmt.Sprintf("(%v,%v) %v | %v | z=%v", l.Lon, l.Lat, gc, loc, l.UtcOffset)
}

func (l *LocResp) Combine(loc *Location) {
	if loc == nil {
		return
	}
	if l == nil {
		*l = LocResp{}
	}
	if l.Name == "" {
		l.Name = loc.Name
	}
	if l.Region == "" {
		l.Region = loc.Region
	}
	if l.PostCode == "" {
		l.PostCode = loc.PostCode
	}
	if l.Country == "" {
		l.Country = loc.Country
	}
	if loc.ValidLatLon() {
		l.Lat, l.Lon = loc.Lat(), loc.Lon()
		l.GeoHash = geohash.EncodeWithPrecision(float64(l.Lat), float64(l.Lon), 5)
	}
	if l.TimeZone == "" {
		l.TimeZone = loc.TimeZone
	}
	if l.UtcOffset == "" {
		if loc.UtcOffset != "" {
			l.UtcOffset = loc.UtcOffset
		} else if loc._timeOffset != "" {
			l.UtcOffset = loc._timeOffset
		}
	}
}

func (l *LocResp) ComputeGeoHash() string {
	if l == nil {
		return ""
	}
	if l.Lat >= -90 && l.Lat <= 90 && l.Lon >= -180 && l.Lon <= 180 {
		l.GeoHash = geohash.EncodeWithPrecision(float64(l.Lat), float64(l.Lon), 5)
		return l.GeoHash
	}
	return ""
}

type TempTime struct { //temperature time
	UnixTime int64      `json:"unixTime,omitempty"`
	Time     *time.Time `json:"time,omitempty"`
	Temp     float32    `json:"temp"`
}

func (w *WeatherRes) timeFromStr(day time.Time, timeStr string) (*time.Time, error) {
	if w == nil {
		return nil, BOUND_REF_NIL
	} else if w.Location.UtcOffset == "" {
		return nil, errors.New("timeFromStr: WeatherRes.UtcOffset is empty")
	} else if timeStr == "" {
		return nil, errors.New("timeFromStr: timeStr is empty")
	} else if day.Year() <= 2000 {
		return nil, errors.New("timeFromStr: day value too small")
	}

	utcDay := day.UTC().Format("2006-01-02")
	dts := fmt.Sprintf("%v %v %v", utcDay, timeStr, w.Location.TimeOffsetCorrected())
	dt, e := time.Parse("2006-01-02 03:04 PM -07:00", dts)
	if e != nil {
		return nil, e
	}
	return &dt, nil
}

func (w *WeatherRes) timeLocal(dayStr, tz string) (*time.Time, error) {
	if w == nil {
		return nil, BOUND_REF_NIL
	} else if w.Location.UtcOffset == "" {
		return nil, errors.New("timeFromStr: WeatherRes.UtcOffset is empty")
	} else if len(dayStr) < 10 {
		return nil, errors.New("timeFromStr: day value too small")
	}

	if zone, e := time.LoadLocation(tz); e != nil {
		return nil, e
	} else if dt, e := time.ParseInLocation("2006-01-02", dayStr, zone); e != nil {
		return nil, e
	} else {
		return &dt, nil
	}
}

type TempHistoryResp struct {
	Params   map[string]interface{} `json:"params,omitempty"`
	Location *LocResp               `json:"location,omitempty"`
	Items    []*TempTime            `json:"items"`
	Current  float32                `json:"current"`
}

func (t *TempHistoryResp) isInvalid() bool {
	ok := t == nil || t.Location == nil || t.Location.UtcOffset == "" || len(t.Items) == 0
	return ok
}

func cacheOkRead(policy string) bool {
	switch strings.ToLower(policy) {
	case "0", "no", "off", "false":
		return false
	default:
		if strings.EqualFold(policy, "writeOnly") {
			return false
		}
		return true
	}
}

func cacheForcedWrite(policy string) bool {
	switch strings.ToLower(policy) {
	case "flush", "ahead", "next", "precache", "fix":
		return true
	default:
		return false
	}
}
func cacheOkWrite(policy string) bool {
	return policy == "" || cacheForcedWrite(policy) || !(len(policy) == 4 && strings.ToLower(policy[0:4]) == "read")
}
