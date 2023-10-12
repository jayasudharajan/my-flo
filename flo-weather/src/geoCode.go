package main

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"googlemaps.github.io/maps"
)

type IGeoCoder interface {
	Code(loc *Location, cachePolicy string) ([]*Location, error)
}

type geoCode struct {
	key string
	gc  *maps.Client
	log *Logger
}

const ENVVAR_GMAP_KEY = "FLO_GMAP_KEY"

func CreateGeoCode(log *Logger) IGeoCoder {
	g := geoCode{
		log: log.CloneAsChild("geo"),
	}
	if k := getEnvOrDefault(ENVVAR_GMAP_KEY, ""); k == "" {
		g.log.Fatal("Missing %v", ENVVAR_GMAP_KEY)
		signalExit()
	} else {
		g.key = k
	}
	if c, err := maps.NewClient(maps.WithAPIKey(g.key)); err != nil {
		g.log.Fatal("GMAP client | %v", err.Error())
		signalExit()
	} else {
		g.gc = c
	}
	return &g
}

func (g *geoCode) Code(loc *Location, cachePolicy string) ([]*Location, error) {
	if g == nil {
		return nil, BOUND_REF_NIL
	}
	start := time.Now()
	g.log.PushScope("Code")
	defer g.log.PopScope()

	var res []*Location
	r := maps.GeocodingRequest{}
	r.Address = strJoinIfNotEmpty(",", loc.Name, loc.Region, loc.PostCode, loc.Country)
	if loc.ValidLatLon() && !loc.ZeroLatLon() {
		r.LatLng = &maps.LatLng{Lat: float64(loc.Lat()), Lng: float64(loc.Lon())}
	}

	regionCountry := strJoinIfNotEmpty(",", loc.Region, loc.Country)
	if !strings.Contains(r.Address, ",") || r.Address == regionCountry {
		if r.LatLng == nil {
			e := errors.New("no valid data to geocode")
			logGeoRequest(g.log, start, r, e)
			return nil, e
		}
	}
	arr, e := g.gc.Geocode(context.Background(), &r)
	if e != nil {
		logGeoRequest(g.log, start, r, e)
		return nil, e
	}
	res = make([]*Location, 0, len(arr)*4)
	deDupMap := make(map[string]bool)
	for _, o := range arr {
		if g.log.isDebug {
			js, _ := json.Marshal(o)
			g.log.Trace(string(js))
		}
		//cache all variants for better hits
		res = g.convAppend(deDupMap, o, true, true, res) //return only short forms
		res = g.convAppend(deDupMap, o, false, true, res)
		res = g.convAppend(deDupMap, o, true, false, res)
		res = g.convAppend(deDupMap, o, false, false, res)
	}
	if len(res) == 0 {
		g.log.Debug("NOT_FOUND | %v", loc)
	}

	logGeoRequest(g.log, start, r, nil)
	return res, nil
}

func (g *geoCode) convAppend(deDupMap map[string]bool, o maps.GeocodingResult, ct, re bool, res []*Location) []*Location {
	l := g.toLoc(&o, ct, re)
	if l != nil {
		name := l.String()
		if _, exists := deDupMap[name]; !exists {
			deDupMap[name] = true
			res = append(res, l)
		}
	}
	return res
}

func logGeoRequest(log *Logger, start time.Time, r maps.GeocodingRequest, err error) {
	took := time.Since(start).Milliseconds()
	ls := ""
	if r.Address != "" {
		ls = r.Address
	} else if r.LatLng != nil {
		if ls != "" {
			ls += " "
		}
		ls += r.LatLng.String()
	}
	ms := "%vms | %v"
	ll := LL_TRACE
	if took > 1000 {
		ll = LL_NOTICE
		ms = "SLOW " + ms
	} else if took > 200 {
		ll = LL_INFO
	} else if took > 100 {
		ll = LL_DEBUG
	}
	if err != nil {
		ll = LL_WARN
		ls += " | " + err.Error()
	}
	log.Log(ll, ms, took, ls)
}

func anyStrMatch(findArr []string, arr []string) bool {
	for _, find := range findArr {
		find = strings.ToLower(find)
		for _, a := range arr {
			if strings.EqualFold(a, find) || strings.Contains(strings.ToLower(a), find) {
				return true
			}
		}
	}
	return false
}

func findNameInComponents(o *maps.GeocodingResult, shortName bool, findArr ...string) string {
	for _, c := range o.AddressComponents {
		if anyStrMatch(findArr, c.Types) {
			if shortName && c.ShortName != "" {
				return c.ShortName
			} else {
				if c.LongName == "" {
					return c.ShortName
				}
				return c.LongName
			}
		}
	}
	return ""
}

func (g *geoCode) toLoc(o *maps.GeocodingResult, ct, re bool) *Location {
	if o == nil {
		return nil
	}
	lat := float32(o.Geometry.Location.Lat)
	lon := float32(o.Geometry.Location.Lng)
	sm := Location{_lat: &lat, _lon: &lon}
	sm.Name = findNameInComponents(o, ct,
		"locality", "neighborhood", "administrative_area_level_3", "administrative_area_level_2", "natural_feature", "establishment")
	sm.Region = findNameInComponents(o, re, "administrative_area_level_1")
	sm.Country = findNameInComponents(o, true, "country")
	sm.PostCode = findNameInComponents(o, true, "postal_code")
	if sm.Country == "" {
		g.log.Notice("Can't decode country | %v", o)
		return nil
	}
	if sm.Name == "" {
		g.log.Notice("Can't decode city | %v", o)
		return nil
	}
	sm.Snapshot()
	return &sm
}
