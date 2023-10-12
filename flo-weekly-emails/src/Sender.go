package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/google/uuid"

	"github.com/onokonem/sillyQueueServer/timeuuid"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

type Sender struct {
	kafka     *KafkaConnection
	kTopic    string
	kGroup    string
	kSub      *KafkaSubscription
	redis     *RedisConnection
	qdb       *queuedRepo
	gw        *pubGwSvc
	validator *Validator
	localize  *Localization
	relay     *emailGwSvc
	ch        chan reqQueueOne
	state     int32 //0=not open, 1=open, 2=closed
	mux       sync.Mutex
	log       *Logger
	msgCount  int64

	lastMissingId string
	lastMissingDt time.Time
	lastGoodId    string
	lastGoodDt    time.Time

	alarmIdType map[int64]AlarmFilterType
	keyDur      KeyPerDuration
	unSubRoot   string
}

func CreateSender(
	kafka *KafkaConnection,
	kTopic, kGroup string,
	redis *RedisConnection,
	qdb *queuedRepo,
	gw *pubGwSvc,
	validator *Validator,
	log *Logger) *Sender {

	s := Sender{
		kafka:     kafka,
		kTopic:    kTopic,
		kGroup:    kGroup,
		redis:     redis,
		qdb:       qdb,
		gw:        gw,
		validator: validator,
		ch:        make(chan reqQueueOne, 2),
		log:       log.CloneAsChild("Sndr"),
		keyDur:    CreateKeyPerDuration(time.Hour * 4),
		unSubRoot: getEnvOrDefault("FLO_UNSUBSCRIBE_ROOT", "https://user.meetflo.com"),
	}
	s.relay = CreateEmailGwSvc(validator, s.log)
	if s.relay == nil {
		return nil
	}
	s.alarmIdType = map[int64]AlarmFilterType{
		51:  ALARM_SHUTOFF,
		81:  ALARM_SHUTOFF,
		101: ALARM_SHUTOFF,
		28:  ALARM_LEAK,
		29:  ALARM_LEAK,
		30:  ALARM_LEAK,
		31:  ALARM_LEAK,
	}
	if s.log.isDebug {
		DUR_SCHD_BAD_CACHE *= 2
		DUR_SCHD_GOOD_CACHE *= 2
	}
	return &s
}

type AlarmFilterType string

const (
	ALARM_SHUTOFF AlarmFilterType = "shutoff"
	ALARM_LEAK    AlarmFilterType = "leak"
)

func (s *Sender) Name() string {
	return s.log.GetName()
}

func (s *Sender) Open() {
	if s == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&s.state, 0, 1) {
		s.log.Debug("Opening...")
		go func() {
			var e error
			if s.localize, e = CreateLocalization(s.validator, s.log); e != nil {
				s.log.Fatal("Open: failed on CreateLocalization")
				signalExit()
			} else {
				go s.localize.Open()
				s.worker()
			}
		}()
		s.log.Info("Opened")
	}
}

func (s *Sender) Close() {
	if s == nil {
		return
	}
	if s != nil && atomic.CompareAndSwapInt32(&s.state, 1, 2) {
		s.log.Debug("Closing...")
		s.mux.Lock()
		defer s.mux.Unlock()

		if s.kSub != nil {
			s.kSub.Close()
			s.kSub = nil
		}
		if s.localize != nil {
			s.localize.Close()
		}
		close(s.ch)
		s.kafka = nil
		s.log.Info("Closed")
	}
}

func (s *Sender) receive(m *kafka.Message) {
	if s == nil || m == nil || len(m.Value) == 0 || atomic.LoadInt32(&s.state) != 1 {
		return
	}

	r := reqQueueOne{}
	if e := json.Unmarshal(m.Value, &r); e != nil {
		s.log.IfWarnF(e, "receive")
		return
	} else if len(r.LocId) < 16 {
		s.log.IfWarnF(e, "receive: invalid LocId | %v", r)
		return
	}
	s.mux.Lock()
	defer s.mux.Unlock()
	if s.kafka != nil {
		s.ch <- r
	}
}

