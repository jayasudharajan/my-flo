package main

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"golang.org/x/sync/semaphore"
)

type IPreCacher interface {
	Run(loc *Location, cachePolicy string) error
	Open()
	Close()
}

type preCache struct {
	redis     *RedisConnection
	geo       IGeoCoderCache
	sem       *semaphore.Weighted
	ctx       context.Context
	lastFlush time.Time
	log       *Logger
	state     int32
	dataDays  int64 //how many days back to keep the data
	noFlusher bool
	hrlPolicy PCachePolicy //defaults to flush but can be override
	weather   IWeatherHandler
}

const (
	ENVVAR_DISABLE_FLUSHER     = "FLO_DISABLE_FLUSHER"
	ENVVAR_DATA_DAYS           = "FLO_DATA_DAYS"
	ENVVAR_HOURLY_CACHE_POLICY = "FLO_HOURLY_CACHE_POLICY" //what logic to use when pre-caching hourly data
	DEFAULT_DATA_DAYS          = 32
)

func CreatePreCache(
	redis *RedisConnection,
	geo IGeoCoderCache,
	weather IWeatherHandler,
	log *Logger,
) IPreCacher {
	p := preCache{
		redis:     redis,
		geo:       geo,
		sem:       semaphore.NewWeighted(10),
		ctx:       context.Background(),
		lastFlush: time.Now().Truncate(time.Hour).Add(-time.Hour), //first flush will run in ~5-6min
		noFlusher: strings.ToLower(getEnvOrDefault(ENVVAR_DISABLE_FLUSHER, "")) == "true",
		dataDays:  DEFAULT_DATA_DAYS,
		weather:   weather,
		hrlPolicy: PCP_FLUSH,
		log:       log.CloneAsChild("Pre$"),
	}
	if n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_DATA_DAYS, "")); e == nil && n > 0 {
		p.dataDays = int64(n)
	}
	if cp := NewPCachePolicy(getEnvOrDefault(ENVVAR_HOURLY_CACHE_POLICY, "")); cp >= PCP_ALLOW {
		p.hrlPolicy = cp
	}
	p.log.Info("%v=%v %v=%v", ENVVAR_DATA_DAYS, p.dataDays, ENVVAR_HOURLY_CACHE_POLICY, p.hrlPolicy.String())
	return &p
}

type CacheReq struct {
	Loc    *Location
	Policy string
}

func (p *preCache) Open() {
	if p == nil {
		return
	}
	if p.noFlusher {
		p.log.Notice("Open: can't run, %v=%v", ENVVAR_DISABLE_FLUSHER, p.noFlusher)
		return
	}
	if !atomic.CompareAndSwapInt32(&p.state, 0, 1) {
		p.log.Notice("Open: can't run, already Running")
		return
	}

	p.log.Debug("Open: enter")
	p.scheduleCleanup()
	p.log.Debug("Open: exit")
}

func (p *preCache) scheduleCleanup() {
	p.log.PushScope("schClean")
	defer p.log.PopScope()

	offsetThreshold := time.Second * 1
	if p.log.isDebug {
		p.lastFlush = time.Now().UTC().Truncate(time.Hour).Add(time.Minute * -61) //force flush on first debug
	} else {
		p.lastFlush = time.Now().UTC().Truncate(time.Hour).Add(time.Minute * -57) //flush in 3 min just in-case of misses
	}
	var runs int64 = 0
	for p != nil && atomic.LoadInt32(&p.state) == 1 {
		time.Sleep(time.Second)
		start := time.Now().UTC()
		truncatedStart := start.Truncate(time.Hour)

		truncateDiff := start.Sub(truncatedStart)
		diff := truncatedStart.Sub(p.lastFlush)
		if diff >= time.Hour && truncateDiff >= offsetThreshold { //flush after the top of the UTC hour
			p.lastFlush = truncatedStart
			when := truncatedStart.Add(-time.Hour)
			if p.log.isDebug && runs == 0 {
				when = truncatedStart
			}
			go func() {
				geoHashes := p.buildHourlyCache(when) //catch last hour access & fetch next hour data
				p.cleanAllData(geoHashes)             //remove expired temperature data
			}()
			runs++
		}
	}
}

func (c *preCache) Close() {
	if c == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&c.state, 1, 0) {
		c.log.Debug("Close: closing")
	} else {
		c.log.Debug("Close: already closed")
	}
}

