package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"golang.org/x/sync/semaphore"
)

const (
	ENVVAR_KAFKA_PRESENCE_TOPIC = "FLO_KAFKA_PRESENCE_TOPIC"
	ENVVAR_KAFKA_CN             = "FLO_KAFKA_CN"
	ENVVAR_KAFKA_GROUP          = "FLO_KAFKA_GROUP_ID"
	ENVVAR_PRESENCE_CONSUMERS   = "FLO_PRESENCE_CONSUMERS"
	ENVVAR_PRESENCE_MAX_SEC     = "FLO_PRESENCE_MAX_SEC"
)

type presenceWorker struct {
	redis     *RedisConnection
	kaf       *KafkaConnection
	kafTopic  string
	kafGroup  string
	kafSub    *KafkaSubscription
	log       *Logger
	state     int32 //0=closed, 1=opened
	sem       *semaphore.Weighted
	maxJobDur time.Duration
	fetchAddr func(req *AddressReq) (*TempHistoryResp, error)
	pubGw     *httpUtil
	pubGwUri  string
	dataDays  int64
}

var (
	_pubGwClient *httpUtil
	_pubGwLock   = sync.Mutex{}
)

func initPubGwClient(log *Logger, timeOut time.Duration) *httpUtil {
	if _pubGwClient == nil { //double check lock, lazy singleton
		_pubGwLock.Lock()
		defer _pubGwLock.Unlock()
		if _pubGwClient == nil {
			jwt := getEnvOrDefault(ENVVAR_API_TOKEN, "")
			if len(jwt) < 12 {
				log.Fatal("initPubGwClient: invalid %v", ENVVAR_API_TOKEN)
				signalExit()
			}
			_pubGwClient = CreateHttpUtil(jwt, log, timeOut)
		}
	}
	return _pubGwClient
}

func CreatePresenceWorker(
	redis *RedisConnection,
	fetchAddr func(req *AddressReq) (*TempHistoryResp, error),
	log *Logger) *presenceWorker {

	l := log.CloneAsChild("presence")
	if workers, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_PRESENCE_CONSUMERS, "16")); workers <= 0 {
		l.Warn("%v is %v :. worker is DISABLED", ENVVAR_PRESENCE_CONSUMERS, workers)
		return nil
	} else if gwUri := getEnvOrDefault(ENVVAR_API_ROOT, ""); strings.Index(gwUri, "http") != 0 {
		l.Fatal("%v is blank", ENVVAR_API_ROOT)
		signalExit()
		return nil
	} else if kcn := getEnvOrDefault(ENVVAR_KAFKA_CN, ""); kcn == "" {
		l.Fatal("%v is blank", ENVVAR_KAFKA_CN)
		signalExit()
		return nil
	} else if kaf, e := OpenKafka(kcn, nil); e != nil {
		l.IfFatalF(e, "OpenKafka failed")
		signalExit()
		return nil
	} else {
		w := presenceWorker{
			redis:     redis,
			kaf:       kaf,
			kafTopic:  getEnvOrDefault(ENVVAR_KAFKA_PRESENCE_TOPIC, "presence-activity-v1"),
			kafGroup:  getEnvOrDefault(ENVVAR_KAFKA_GROUP, "weather-presence-group"),
			log:       l,
			sem:       semaphore.NewWeighted(int64(workers)),
			maxJobDur: time.Duration(15) * time.Second,
			fetchAddr: fetchAddr,
			pubGwUri:  gwUri,
			dataDays:  DEFAULT_DATA_DAYS,
		}
		if maxS, _ := strconv.Atoi(getEnvOrDefault(ENVVAR_PRESENCE_MAX_SEC, "")); maxS > 0 {
			w.maxJobDur = time.Duration(int64(maxS)) * time.Second
		}
		w.pubGw = initPubGwClient(w.log, w.maxJobDur/2)
		if n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_DATA_DAYS, "")); e == nil && n > 0 {
			w.dataDays = int64(n)
		} else {
			w.dataDays = 31
		}
		l.Debug("Create OK.  Using topic '%v' & group '%v'", w.kafTopic, w.kafGroup)
		return &w
	}
}

func (w *presenceWorker) Open() {
	if w == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&w.state, 0, 1) {
		w.log.Debug("Open: begin")
		if sub, e := w.kaf.Subscribe(w.kafGroup, []string{w.kafTopic}, w.consumeMessage); e != nil {
			w.log.IfErrorF(e, "Open: subscribe error")
			atomic.StoreInt32(&w.state, 0)
		} else {
			w.kafSub = sub
			w.log.Info("Open: Subscribe ok to topic '%v' as %v", w.kafTopic, w.kafGroup)
		}
	} else {
		w.log.Warn("Open: already running")
	}
}

