package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"sync/atomic"
	"time"

	"github.com/mmcloughlin/geohash"
)

type ICacheBootstraper interface {
	DiskLoad()
	Open()
	Close()
}

type cacheBootstrap struct {
	token   string    //auth token
	apiRoot string    //base path
	macFile string    //mac address file (new line per mac)
	hc      *httpUtil //http client
	redis   *RedisConnection
	bootKey string
	geo     IGeoCoder
	pre     IPreCacher
	log     *Logger
	state   int32 //0= not started, 1= running, 2= stopped
}

const ENVVAR_API_ROOT = "FLO_API_ROOT"
const ENVVAR_API_TOKEN = "FLO_API_TOKEN"
const ENVVAR_BOOTSTRAP_MAC_FILE = "FLO_BOOTSTRAP_MAC_FILE"
const ENVVAR_BOOTSTRAP_REDIS_KEY = "FLO_BOOTSTRAP_REDIS_KEY"

func CreateBootstrap(pre IPreCacher, geo IGeoCoder, redis *RedisConnection, log *Logger) ICacheBootstraper {
	cb := cacheBootstrap{
		pre:     pre,
		geo:     geo,
		redis:   redis,
		log:     log.CloneAsChild("bo0t3r"),
		bootKey: getEnvOrDefault(ENVVAR_BOOTSTRAP_REDIS_KEY, ""),
		token:   getEnvOrDefault(ENVVAR_API_TOKEN, ""),
		apiRoot: getEnvOrDefault(ENVVAR_API_ROOT, ""),
		macFile: getEnvOrDefault(ENVVAR_BOOTSTRAP_MAC_FILE, ""),
	}
	if cb.bootKey == "" {
		cb.log.Info("%v missing, skipping this", ENVVAR_BOOTSTRAP_REDIS_KEY)
		return nil
	}
	if cb.macFile != "" {
		if st, e := os.Stat(cb.macFile); e != nil || st == nil {
			cb.log.Notice("can't find %v, not running bootstrap", cb.macFile)
			return nil
		}
	}
	if cb.apiRoot == "" || cb.token == "" {
		cb.log.Notice("BOTH %v & %v env are required also, not running bootstrap", ENVVAR_API_ROOT, ENVVAR_API_TOKEN)
		return nil
	}
	cb.hc = CreateHttpUtil(cb.token, cb.log, time.Second*9)
	return &cb
}

func (b *cacheBootstrap) Open() {
	if b == nil {
		return
	}
	b.log.Debug("Open: enter")
	if atomic.CompareAndSwapInt32(&b.state, 0, 1) {
		var lastCheck time.Time
		for b != nil && atomic.LoadInt32(&b.state) == 1 {
			if time.Since(lastCheck) >= time.Minute {
				if n, e := b.getListSize(); e == nil && n > 0 {
					b.Run()
				}
				lastCheck = time.Now()
			}
			time.Sleep(time.Second)
		}
	}
	b.log.Debug("Open: exit")
}

func (b *cacheBootstrap) Close() {
	if b == nil {
		return
	}
	b.log.Debug("Close: enter & exit")
	//nothing to do here, only doing this so we fit IOpenCloser interface
}

// load a local file that contains mac addresses (1 per line) to a redis list
// meant to be used locally & not on the cloud
func (b *cacheBootstrap) DiskLoad() {
	if b == nil {
		return
	}
	started := time.Now()
	b.log.PushScope("DiskLoad")
	defer b.log.PopScope()
	if b.macFile == "" {
		b.log.Notice("skipping, macFile missing")
		return
	}

	b.log.Info("Starting")
	file, e := os.Open(b.macFile)
	if e != nil {
		b.log.IfError(e)
		return
	}
	scanner := bufio.NewScanner(file)
	dc := 0
	rows := 0
	for scanner.Scan() {
		rows++
	}
	b.log.Notice("Found %v rows in %v", rows, b.macFile)

	_, e = file.Seek(0, 0) //start from the top
	if e != nil {
		b.log.IfFatal(e)
		return
	}
	defer file.Close()

	scanner = bufio.NewScanner(file)
	batch := make([]interface{}, 30)
	i := 0
	for scanner.Scan() {
		dc++
		mac := strings.TrimSpace(scanner.Text())
		if mac == "" {
			continue
		}
		batch[i] = mac
		i++
		if i%30 == 0 { //flush
			cmd := b.redis._client.LPush(b.bootKey, batch...)
			if b.log.IfWarn(cmd.Err()) == nil {
				b.log.Debug("Stored %v/%v MACS", dc, rows)
			}
			i = 0
		}
	}
	b.log.IfWarn(scanner.Err())
	b.log.Notice("DONE! took %v, processed %v", fmtDuration(time.Since(started)), dc)
}

