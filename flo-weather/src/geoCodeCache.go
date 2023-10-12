package main

import (
	"fmt"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/go-redis/redis"

	"github.com/mmcloughlin/geohash"

	"googlemaps.github.io/maps"
)

type IGeoCoderCache interface {
	Open()
	Close()
	Code(loc *Location, cachePolicy string) ([]*Location, error)
	UsedCoordsKey(dt time.Time) string
	LocKey(country, region string) string
}

func CreateGeoCoderWithCache(redis *RedisConnection, log *Logger) IGeoCoderCache {
	g := CreateGeoCode(log)
	c := CreateGeoCodeCache(g, redis, log)
	return c
}

type geoCodeCache struct {
	base       IGeoCoder
	redis      *RedisConnection
	coordsUsed map[string]*Location
	coordsMx   sync.RWMutex
	lastFlush  time.Time
	cacheOnly  bool
	state      int32 //0 stopped, 1 running
	log        *Logger
}

func CreateGeoCodeCache(base IGeoCoder, redis *RedisConnection, log *Logger) IGeoCoderCache {
	g := geoCodeCache{
		base:       base,
		redis:      redis,
		lastFlush:  time.Now().Add(time.Minute - 3), //first flush will run in 2min
		coordsUsed: make(map[string]*Location),
		coordsMx:   sync.RWMutex{},
		cacheOnly:  strings.ToLower(getEnvOrDefault(ENVVAR_CACHE_ONLY, "")) == "true",
		log:        log.CloneAsChild("geo"),
	}
	if g.log.isDebug { //less wait time to debug the first run
		g.lastFlush = time.Now().Add(time.Minute*-4 + (time.Second * 45))
	}
	return &g
}

func (g *geoCodeCache) State() (int32, string) {
	if g == nil {
		return 0, ""
	}
	switch n := atomic.LoadInt32(&g.state); n {
	case 1:
		return n, "Opened"
	default:
		return n, "Closed"
	}
}

func (g *geoCodeCache) Open() {
	if g == nil {
		return
	}
	if !atomic.CompareAndSwapInt32(&g.state, 0, 1) {
		_, st := g.State()
		g.log.Notice("Open: can't, already %v", st)
		return
	}
	g.log.Debug("Open: enter")
	sleepDur := time.Second
	diffFLushDur := time.Minute * 5

	if g.log.isDebug {
		diffFLushDur = time.Second * 30
		sleepDur = time.Second * 5
	}
	for g != nil && atomic.LoadInt32(&g.state) == 1 {
		time.Sleep(sleepDur)
		start := time.Now()
		diff := start.Sub(g.lastFlush)

		if diff >= diffFLushDur { //flush every 5min; do it here
			g.lastFlush = start
			lm := make(map[string]*Location)
			g.coordsMx.RLock()
			ml := len(g.coordsUsed)
			g.coordsMx.RUnlock()
			if ml > 0 {
				g.coordsMx.Lock()
				for k, l := range g.coordsUsed {
					lm[k] = l
					delete(g.coordsUsed, k)
				}
				g.coordsMx.Unlock()
				g.flushStoreMap(start, lm)
			}
		}
	}

	if g != nil {
		g.log.Debug("Open: exit")
	}
}

func (g *geoCodeCache) Close() {
	if g == nil {
		return
	}
	if !atomic.CompareAndSwapInt32(&g.state, 1, 0) {
		_, st := g.State()
		g.log.Notice("Close: can't, already %v", st)
		return
	}

	g.log.Debug("Close: enter")
	g.coordsMx.Lock()
	g.flushStoreMap(time.Now(), g.coordsUsed) //last flush
	g.coordsMx.Unlock()
	g.log.Debug("Close: exit")
}

func (g *geoCodeCache) UsedCoordsKey(dt time.Time) string {
	dt = dt.UTC().Truncate(time.Hour)
	dts := dt.Format("2006-01-02T15:04:00Z")
	return fmt.Sprintf("geo:hourly:coords:{%v}", dts)
}