func (w *presenceWorker) Close() {
	if w == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&w.state, 1, 0) {
		w.log.Debug("Close: begin")
		if w.kafSub != nil {
			w.kafSub.Close()
			time.Sleep(time.Second) //wait a little
		}
		w.log.Info("Close: completed OK")
	} else {
		w.log.Warn("Close: already running")
	}
}

func (w *presenceWorker) consumeMessage(item *kafka.Message) {
	if w == nil || item == nil || len(item.Value) == 0 {
		return
	}

	defer panicRecover(w.log, "consumeMessage: %v", item.Value)
	summary, ok := w.parseAsUserPresence(item.Value)
	if !ok {
		summary, ok = w.parseAsSummary(item.Value)
	}
	if summary != nil {
		cx := presenceContext{
			log:    w.log.CloneAsChild("bg"),
			msg:    summary,
			worker: w,
		}
		if e := cx.acquireSem(); e == nil {
			go func(pc *presenceContext) {
				defer panicRecover(pc.log, "cacheLocations wrapper func: %v", summary)
				defer pc.releaseSem()
				pc.cacheLocations()
			}(&cx)
		}
	}
}

func (w *presenceWorker) parseAsSummary(buf []byte) (*PresenceSummary, bool) {
	sum := PresenceSummary{}
	if e := json.Unmarshal(buf, &sum); e != nil {
		w.log.IfWarnF(e, "parseAsSummary: deserialization error | %v", buf)
	} else if sum.AccountId != "" {
		return &sum, len(sum.Locations) != 0
	}
	return nil, false
}

func (w *presenceWorker) parseAsUserPresence(buf []byte) (*PresenceSummary, bool) {
	userMsg := UserPresence{}
	if e := json.Unmarshal(buf, &userMsg); e != nil {
		w.log.IfWarnF(e, "parseAsUserPresence: deserialization error | %v", buf)
	} else if strings.EqualFold(userMsg.Type, "user") { //process as user info
		return userMsg.ToSummary()
	}
	return nil, false
}

type UserPresence struct {
	Id       string    `json:"id,omitempty"`
	Type     string    `json:"type"`
	Action   string    `json:"action,omitempty"`
	TTLS     int64     `json:"ttl,omitempty"`
	UserInfo *UserInfo `json:"userData,omitempty"`
}

type UserInfo struct {
	Id        string                 `json:"id"`
	Locations []*UserLocationSummary `json:"locations,omitempty"`
	Account   *IdEntity              `json:"account,omitempty"`
}

type UserLocationSummary struct {
	Id       string           `json:"id"`
	TimeZone string           `json:"timezone,omitempty"`
	Country  string           `json:"country,omitempty"`
	Devices  []*DeviceSummary `json:"devices,omitempty"`
}

type DeviceSummary struct {
	Id      string `json:"id"`
	MacAddr string `json:"macAddress,omitempty"`
	Model   string `json:"deviceModel,omitempty"`
	Type    string `json:"deviceType,omitempty"`
	FwVer   string `json:"fwVersion,omitempty"`
	Serial  string `json:"serialNumber,omitempty"`
}

type IdEntity struct {
	Id string `json:"id"`
}

func (userMsg *UserPresence) ToSummary() (*PresenceSummary, bool) {
	if userMsg.UserInfo == nil {
		return nil, false
	} else if len(userMsg.UserInfo.Locations) == 0 || userMsg.UserInfo.Account == nil {
		return nil, false
	}
	locations := make(map[string]bool)
	for _, loc := range userMsg.UserInfo.Locations {
		locations[loc.Id] = true
	}
	if len(locations) != 0 {
		locIds := make([]string, 0, len(locations))
		for k, _ := range locations {
			locIds = append(locIds, k)
		}
		return &PresenceSummary{
			AccountId: userMsg.UserInfo.Account.Id,
			Locations: locIds,
			TTLS:      userMsg.TTLS,
		}, true
	}
	return nil, true
}

type PresenceSummary struct {
	AccountId string   `json:"accountId,omitempty"`
	Locations []string `json:"locations,omitempty"`
	TTLS      int64    `json:"ttl,omitempty"`
}

type presenceContext struct {
	msg    *PresenceSummary
	log    *Logger
	worker *presenceWorker
}