func (b *cacheBootstrap) getListSize() (size int64, e error) {
	cmd := b.redis._client.LLen(b.bootKey)
	if size, e = cmd.Result(); e != nil {
		if e.Error() == "redis: nil" {
			return 0, nil
		} else {
			return 0, b.log.IfWarn(e)
		}
	} else if size == 0 {
		if b.log.isDebug {
			b.log.Debug("%v is EMPTY", b.bootKey)
		}
		return 0, nil
	}
	return size, nil
}

// will take an item from redis queue until there are no more to process, everything is done in a single thread
func (b *cacheBootstrap) Run() {
	if b == nil {
		return
	}
	started := time.Now()
	b.log.PushScope("Run")
	defer b.log.PopScope()
	b.log.Notice("Start")

	total, _ := b.getListSize()
	b.log.Info("Found %v items in list", total)
	if total == 0 {
		return
	}

	oc, found := 0, total
	locCount := 0
	counter := 0
	for total > 0 && atomic.LoadInt32(&b.state) == 1 {
		cmd := b.redis._client.LPop(b.bootKey)
		counter++
		if mac, e := cmd.Result(); e != nil {
			if e.Error() == "redis: nil" { //EOF
				break
			} else {
				if n, _ := b.getListSize(); n == 0 { //EOF
					break
				} else {
					b.log.IfError(e)
				}
			}
		} else if len(mac) != 0 {
			if ok, lc := b.Boot(mac); ok {
				locCount += lc
				oc++
				if counter%10 == 0 {
					n, _ := b.getListSize()
					b.log.Notice("PROCESSED %v, OK %v still %v left", counter, oc, n)
				}
			}
		}
		total--
	}
	b.log.Notice("DONE! took %v, processed %v, OK=%v, possible locs=%v", fmtDuration(time.Since(started)), found, oc, locCount)
}

func (b *cacheBootstrap) Boot(mac string) (bool, int) {
	if b == nil {
		return false, 0
	}
	b.log.PushScope("Boot")
	defer b.log.PopScope()

	resp := DevResp{}
	url := fmt.Sprintf("%v/devices?macAddress=%v&expand=location", b.apiRoot, mac)
	if e := b.hc.Do("GET", url, nil, nil, &resp); e != nil {
		time.Sleep(time.Millisecond * 500)
		return false, 0
	}
	if resp.Location.Id == "" {
		b.log.Debug("Skipping %v", mac)
		return false, 0
	}
	l := resp.Location.ToLocation()
	if locs, e := b.geo.Code(l, "flush"); e == nil && len(locs) != 0 {
		lm := make(map[string]*Location)
		for _, ll := range locs {
			gh5 := geohash.EncodeWithPrecision(float64(ll.Lat()), float64(ll.Lon()), 5)
			if _, ok := lm[gh5]; !ok {
				lm[gh5] = ll
			}
		}
		i := 0
		for _, ll := range lm {
			if atomic.LoadInt32(&b.state) != 1 {
				return false, i
			}
			e = b.pre.Run(ll, "flush")
			i++
			if i > 4 {
				return true, i
			}
		}
		return true, i
	} else {
		time.Sleep(time.Millisecond * 200)
	}
	return false, 0
}

type DevResp struct {
	Location DevLoc `json:"location"`
}

type DevLoc struct {
	Id       string `json:"id"`
	Street   string `json:"address"`
	City     string `json:"city"`
	Region   string `json:"state"`
	Country  string `json:"country"`
	PostCode string `json:"postalCode"`
	TZ       string `json:"timeZone"`
}

func (d *DevLoc) ToLocation() *Location {
	return &Location{
		Name:     d.City,
		Region:   d.Region,
		Country:  d.Country,
		PostCode: d.PostCode,
		TimeZone: d.TZ,
	}
}