func (cx *processContext) computeReportDates(timeZoneName string, reportEndsOn time.Weekday) (from, to time.Time) {
	now := cx.created.UTC()
	if now.Year() < 2000 {
		now = time.Now().UTC()
	}
	if tz, e := time.LoadLocation(timeZoneName); e != nil {
		cx.log.Notice("computeReportDates: can't resolve '%v' timezone for %v, will use rolling -24h instead | %v", timeZoneName, reportEndsOn, e)
		to = floorDay(now)
	} else { //compute range using PDT
		now = floorDay(now.In(tz))
		var durDiff time.Duration
		if today := now.Weekday(); today > reportEndsOn { //we can do current week
			durDiff = time.Duration(int(today)-int(reportEndsOn)-1) * DUR_1_DAY
		} else { //use previous week
			durDiff = time.Duration(int(today)+(int(time.Saturday)-int(reportEndsOn))) * DUR_1_DAY
		}
		to = floorDay(now.Add(-durDiff))
	}
	from = to.Add(-DUR_WEEK)
	return from, to
}

func floorDay(t time.Time) time.Time {
	tz := t.Location()
	nt, _ := time.ParseInLocation(FMT_DT_DAYTZ, t.Format(FMT_DT_DAYTZ), tz)
	return nt
}

var (
	DUR_SCHD_BAD_CACHE  = time.Minute * 1
	DUR_SCHD_GOOD_CACHE = time.Second * 5
)

func (s *Sender) hasSchedule(m *reqQueueOne) (bool, error) {
	now := time.Now()
	if goodDiff := now.Sub(s.lastGoodDt); m.ScheduleId == s.lastGoodId && goodDiff < DUR_SCHD_GOOD_CACHE {
		return true, nil //cut down on redis calls
	} else if badDiff := now.Sub(s.lastMissingDt); m.ScheduleId == s.lastMissingId && badDiff < DUR_SCHD_BAD_CACHE {
		return false, nil //cut down on redis calls
	} else if _, e := s.redis.Get(m.ScheduleId); e != nil {
		if e.Error() == "redis: nil" {
			s.lastMissingId = m.ScheduleId
			s.lastMissingDt = time.Now()
			s.log.Debug("SKIPPING locId %v | run %v terminated", m.LocId, m.ScheduleId)
			return false, nil //skip
		} else {
			s.log.IfWarnF(e, "redis problem, sleeping 2s")
			time.Sleep(time.Second * 2)
			return false, e
		}
	} else {
		s.lastGoodId = m.ScheduleId
		s.lastGoodDt = time.Now()
		return true, nil
	}
}

func (s *Sender) subscribe() error {
	if kSub, e := s.kafka.Subscribe(s.kGroup, []string{s.kTopic}, s.receive); e != nil {
		return s.log.IfWarnF(e, "subscribe")
	} else {
		if s.kSub != nil {
			s.kSub.Close()
		}
		s.kSub = kSub
		return nil
	}
}

func (s *Sender) worker() {
	s.log.PushScope("worker")
	defer s.log.PopScope()

	s.log.Info("enter")
	RetryIfError(s.subscribe, time.Second*10, s.log)
	for m := range s.ch { //loop will exit when ch is closed
		atomic.AddInt64(&s.msgCount, 1)
		if m.ScheduleId != "" {
			if ok, _ := s.hasSchedule(&m); !ok {
				continue //skip
			}
		}
		cx := processContext{
			created: time.Now().UTC(),
			req:     &m,
			log:     s.log.CloneAsChild("prCx"),
		}
		cx.from, cx.to = cx.computeReportDates("America/Los_Angeles", time.Friday)
		s.process(&cx)
	}
	s.log.Info("exit")
}

type processContext struct {
	created time.Time
	req     *reqQueueOne
	log     *Logger
	notes   []string
	from    time.Time
	to      time.Time
	queueId int64 //pg email_queued.id
}