func (cx *presenceContext) acquireSem() error {
	if atomic.LoadInt32(&cx.worker.state) != 1 {
		return errors.New(cx.log.Notice("acquireSem: skipping, worker closed"))
	}
	exp := time.Now().Add(cx.worker.maxJobDur)
	if cx.log.isDebug { //longer debug exp
		exp = exp.Add(time.Minute * 5)
	}
	ctx, _ := context.WithDeadline(context.Background(), exp)
	if e := cx.worker.sem.Acquire(ctx, 1); e != nil {
		cx.log.IfWarnF(e, "acquireSem: failed")
		time.Sleep(time.Second)
		return e
	}
	return nil
}

func (cx *presenceContext) releaseSem() {
	cx.worker.sem.Release(1)
}

func (cx *presenceContext) cacheLocations() {
	started := time.Now()
	cx.log.PushScope("$Locs")
	defer cx.log.PopScope()

	var (
		oks     = make([]string, 0)
		skips   = make([]string, 0)
		missing = make([]string, 0)
		errs    = make([]string, 0)
	)
	for _, locId := range cx.msg.Locations {
		if len(locId) < 12 {
			cx.log.Warn("invalid locId %v", locId)
			errs = append(errs, locId)
		} else if cx.alreadyCached(locId, cx.msg.TTLS) {
			skips = append(skips, locId)
		} else if loc, e := cx.resolveLoc(locId); e != nil {
			errs = append(errs, locId)
		} else if !loc.HasShutoffDevice() || !loc.HasAddress() {
			skips = append(skips, locId)
		} else {
			ar := AddressReq{
				End:      time.Now().UTC(),
				Street:   loc.Street,
				City:     loc.City,
				Region:   loc.Region,
				PostCode: loc.PostCode,
				Country:  loc.Country,
				Cache:    "noloc",
			}
			ar.Start = ar.End.Add(-time.Duration(cx.worker.dataDays) * time.Hour * 24).Truncate(time.Hour * 24)
			ar.NormalizeAddress().NormalizeDates()
			if res, e := cx.worker.fetchAddr(&ar); e != nil {
				errs = append(errs, locId)
			} else if res.isInvalid() {
				missing = append(missing, locId)
			} else {
				oks = append(oks, locId)
			}
		}
	}
	ll := LL_DEBUG
	if len(oks) > 0 || len(missing) > 0 {
		ll = LL_INFO
	} else if len(errs) == 0 {
		ll = LL_TRACE
	}
	cx.log.Log(ll, "Completed in %vms for acc=%v | oks=%v %v | missing=%v %v | skips=%v %v | errs=%v %v",
		time.Since(started).Milliseconds(), cx.msg.AccountId, len(oks), oks, len(missing), missing, len(skips), skips, len(errs), errs)
}

func (cx *presenceContext) alreadyCached(locId string, ttls int64) bool {
	k := fmt.Sprintf("weather:presence:loc:{%v}", strings.ReplaceAll(locId, "-", ""))
	dur := time.Minute * 10 //10min back off
	if dur.Seconds() < float64(ttls) {
		dur += time.Duration(ttls) * time.Second
	}
	if ok, e := cx.worker.redis.SetNX(k, time.Now().UTC().Format(time.RFC3339), int(dur.Seconds())); e != nil {
		cx.log.IfWarnF(e, "alreadyCached: locId=%v", locId)
		return false
	} else {
		return !ok
	}
}

func (cx *presenceContext) resolveLoc(id string) (*GwLoc, error) {
	cx.log.PushScope("rLoc", id)
	defer cx.log.PopScope()

	url := fmt.Sprintf("%v/locations/%v?expand=devices", cx.worker.pubGwUri, id)
	loc := GwLoc{}
	if e := cx.worker.pubGw.Do("GET", url, nil, nil, &loc); e != nil {
		return nil, cx.log.IfErrorF(e, "fetch failed")
	} else {
		return &loc, nil
	}
}

type GwLoc struct {
	Id       string           `json:"id"`
	Street   string           `json:"address,omitempty"`
	City     string           `json:"city,omitempty"`
	Region   string           `json:"state,omitempty"`
	Country  string           `json:"country"`
	PostCode string           `json:"postalCode,omitempty"`
	TZ       string           `json:"timeZone,omitempty"`
	Devices  []*DeviceSummary `json:"devices,omitempty"`
}

func (l *GwLoc) HasShutoffDevice() bool {
	if l != nil {
		for _, d := range l.Devices {
			if d != nil && (strings.Contains(d.Model, "flo_device_") || strings.Contains(d.Type, "flo_device_")) {
				return true
			}
		}
	}
	return false
}

func (loc *GwLoc) HasAddress() bool {
	if addrStr := strJoinIfNotEmpty(loc.Street, loc.City, loc.Region, loc.PostCode, loc.Country); len(addrStr) >= 8 {
		return true
	} else {
		return false
	}
}