func (g *geoCodeCache) flushStoreMap(dt time.Time, lm map[string]*Location) {
	g.log.PushScope("storeMap")
	defer g.log.PopScope()

	hrKey := g.UsedCoordsKey(dt)
	if len(lm) == 0 {
		g.log.Debug("SKIP_MAP %v -> [] @ %v", hrKey, dt.Format(DT_FMT_NO_TZ))
		return
	}

	keys := make([]string, 0, len(lm))
	vmap := make(map[string]interface{})
	es := make([]error, 0)
	for k, v := range lm {
		buf, e := jsonMarshalGz(v)
		if e != nil {
			es = append(es, e)
		}
		vmap[k] = buf
		keys = append(keys, k)
		if len(vmap) >= 30 { //flush in batches of 30 keys
			ok, e := g.redis.HMSet(hrKey, vmap, 0)
			if !ok && e != nil {
				es = append(es, e)
			}
			vmap = make(map[string]interface{})
		}
	}
	if len(vmap) > 0 { //last batch
		ok, e := g.redis.HMSet(hrKey, vmap, 0)
		if !ok && e != nil {
			es = append(es, e)
		}
	}
	g.log.Info("%v -> %v @ %v", hrKey, keys, dt.Format(DT_FMT_NO_TZ))
	g.log.IfWarn(wrapErrors(es))
}

func (g *geoCodeCache) appendUsedCoords(locs []*Location, cachePolicy string) {
	if len(locs) == 0 {
		return
	}
	if cp := NewPCachePolicy(cachePolicy); cp != PCP_ALLOW {
		return
	}
	for _, l := range locs {
		if !l.ValidLatLon() {
			continue
		}
		gh5 := geohash.EncodeWithPrecision(float64(l.Lat()), float64(l.Lon()), 5)
		g.coordsMx.RLock()
		if _, ok := g.coordsUsed[gh5]; !ok {
			g.coordsMx.RUnlock()
			g.coordsMx.Lock()
			g.coordsUsed[gh5] = l
			g.coordsMx.Unlock()
		} else {
			g.coordsMx.RUnlock()
		}
	}
}

func (g *geoCodeCache) canReadCache(cachePolicy string) bool {
	readOk := cacheOkRead(cachePolicy)
	cp := NewPCachePolicy(cachePolicy)
	if g.cacheOnly || (readOk && cp != PCP_FLUSH) {
		switch strings.ToLower(cachePolicy) {
		case "no-geo", "flush-geo", "fix-geo":
			return false
		default:
			return true
		}
	}
	return false
}

func (g *geoCodeCache) Code(loc *Location, cachePolicy string) ([]*Location, error) {
	start := time.Now()
	g.log.PushScope("Code")
	defer g.log.PopScope()

	if res, ok := g.cacheFetch(loc); ok && len(res) != 0 {
		g.appendUsedCoords(res, cachePolicy)
		return res, nil
	} else if g.cacheOnly && !strings.EqualFold(cachePolicy, "noloc") {
		go func(l *Location, policy string) {
			defer panicRecover(g.log, "Code cacheMissed go Func: %v %v", policy, l.String())
			found, e := g.base.Code(l, policy)
			g.appendUsedCoords(found, policy)
			if e == nil {
				go g.cacheStore(l, found) //store the og
			}
		}(loc, cachePolicy)

		r := maps.GeocodingRequest{Address: strJoinIfNotEmpty(",", loc.Name, loc.Region, loc.PostCode, loc.Country)}
		if loc.ValidLatLon() {
			r.LatLng = &maps.LatLng{Lat: float64(loc.Lat()), Lng: float64(loc.Lon())}
		}
		logGeoRequest(g.log, start, r, nil)
		return res, nil
	}
	found, e := g.base.Code(loc, cachePolicy)
	g.appendUsedCoords(found, cachePolicy)
	if e == nil {
		go g.cacheStore(loc, found) //store the og
	}
	return found, e
}

func (g *geoCodeCache) cacheFetch(l *Location) ([]*Location, bool) {
	started := time.Now()
	g.log.PushScope("$Fetch")
	defer g.log.PopScope()

	keys := g.cacheKeys(l)
	res := make([]*Location, 0)
	found := 0
	missedKeys := make([]string, 0, len(keys))
	for _, k := range keys {
		if gzs, e := g.redis.Get(k); e == nil && len(gzs) != 0 {
			er := jsonUnMarshalGz([]byte(gzs), &res)
			if er != nil {
				g.log.IfWarn(er)
			} else if len(res) != 0 {
				found++
				break
			}
		}
		missedKeys = append(missedKeys, k)
	}
	if rl := len(res); rl != 0 {
		if len(missedKeys) > 1 {
			go g.cacheStore(l, res) //re-store cache for faster geo hits, maybe rule changed since last store
		}
		clean := make([]*Location, 0, rl)
		for _, r := range res {
			if r.ValidLatLon() {
				clean = append(clean, r)
			}
		}
		res = clean
	}

	st := "FOUND"
	if found == 0 {
		st = "NOT_FOUND"
	}
	g.log.Debug("%v %vms r=%v | %v", st, time.Since(started).Milliseconds(), len(res), l.String())
	return res, found != 0
}