const DT_INPUT_UTC = "2006-01-02T15:04:05Z"

type PCachePolicy int64

const (
	PCP_OFF   = 0 //don't cache no matter what
	PCP_SKIP  = 1 //skip this run
	PCP_ALLOW = 2 //cache from the last run -1hr to now, if there's already data leave it alone (default value really)
	PCP_NEXT  = 3 //cache from the last run -1hr to now even if there's data (don't worry, we only allow 2x runes per hour)
	PCP_FIX   = 4 //go back in time (-3months) and check cache, if there are gaps, fill in the gap when needed
	PCP_FLUSH = 5 //go back in time (-3months) but re-place all cache even if it's there
)

func NewPCachePolicy(cachePolicy string) PCachePolicy {
	switch strings.ToLower(cachePolicy) {
	case "0", "false", "off", "no", "none":
		return PCP_OFF
	}
	if cacheOkWrite(cachePolicy) {
		switch strings.ToLower(cachePolicy) {
		case "flush":
			return PCP_FLUSH
		case "precache", "ahead", "fix":
			return PCP_FIX
		case "next":
			return PCP_NEXT
		}
		return PCP_ALLOW
	}
	return PCP_SKIP
}
func (p *PCachePolicy) String() string {
	if p == nil {
		return ""
	}
	switch *p {
	case PCP_FLUSH:
		return "FLUSH"
	case PCP_FIX:
		return "FIX"
	case PCP_NEXT:
		return "NEXT"
	case PCP_ALLOW:
		return "ALLOW"
	case PCP_SKIP:
		return "SKIP"
	case PCP_OFF:
		return "OFF"
	default:
		return ""
	}
}

func (p *preCache) buildHourlyCache(start time.Time) []string {
	pstart := time.Now()

	hrKey := p.geo.UsedCoordsKey(start)
	p.log.Info("ALL HOURLY build %v BEGIN", hrKey)
	cmd := p.redis._client.HKeys(hrKey)
	es := make([]error, 0)
	geoHashes := make([]string, 0)
	items := 0
	if arr, e := cmd.Result(); e == nil && len(arr) != 0 { //we got all known keys here
		for _, ck := range arr {
			if atomic.LoadInt32(&p.state) != 1 {
				break
			}
			lCmd := p.redis._client.HGet(hrKey, ck)
			if gzs, e := lCmd.Result(); e == nil && len(gzs) != 0 { //we are able to fetch the key payload
				rCmd := p.redis._client.HDel(hrKey, ck)
				if kHash, e := rCmd.Result(); e == nil && kHash != 0 { //able to remove the key! do the processing now for that key
					l := Location{}
					if e = jsonUnMarshalGz([]byte(gzs), &l); e == nil && l.ValidLatLon() {
						p.Run(&l, "next")
						geoHashes = append(geoHashes, ck)
						items++
					} else {
						es = append(es, e)
					}
				} else if e != nil {
					es = append(es, e)
				}
			} else if e != nil {
				es = append(es, e)
			}
		}
	} else if e != nil {
		es = append(es, e)
	}
	p.log.Notice("ALL HOURLY build COMPLETED %v | locs=%v took=%v | %v", hrKey, items, fmtDuration(time.Since(pstart)), geoHashes)
	return geoHashes
}

func (p *preCache) cleanAllData(geoHashes []string) {
	started := time.Now()
	if p == nil {
		return
	}
	p.log.PushScope("clnAll")
	defer p.log.PopScope()
	if len(geoHashes) == 0 {
		p.log.Debug("geoHashes are empty")
		return
	}

	allRemKeys := make([]string, 0)
	for _, gh5 := range geoHashes { //now clean up all the old tempature data once we have location keys
		if p == nil {
			return
		}
		arr := p.cleanLocTemp(gh5)
		allRemKeys = append(allRemKeys, arr...)
	}
	ll := LL_INFO
	rmln := len(allRemKeys)
	if rmln != 0 {
		ll = LL_NOTICE
	}
	p.log.Log(ll, "%vms rem=%v | %v", time.Since(started).Milliseconds(), rmln, geoHashes)
}