func (p *processContext) weeklyUniqueKey() string {
	yr, wk := p.created.ISOWeek()
	k := fmt.Sprintf("email:weekly:schd:{%02d-%02d}:enqueue", yr-2000, wk)
	if p.log.isDebug { //1min key in debug mode
		k = fmt.Sprintf("%v:%v", k, p.created.Truncate(time.Minute).Unix())
	}
	return k
}
func (p *processContext) logRun() *processContext {
	ll := LL_INFO
	var note string
	if len(p.notes) == 0 {
		if p.queueId < 1 {
			note = "NOT_QUEUED!"
		} else {
			note = "OK"
		}
	} else {
		note = fmt.Sprintf("%v ERRORS", len(p.notes))
		ll = LL_NOTICE
	}
	fs, ts := p.from.Format(time.RFC3339), p.to.Format("01-02MST")
	took := time.Now().UTC().Sub(p.created).Milliseconds()
	p.log.Log(ll, "%vms Done [%v, %v] qid=%v %v - %v | %v", took, p.req.Force, p.req.Recipient, p.queueId, fs, ts, note)
	return p
}

func (cx *processContext) filterDevices(devs []*DeviceResp) []*DeviceResp {
	oks := make([]*DeviceResp, 0, len(devs))
	for _, d := range devs {
		if d == nil {
			continue
		} else if strings.Index(strings.ToLower(d.DeviceType), "flo_device_v") != 0 {
			cx.log.Debug("skip %v | unsupported %v", d.MacAddr, d.DeviceType)
		} else if !d.IsPaired {
			cx.log.Debug("skip %v | IsPaired=false", d.MacAddr)
		} else if !d.InstallStatus.IsInstalled {
			cx.log.Debug("skip %v | InstallStatus.IsInstalled=false", d.MacAddr)
		} else {
			oks = append(oks, d)
		}
	}
	return oks
}

func (s *Sender) fetchLoc(cx *processContext) *LocResp {
	if loc, e := s.gw.GetLocViaCache(cx.req.LocId); e != nil {
		cx.notes = append(cx.notes, "fetchLoc error")
	} else if loc == nil {
		cx.notes = append(cx.notes, "fetchLoc not found")
	} else if len(loc.Users) == 0 {
		cx.notes = append(cx.notes, "fetchLoc has no users")
	} else if len(loc.Devices) == 0 {
		cx.notes = append(cx.notes, "fetchLoc has no devices")
	} else if loc.Devices = cx.filterDevices(loc.Devices); len(loc.Devices) == 0 {
		cx.notes = append(cx.notes, "fetchLoc filtered devices are empty")
	} else if hasUserId := cx.req.UserId != ""; hasUserId && !loc.HasUser(cx.req.UserId) {
		cx.notes = append(cx.notes, "fetchLoc has no user: "+cx.req.UserId)
	} else if loc.Account == nil {
		cx.notes = append(cx.notes, "fetchLoc has no account info")
	} else if loc.IsMultiUnit() {
		cx.notes = append(cx.notes, "skipping, account.type is "+loc.Account.Type)
	} else {
		if hasUserId {
			for _, u := range loc.Users {
				if strings.EqualFold(u.Id, cx.req.UserId) {
					loc.Users = []*UserSummary{u}
					break
				}
			}
		}
		return loc
	}
	return nil
}

const (
	DUR_1_DAY = time.Hour * 24
)

func (s *Sender) adjustTimeZone(cx *processContext, timeZone string) {
	if tz, e := time.LoadLocation(timeZone); e != nil {
		cx.log.IfWarnF(e, "can't parse TZ %v. Will use dt %v - %v",
			timeZone, cx.from.Format(time.RFC3339+" MST"), cx.to.Format(time.RFC3339+" MST"))
	} else { //re-compute from - to using location TZ
		cx.from = floorDay(cx.from.In(tz))
		cx.to = floorDay(cx.to.In(tz))
		ll := LL_TRACE
		if cx.log.isDebug {
			ll = LL_DEBUG
		}
		cx.log.Log(ll, "dt range %v - %v", cx.from.Format(time.RFC3339+" MST"), cx.to.Format(FMT_DT_NO_TZ))
	}
}