func (g *geoCodeCache) cacheKeys(l *Location) []string {
	keys := make([]string, 0, 4)
	keys = append(keys, strJoinIfNotEmpty(",", l.Name, l.Region, l.PostCode, l.Country))
	if len(l.PostCode) == 5 && l.Country == "" {
		l.Country = "us" //infer country
	}
	if l.PostCode != "" && (l.Region != "" || l.Country != "") {
		keys = append(keys, strJoinIfNotEmpty(",", l.Region, l.PostCode, l.Country))
	}
	keys = append(keys, strJoinIfNotEmpty(",", l.Name, l.Region, l.Country))
	keys = append(keys, strJoinIfNotEmpty(",", l.Name, l.Region))

	regionCountryOnly := strJoinIfNotEmpty(",", l.Region, l.Country)
	kmap := make(map[string]int)
	for i, n := range keys {
		if !strings.Contains(n, ",") || n == regionCountryOnly {
			continue
		}
		k := strings.ToLower(fmt.Sprintf("geo:name:{%v}", n))
		kmap[k] = i
	}
	if l.ValidLatLon() {
		lat, lon := l.Lat(), l.Lon()
		if true { //exact within .2km accuracy
			gh6 := geohash.EncodeWithPrecision(float64(lat), float64(lon), 6)
			k := fmt.Sprintf("geo:hash:{%v}", gh6)
			kmap[k] = -2
		}
		if true { //semi exact with 4km accuracy
			gh5 := geohash.EncodeWithPrecision(float64(lat), float64(lon), 5)
			k := fmt.Sprintf("geo:hash:{%v}", gh5)
			kmap[k] = -1 //prioritize coordinates over names if we can help it
		}
	}
	mapLen := len(kmap)
	if mapLen > 1 { //remove ambiguous location if we can help it
		cityCountryOnly := strJoinIfNotEmpty(",", l.Name, l.Country)
		k := strings.ToLower(fmt.Sprintf("geo:name:{%v}", cityCountryOnly))
		if _, ok := kmap[k]; ok {
			delete(kmap, k)
			mapLen--
		}
	}
	res := make([]string, mapLen)
	j := 0
	for k, _ := range kmap {
		res[j] = k
		j++
	}
	sort.Slice(res, func(i, j int) bool { //longer keys first for better accuracy on fetch
		ki, kj := res[i], res[j]
		return kmap[ki] < kmap[kj]
	})
	return res
}

func (g *geoCodeCache) cacheStore(l *Location, res []*Location) {
	if g == nil || l == nil {
		return
	}
	started := time.Now()
	defer panicRecover(g.log, "cacheStore: %v", l.String())
	g.log.PushScope("$Store")
	defer g.log.PopScope()

	keys := g.cacheKeys(l)
	if res == nil {
		res = []*Location{}
	}
	gz, e := jsonMarshalGz(res) //gz the results
	if e != nil {
		g.log.IfErrorF(e, "", l)
		return
	}
	for _, k := range keys {
		_, e := g.redis.Set(k, gz, 0) //store in denormalized in strings
		g.log.IfErrorF(e, k)
	}

	lMap := make(map[string][]*redis.GeoLocation) //batch calls to geo add
	for _, loc := range res {
		if !loc.ValidLatLon() {
			continue
		}
		lk := g.LocKey(loc.Country, loc.Region)
		gl := redis.GeoLocation{
			Name:      strings.ToLower(loc.Name),
			Longitude: float64(loc.Lon()),
			Latitude:  float64(loc.Lat()),
		}
		if locArr, ok := lMap[lk]; ok {
			lMap[lk] = append(locArr, &gl)
		} else {
			lMap[lk] = []*redis.GeoLocation{&gl}
		}
	}
	for k, arr := range lMap {
		cmd := g.redis._client.GeoAdd(k, arr...) //save to nearby locations
		g.log.IfError(cmd.Err())
	}
	g.log.Debug("%vms k=%v | %v", time.Since(started).Milliseconds(), len(res), l)
}

func (g *geoCodeCache) LocKey(country, region string) string {
	return strings.ToLower(fmt.Sprintf("geo:loc:{%v:%v}", country, region))
}