func (p *preCache) cleanLocTemp(gh5 string) []string { //remove temperature data that is older than needed
	if p == nil {
		return []string{}
	}
	p.log.PushScope("clnLoc", gh5)
	defer p.log.PopScope()

	tempKey := fmt.Sprintf("weather:geo:temp:{%v}", gh5)
	es := make([]error, 0)
	allRemKeys := make([]string, 0)

	cmds := p.redis._client.HKeys(tempKey)
	if keys, e := cmds.Result(); e == nil && len(keys) != 0 {
		pastDur := time.Duration((p.dataDays+1)*-24) * time.Hour
		cutOffDt := time.Now().UTC().Truncate(time.Hour * 24).Add(pastDur)
		rems := make([]string, 0)
		pm := make(map[string]bool)

		for _, k := range keys {
			if k == "" || k[0:1] != "2" {
				continue
			}
			dt, e := time.Parse("20060102", k)
			if e != nil || dt.Year() < 2000 || dt.After(cutOffDt) {
				es = append(es, e)
				continue
			}
			if _, ok := pm[k]; !ok { //de-dup to ensure we only rm once
				pm[k] = true
				rems = append(rems, k)
			}
		}
		if len(rems) != 0 { //remove these keys
			e := p.redis.HDelete(tempKey, rems...)
			es = append(es, e)
			p.log.Debug("removed %v", rems)
			allRemKeys = append(allRemKeys, rems...)
		}
	} else if e != nil {
		es = append(es, e)
	}
	p.log.IfWarn(wrapErrors(es))
	return allRemKeys
}

func (h *preCache) preCheck(loc *Location, cachePolicy string, started time.Time) (policy PCachePolicy, key string, lastRun time.Time) {
	started = started.UTC()
	h.log.PushScope("check")
	defer h.log.PopScope()

	cp := NewPCachePolicy(cachePolicy)
	n := strJoinIfNotEmpty(",", loc.Name, loc.Region, loc.PostCode, loc.Country)
	k := strings.ToLower(fmt.Sprintf("weather:precache:{%v}", n))
	if cp < PCP_ALLOW {
		h.log.Debug("%v (%v) %v | %v", cp.String(), cachePolicy, k, loc)
		return cp, k, time.Unix(0, 0)
	}
	if !loc.ValidLatLon() {
		h.log.Debug("BAD_COORDINATES | %v -> PCP_SKIP %v (%v,%v) | %v", cp.String(), k, loc.Lon(), loc.Lat(), loc)
		return PCP_SKIP, k, time.Unix(0, 0)
	}

	dts, e := h.redis.Get(k)
	if e == nil { //key exists
		if lastRun, e = time.Parse(DT_INPUT_UTC, dts); e == nil && lastRun.Year() > 2000 {
			lastRun = lastRun.UTC()
		} else { //can't parse lastRun, will reset to now
			oldLast, lastRun := lastRun, time.Now().UTC().Truncate(time.Minute*-30) //reset to 30 min ago
			h.log.Warn("Can't parse lastRun %v, setting to (-30min) %v", oldLast, lastRun)
		}
		sinceLastRun := started.Sub(lastRun)
		if cp >= PCP_FIX { //fix, flush or higher
			//do nothing here & return CP as is, will allow re-run NOW
		} else if cp >= PCP_ALLOW { //will check for duplicates
			if h.log.isDebug {
				sinceLastRun = time.Duration(61 * time.Minute) //force run on debug
			}
			if sinceLastRun.Minutes() < 30 { //progressive downgrades
				ogCp := cp
				cp = PCachePolicy(int32(cp) - 1)
				h.log.Debug("%v -> %v because only %v elapsed (30 min) since last run %v | %v",
					ogCp.String(), cp.String(), fmtDuration(sinceLastRun), lastRun.Format(DT_INPUT_UTC), loc)
			} else if sinceLastRun.Minutes() < 15 { //downgrade cache run even more
				ogCp := cp
				cp = PCachePolicy(int32(cp) - 2)
				h.log.Debug("%v -> %v because only %v elapsed (15 min) since last run %v | %v",
					ogCp.String(), cp.String(), fmtDuration(sinceLastRun), lastRun.Format(DT_INPUT_UTC), loc)
			}
		}
		if cp >= PCP_ALLOW {
			if ok, _ := h.doubleCheckSet(k, started, lastRun); !ok {
				cp = PCP_SKIP //another thread picked it up
			}
		}
	} else if e.Error() == "redis: nil" { //first run ever for this location
		if ok, _ := h.doubleCheckSet(k, started, lastRun); !ok {
			cp = PCP_SKIP //another thread picked it up
		} else {
			cp = PCP_FLUSH
			h.log.Info("FIRST %v | %v", k, started)
		}
	} else { //can't get the key, will do nothing
		cp = PCP_OFF
		h.log.IfErrorF(e, "get lastRun %v", k) //redis error for real
	}
	h.log.Info("%v %v | lastRun=%v", cp.String(), k, lastRun.Format(DT_INPUT_UTC))
	return cp, k, lastRun
}