func (s *Sender) process(cx *processContext) {
	defer panicRecover(cx.log, "process | %v", cx.req)
	cx.log.PushScope("process", cx.req.LocId, cx.req.UserId)
	defer cx.log.PopScope()
	defer cx.logRun()

	loc := s.fetchLoc(cx)
	if loc == nil {
		return
	} else if loc.TimeZone != "" {
		s.adjustTimeZone(cx, loc.TimeZone)
	}
	if cx.req.Force {
		if locked, e := s.processTempLock(cx, loc.Users); e != nil {
			return
		} else {
			loc.Users = locked //these are the users that we can email
			for _, u := range loc.Users {
				if cx.req.Locale != "" { //overriding everyone's locale
					u.Locale = cx.req.Locale
				}
				if cx.req.UnitSystem != "" { //override unit systems
					u.UnitSystem = cx.req.UnitSystem
				}
			}
		}
	} else {
		if canSend, e := s.ensureNotSent(cx, loc); e != nil || len(canSend) == 0 {
			return
		} else if locked, e := s.processLock(cx, canSend); e != nil {
			return
		} else if subscribers, e := s.ensureSubscribed(cx, locked); e != nil {
			return
		} else {
			loc.Users = subscribers //exclusive lock + not opted out
		}
	}
	if len(loc.Users) == 0 { //double check
		cx.notes = append(cx.notes, "can't send email to any user")
	} else if rc := s.buildReport(cx, loc); rc != nil {
		s.queueReport(rc)
	}
}

func (s *Sender) ensureSubscribed(cx *processContext, users []*UserSummary) (subscribers []*UserSummary, e error) {
	cx.log.PushScope("unSub?", cx.req.LocId)
	defer cx.log.PopScope()

	uc := len(users)
	emails := make([]string, uc)
	for i, u := range users {
		emails[i] = u.Email
	}
	if unSubs, e := s.relay.IsUnsubscribed(emails); e != nil {
		cx.notes = append(cx.notes, "UnSubscribe check failed")
		return nil, cx.log.IfErrorF(e, "%v", emails)
	} else {
		subscribers := make([]*UserSummary, 0, uc)
		for _, u := range users {
			if unSub, ok := unSubs[strings.ToLower(u.Email)]; ok {
				if !unSub {
					subscribers = append(subscribers, u)
				}
			} else {
				subscribers = append(subscribers, u)
			}
		}
		if len(subscribers) == 0 {
			cx.notes = append(cx.notes, "all emails unSubscribed")
			return nil, errors.New(cx.log.Info("all emails unSubscribed: %v", emails))
		}
		return subscribers, nil
	}
}

func (s *Sender) processTempLock(cx *processContext, canSend []*UserSummary) ([]*UserSummary, error) {
	cx.log.PushScope("prTmpLock")
	defer s.log.PopScope()

	oks := make([]*UserSummary, 0)
	failed := make([]string, 0)
	for _, u := range canSend {
		k := fmt.Sprintf("email:wktmp:{%v}:%v",
			strings.ReplaceAll(cx.req.LocId, "-", ""),
			strings.ReplaceAll(u.Id, "-", ""))
		if ok, e := s.redis.SetNX(k, time.Now().UTC().Format(time.RFC3339), 15); e != nil {
			s.log.IfErrorF(e, "redis setNX %v", k)
			failed = append(failed, u.Id)
		} else if ok {
			oks = append(oks, u)
		} else {
			failed = append(failed, u.Id)
		}
	}
	if ol := len(oks); ol == 0 {
		n := fmt.Sprintf("failed for all: %v", failed)
		cx.notes = append(cx.notes, n)
		return nil, errors.New(cx.log.Notice(n))
	} else {
		if len(failed) != 0 {
			cx.log.Info("%v oks, skipping %v", ol, failed)
		}
		return oks, nil
	}
}