func (h *preCache) doubleCheckSet(k string, started, lastRun time.Time) (bool, error) {
	checkKey := k + lastRun.Format(":20060102-1504")
	exp := 60 * 10
	if h.log.isDebug {
		exp = 60 * 2
	}
	if ok, e := h.redis.SetNX(checkKey, time.Now().UTC().Format(DT_INPUT_UTC), exp); e == nil && ok { //check key doesn't exists
		_, e = h.redis.Set(k, started.Format(DT_INPUT_UTC), 0) //this thread will run & set set last run
		h.log.IfErrorF(e, "doubleCheckSet: save %v lastRun=%v", k, lastRun.Format(time.RFC3339))
		return true, nil
	} else {
		return false, h.log.IfErrorF(e, "doubleCheckSet: compare %v lastRun=%v", k, lastRun.Format(time.RFC3339))
	}
}

func (h *preCache) Run(loc *Location, cachePolicy string) error {
	if h == nil || loc == nil {
		return errors.New("ref binding or loc is nil")
	}
	started := time.Now()
	defer panicRecover(h.log, "Run: %v", loc.String())
	h.log.PushScope("Run")
	defer h.log.PopScope()

	policy, cacheKey, lastRun := h.preCheck(loc, cachePolicy, started) //or else geo code will be slammed
	if policy < PCP_ALLOW {
		return nil
	}

	var tail, startAt, endAt time.Time
	if policy >= PCP_FIX { //fix || flush+
		tail = started.UTC().Truncate(time.Hour * 24)
		endAt = tail.Add(time.Duration(h.dataDays*-24) * time.Hour) //~3 months
		if policy == PCP_FLUSH {
			cachePolicy = "flush"
		}
	} else { //allow || next
		tail = started.UTC().Truncate(time.Hour)
		endAt = lastRun.UTC().Truncate(time.Hour).Add(time.Hour * -24) //rebuild the day before too
		if policy == PCP_NEXT {
			cachePolicy = h.hrlPolicy.String()
		}
	}
	startAt = tail
	if lastRun.Before(tail) && lastRun.After(endAt) {
		endAt = lastRun
	}
	runDur := startAt.Sub(endAt)
	if durDays := math.Ceil(runDur.Hours() / 24); durDays > float64(h.dataDays+3) {
		return h.log.Warn("Too many days (%v) in range %v - %v", durDays, startAt.Format(DT_INPUT_UTC), endAt.Format(DT_INPUT_UTC))
	}
	h.log.Debug("START %v | %v - %v | %v", cacheKey, startAt.Format(DT_INPUT_UTC), endAt.Format(DT_INPUT_UTC), loc)

	es := make([]error, 0)
	batches, rows := 0, 0
	for tail.After(endAt) {
		head := tail.Add(time.Duration(WTR_STK_MAX_DAYS) * time.Hour * -24)
		if head.Before(endAt) {
			head = endAt
		}
		ar := AddressReq{
			Start:    head.UTC(),
			End:      tail.UTC(),
			City:     strings.ToLower(loc.Name),
			Region:   strings.ToLower(loc.Region),
			Country:  strings.ToLower(loc.Country),
			PostCode: strings.ToLower(loc.PostCode),
			Cache:    cachePolicy,
		}

		h.sem.Acquire(h.ctx, 1)
		rs, e := h.weather.fetchAddr(&ar)
		h.sem.Release(1)

		if e != nil {
			h.log.IfError(e)
			es = append(es, e)
		}
		batches++
		if rs != nil {
			rows += len(rs.Items)
		}
		tail = head.Add(time.Hour * -24)
		time.Sleep(250 * time.Millisecond)
	}
	h.log.Info("DONE %v | %v - %v | took=%v loops=%v rows=%v $=%v lastRun=%v",
		cacheKey, startAt.Format(DT_INPUT_UTC), endAt.Format(DT_INPUT_UTC),
		fmtDuration(time.Since(started)), batches, rows, cachePolicy, lastRun.Format(DT_INPUT_UTC))
	return wrapErrors(es)
}