func (s *Sender) processLock(cx *processContext, canSend []*UserSummary) ([]*UserSummary, error) {
	cx.log.PushScope("prLock")
	defer s.log.PopScope()

	uniques := make([]*UserSummary, 0)
	failed := make([]string, 0)
	for _, u := range canSend {
		if s.ensureUnique(cx, u) {
			uniques = append(uniques, u)
		} else {
			failed = append(failed, u.Id)
		}
	}
	if uc := len(uniques); uc == 0 {
		n := fmt.Sprintf("failed for all: %v", failed)
		cx.notes = append(cx.notes, n)
		return nil, cx.log.Warn(n)
	} else { //set ttl on at least 1 write
		if len(failed) != 0 {
			cx.log.Info("%v oks, skipping %v", uc, failed)
		}
		if wkk := cx.weeklyUniqueKey(); s.keyDur.Check(wkk, time.Hour) { //reduce redis load
			dur := DUR_1_DAY * 4
			if cmd := s.redis._client.Expire(wkk, dur); !cmd.Val() {
				cx.log.IfWarnF(cmd.Err(), "ttl set")
			}
		}
		return uniques, nil
	}
}

func (s *Sender) ensureUnique(cx *processContext, user *UserSummary) bool {
	email := user.Email
	if cx.req.Recipient != "" {
		email = cx.req.Recipient
	}
	mh, _ := mh3(email)
	v := strings.ToLower(fmt.Sprintf("{%v}|%v|%v",
		strings.ReplaceAll(cx.req.LocId, "-", ""),
		strings.ReplaceAll(user.Id, "-", ""),
		mh))
	k := cx.weeklyUniqueKey()
	if n, e := s.redis.SAdd(k, v); e != nil {
		cx.log.IfWarnF(e, "SAdd('%v','%v')", k, v)
		return false
	} else if n == 0 {
		cx.log.Notice("'%v' has already been added to set '%v'", v, k)
		return false
	}
	return true
}

var DUR_WEEK = time.Duration(7*24) * time.Hour

func (s *Sender) ensureNotSent(cx *processContext, loc *LocResp) ([]*UserSummary, error) {
	if sentUserIds, e := s.qdb.FetchAfter(cx.to.UTC(), 1, loc.Id); e != nil {
		cx.notes = append(cx.notes, "QueuedAfter fetch error")
		return nil, e
	} else if ul := len(sentUserIds); ul > 0 {
		notSent := make([]*UserSummary, 0, ul)
		for _, u := range loc.Users {
			if found, ok := sentUserIds[strings.ToLower(u.Id)]; !ok || !found {
				notSent = append(notSent, u) //these people did not receive an email for the week yet
			} else {
				cx.log.Debug("ensureNotSent: already sent to uid=%v %v @ loc=%v", u.Id, u.Email, loc.Id)
			}
		}
		if len(notSent) == 0 {
			cx.notes = append(cx.notes, "QueuedAfter check already sent all")
		}
		return notSent, nil
	} else {
		return loc.Users, nil //no one in the loc receive any email this week
	}
}

const FMT_DT_NO_TZ = "2006-01-02T15:04:05"

func (s *Sender) fetchWaterUsage(cx *processContext, loc *LocResp) []*WaterUsage {
	rq := WaterUseReq{
		LocId:     loc.Id,
		StartDate: cx.from.Add(-DUR_WEEK).Format(FMT_DT_NO_TZ),  //take an extra week of data to compare,
		EndDate:   cx.to.Add(-time.Second).Format(FMT_DT_NO_TZ), //date str is tz local rendered w/o tz info
		TimeZone:  loc.TimeZone,
		Interval:  "1d",
	}
	if res, e := s.gw.GetWaterUsage(&rq); e != nil || res == nil || len(res.Items) == 0 {
		cx.log.Warn("missing water usage")
		return nil
	} else {
		for _, w := range res.Items { //round gallons to whole numbers so roundings are not off
			if w.Gallons != 0 {
				w.Gallons = float32(math.Round(float64(w.Gallons)))
			}
		}
		return res.Items
	}
}

func (s *Sender) fetchWaterStats(cx *processContext, loc *LocResp) map[string]*WaterStatsResp {
	macWater := make(map[string]*WaterStatsResp)
	for _, d := range loc.Devices {
		if _, ok := macWater[d.MacAddr]; ok { //skip duplicate
			continue
		}
		wr := WaterStatsReq{
			MacAddr:   d.MacAddr,
			StartDate: cx.from.Add(-DUR_WEEK).Format(FMT_DT_NO_TZ), //take an extra week of data to compare
			EndDate:   cx.to.Format(FMT_DT_NO_TZ),                  //date str is tz local rendered w/o tz info
			TimeZone:  loc.TimeZone,
			Interval:  "1d",
		}
		if water, e := s.gw.GetWaterStats(&wr); e != nil || water == nil {
			continue
		} else {
			macWater[d.MacAddr] = water
		}
	}
	if len(macWater) == 0 {
		cx.log.Warn("missing water stats")
	}
	return macWater
}

type reportContext struct {
	log         *Logger
	job         *processContext
	location    *LocResp
	alertStats  *AlertStatsResp
	leaks       []*AlertEvent
	shutOffs    []*AlertEvent
	locWater    []*WaterUsage
	macWater    map[string]*WaterStatsResp
	usrUnSubUrl map[string]string
	defaultUnit UnitSystem
}

func (cx *reportContext) unSubscribeUrl(userId string) (url string) {
	url, _ = cx.usrUnSubUrl[userId]
	return url
}

func (s *Sender) genUnsubLinks(loc *LocResp) map[string]string {
	m := make(map[string]string)
	for _, u := range loc.Users {
		var (
			tu  = timeuuid.TimeUUID().String()
			tk  = uuid.New().String()
			url = fmt.Sprintf("%s/unsubscribe?u=%s&l=%s&n=%s&t=%s", s.unSubRoot, u.Id, loc.Id, tu, tk)
		)
		m[u.Id] = url
	}
	return m
}

func (ac *AlertsCount) IdMap(severity string) map[int64]string {
	m := make(map[int64]string)
	for _, a := range ac.Alarms {
		if severity == "" || strings.EqualFold(severity, a.Severity) {
			m[a.Id] = a.Severity
		}
	}
	return m
}

func (s *Sender) buildReport(cx *processContext, loc *LocResp) *reportContext {
	started := time.Now()
	cx.log.PushScope("mkRp")
	defer cx.log.PopScope()

	var (
		e          error
		rc         = reportContext{log: cx.log, job: cx, location: loc, defaultUnit: s.localize.DefaultUnitSystem()}
		shutOffArg = AlertReq{LocId: loc.Id, Severity: []string{"critical"}, Size: 200}
		leaksArg   = AlertReq{LocId: loc.Id, Severity: []string{"warning"}, Size: 250}
	)
	rc.usrUnSubUrl = s.genUnsubLinks(loc)
	if rc.locWater = s.fetchWaterUsage(cx, loc); len(rc.locWater) == 0 {
		return nil
	} else if rc.macWater = s.fetchWaterStats(cx, loc); len(rc.macWater) == 0 {
		return nil
	} else if rc.alertStats, e = s.gw.GetAlertStats(loc.Id); e != nil {
		return nil
	} else if rc.shutOffs, e = s.fetchAlerts(cx, &shutOffArg, func(a *AlertEvent) bool {
		if at, ok := s.alarmIdType[a.Alarm.Id]; ok && at == ALARM_SHUTOFF {
			return true
		}
		return false
	}); e != nil {
		return nil
	} else if rc.leaks, e = s.fetchAlerts(cx, &leaksArg, func(a *AlertEvent) bool {
		if at, ok := s.alarmIdType[a.Alarm.Id]; ok && at == ALARM_LEAK {
			return true
		}
		return false
	}); e != nil {
		return nil
	}
	cx.log.Info("%vms DONE %v devices, %v users, %v shuts, %v leaks, %v unSubUrls, %v pending",
		time.Since(started).Milliseconds(), len(rc.macWater), len(rc.location.Users), len(rc.shutOffs), len(rc.leaks), len(rc.usrUnSubUrl), rc.alertStats.PendingTotal())
	return &rc
}

func (s *Sender) fetchAlerts(cx *processContext, arg *AlertReq, filter func(*AlertEvent) bool) ([]*AlertEvent, error) {
	from, to := cx.from.UTC(), cx.to.UTC()
	res := make([]*AlertEvent, 0)
	arg.Normalize()
	fromUx, toUx := from.Unix(), to.Unix()
	for next := true; next; {
		if alerts, e := s.gw.GetAlerts(arg); e != nil {
			return nil, e
		} else {
			if al := len(alerts.Items); alerts.Total == 0 && al != 0 {
				alerts.Total = int32(al)
			}
			if alerts.Total < arg.Size {
				next = false
			}
			for _, a := range alerts.Items {
				if cdt := a.CreatedDt.Unix(); cdt >= fromUx && cdt <= toUx && filter(a) {
					res = append(res, a)
				} else if cdt < from.Unix() {
					next = false
				}
			}
			arg.Page++
		}
	}
	return res, nil
}

func (em *EmailMessage) ToEmailQueued(cx *reportContext, u *UserSummary, e error) *emailQueued {
	q := emailQueued{
		ScheduleId: cx.job.req.ScheduleId,
		LocId:      cx.location.Id,
		UserId:     u.Id,
		Email:      u.Email,
		EmailType:  1,
		Request:    make(map[string]interface{}),
	}
	if em != nil {
		q.Created = em.TimeStamp
		if len(em.Recipients) > 0 && em.Recipients[0] != nil {
			if d := em.Recipients[0].Data; d != nil {
				q.TemplateId = d.TemplateId
				q.TemplateData = d.EmailTemplateData.Data
			}
		}
	} else {
		q.Created = time.Now().UTC()
	}
	if js, _ := json.Marshal(cx.job.req); len(js) != 0 {
		json.Unmarshal(js, &q.Request)
	}
	if e != nil {
		q.Error = e.Error() //TODO: decode full stack if possible
	}
	return &q
}

func (s *Sender) resolveTemplate(cx *reportContext, locale string) (template string, e error) {
	if r := cx.job.req; r.Force && r.Template != "" {
		return cx.job.req.Template, nil //use template override on request if available
	} else if template, e = s.localize.EmailTemplate(locale); e != nil {
		return "", e
	} else {
		return template, nil
	}
}

func (s *Sender) queueReport(cx *reportContext) {
	cx.log.PushScope("qRprt")
	defer cx.log.PopScope()

	users, qOK, qErr := 0, 0, 0
	es := make([]error, 0)
	for _, u := range cx.location.Users {
		users++
		var (
			template string
			e        error
			email    *EmailMessage
		)
		if template, e = s.resolveTemplate(cx, u.Locale); e != nil {
			es = append(es, e)
		} else if unSubLink := cx.unSubscribeUrl(u.Id); unSubLink == "" {
			es = append(es, s.log.Error("unSubscribeUrl for usr %v not found", u.Id))
		} else if email, e = CreatePacker(cx, s.localize, s.alarmIdType).Box(u, template, unSubLink); e != nil {
			es = append(es, e)
		} else if cx.job.req.DryRun { //fake queue
			cx.log.Debug("DRYRUN: FakeQueue for qid=%v uid=%v %v %v", email.Id, u.Id, u.Email, u.Name())
		} else if _, e := s.relay.Queue(email); e != nil { //real queue
			es = append(es, e)
		}

		if e != nil || email == nil {
			qErr++
		} else {
			qOK++
		}
		if cx.job.queueId, e = s.qdb.Store(email.ToEmailQueued(cx, u, e)); e != nil {
			es = append(es, e)
		}
	}
	dry := "QUEUE"
	if cx.job.req.DryRun {
		dry = "DRYRUN"
	}
	if e := wrapErrors(es); e != nil {
		n := fmt.Sprintf("%v users=%v ok=%v err=%v", dry, users, qOK, qErr)
		cx.job.notes = append(cx.job.notes, n)
		cx.log.Notice(n)
	} else {
		cx.log.Debug("%v users=%v ok=%v err=%v", dry, users, qOK, qErr)
	}
}

// relay adaptors

func (s *Sender) IsUnsubscribed(emails []string) (map[string]bool, error) {
	return s.relay.IsUnsubscribed(emails)
}

// queueRepo adaptors

func (s *Sender) Ping() error {
	return s.qdb.Ping()
}

func (s *Sender) FetchQueued(rq *reqQueueHst) ([]*emailQueued, error) {
	return s.qdb.Fetch(rq)
}

func (s *Sender) StoreQueued(v *emailQueued) (id int64, e error) {
	return s.qdb.Store(v)
}
