package main

import (
	"fmt"
	"hash/crc32"
	"strings"
	"sync/atomic"
	"time"

	"github.com/robfig/cron/v3"
)

const ENVVAR_EMAIL_CRON_SCHEDULE = "FLO_EMAIL_CRON_SCHEDULE"
const ENVVAR_EMAIL_CRON_ASAP = "FLO_EMAIL_CRON_ASAP"

type Scheduler struct {
	dev       *deviceSvc
	gw        *pubGwSvc
	rdb       *runRepo
	redis     *RedisConnection
	kafka     *KafkaConnection //used as producer
	kTopic    string
	log       *Logger
	pingFirst bool
	cronJob   *cron.Cron
	state     int32 //0=closed, 1=open
	crc32q    *crc32.Table
}

func CreateScheduler(
	dev *deviceSvc,
	gw *pubGwSvc,
	rdb *runRepo,
	redis *RedisConnection,
	kafka *KafkaConnection,
	kTopic string,
	log *Logger) *Scheduler {

	s := Scheduler{
		dev:       dev,
		gw:        gw,
		rdb:       rdb,
		redis:     redis,
		kafka:     kafka,
		kTopic:    kTopic,
		log:       log.CloneAsChild("Schlr"),
		pingFirst: strings.EqualFold(getEnvOrDefault("FLO_PING_B4_QUEUE", ""), "true"),
		crc32q:    crc32.MakeTable(0xD5828281),
	}
	return &s
}

func (s *Scheduler) Name() string {
	return s.log.GetName()
}

func (q *Scheduler) canCronASAP() bool {
	return q.log.isDebug && strings.EqualFold(getEnvOrDefault(ENVVAR_EMAIL_CRON_ASAP, ""), "true")
}

func (q *Scheduler) Open() {
	if q == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&q.state, 0, 1) {
		if cronExp := getEnvOrDefault(ENVVAR_EMAIL_CRON_SCHEDULE, ""); cronExp == "" {
			if q.canCronASAP() {
				go func() {
					time.Sleep(time.Second * 5) //fake trigger now
					q.cronRun()
				}()
			} else {
				q.log.Notice("Open: %v is BLANK, will not schedule weekly email runs", ENVVAR_EMAIL_CRON_SCHEDULE)
			}
		} else {
			c := cron.New()
			if cid, e := c.AddFunc(cronExp, q.cronRun); e != nil {
				q.log.IfFatalF(e, "Open: bad cronExp %v=%v", ENVVAR_EMAIL_CRON_SCHEDULE, cronExp)
				defer signalExit()
			} else {
				q.cronJob = c
				q.log.Notice("Open: cronJob #%v | %v=%v", cid, ENVVAR_EMAIL_CRON_SCHEDULE, cronExp)
				q.cronJob.Start()
				if q.canCronASAP() {
					go func() {
						time.Sleep(time.Second * 5) //fake trigger now
						q.cronRun()
					}()
				}
			}
		}
	}
}

func (q *Scheduler) Close() {
	if q == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&q.state, 1, 0) {
		if q.cronJob != nil {
			q.log.Notice("Stop: terminating cronJob")
			q.cronJob.Stop()
		} else {
			q.log.Notice("Stop: no cronJob scheduled")
		}
	}
}

func (q *Scheduler) cronRun() {
	q.log.Notice("cronRun: ATTEMPT")
	rq := reqQueueAll{}
	if q.log.isDebug { //test safety
		rq.Recipient = getEnvOrDefault("FLO_DEFAULT_TEST_EMAIL", "huy+testing@flotechnologies.com")
		rq.DryRun = true
		//rq.Force = true
	}
	if res, e := q.Run(&rq); e != nil {
		q.log.Notice("cronRun: REJECTED, already ran or another machine picked up the queuing task")
	} else {
		q.log.Notice("cronRUN: ACCEPTED, run id=%v | %v", res.Id, res)
	}
}

func (q *Scheduler) Ping() error {
	if e := q.kafka.Producer.GetFatalError(); e != nil {
		return e
	}
	for _, csm := range q.kafka.Consumers {
		if _, e := csm.Consumer.Subscription(); e != nil {
			return e
		}
	}
	if q.log.isDebug { //no need to continue if debugging locally
		return nil
	}
	_, e := q.kafka.Producer.GetMetadata(&q.kTopic, false, 3000)
	return q.log.IfErrorF(e, "Ping")
}

func (h *Scheduler) QueueWork(q *reqQueueOne) error {
	if q == nil {
		return h.log.Warn("QueueWork: nil input")
	}
	if e := h.kafka.Publish(h.kTopic, q, []byte(q.LocId)); e == nil {
		h.log.Debug("QueueWork: %v", q)
		return nil
	} else {
		return e
	}
}

func (h *Scheduler) preRunPing(id string) *HttpErr {
	if e := h.dev.Ping(); e != nil {
		return &HttpErr{502, "can't ping device service", id}
	} else if e = h.rdb.Ping(); e != nil {
		return &HttpErr{502, "can't ping pg", id}
	} else {
		return nil
	}
}

func (h *Scheduler) canRun(rq *reqQueueAll) (id string, he *HttpErr) {
	h.log.PushScope("canRun")
	defer h.log.PopScope()

	if st := atomic.LoadInt32(&h.state); st == 0 {
		return "", &HttpErr{502, "service is not in Open state", fmt.Sprintf("state=%v", st)}
	}
	n := time.Now().UTC()
	yr, wk := n.ISOWeek()
	id = fmt.Sprintf("email:1:{%02d:%02d}", yr-2000, wk)
	if h.log.isDebug {
		id += ":!"
	}
	if h.pingFirst {
		if he = h.preRunPing(id); he != nil {
			h.log.IfErrorF(he, he.Trace)
			return id, he
		} else {
			h.log.Info("ping OK")
		}
	}
	ttl := DUR_WEEK - DUR_1_DAY
	if rq.Force {
		if rq.TTLS > 0 {
			ttl = time.Duration(rq.TTLS) * time.Second
		} else if h.log.isDebug {
			ttl = time.Minute * 5
		} else if rq.DryRun {
			ttl = time.Minute * 60 //1hr test
		}
		id += fmt.Sprintf(":t:%v", n.Truncate(ttl).Unix())
		if rq.Limit > 0 {
			id += fmt.Sprintf(":l:%v", rq.Limit)
		}
	}
	if rq.MacAddr != "" {
		id += fmt.Sprintf(":d:%v", rq.MacAddr)
	}
	if rq.DryRun {
		id += "_"
	}
	if rq.Recipient != "" {
		id += fmt.Sprintf(":re:%08x", crc32.Checksum([]byte("Hello world"), h.crc32q))
	}
	if ok, e := h.redis.SetNX(id, tryToJson(rq), int(ttl.Seconds())); e != nil {
		he = &HttpErr{500, "mutex check failed", id}
		h.log.IfErrorF(he, he.Trace)
	} else if !ok {
		he = &HttpErr{409, "already ran", id}
		h.log.IfWarnF(he, he.Trace)
	}
	return id, he
}

func (h *Scheduler) Run(rq *reqQueueAll) (*respQueueAll, *HttpErr) {
	started := time.Now()
	id, he := h.canRun(rq)
	if he != nil {
		return nil, he
	}
	h.log.PushScope("Run", id)
	defer h.log.PopScope()

	rh := respQaHistRun{Id: id, EmailType: 1, Params: rq, Created: started.UTC()}
	if _, e := h.rdb.Store(&rh); e != nil {
		return nil, &HttpErr{500, e.Error(), id}
	}
	h.newSchRunContext(&rh).background() //none blocking
	res := respQueueAll{
		Id:      id,
		Message: "queue all accepted",
		Params:  rq,
	}
	return &res, nil
}

func (h *Scheduler) newSchRunContext(rh *respQaHistRun) *schRunContext {
	cx := schRunContext{
		sch: h,
		job: rh,
		log: h.log.CloneAsChild("bg"),
		es:  make([]error, 0),
	}
	return &cx
}

type schRunContext struct {
	sch *Scheduler
	job *respQaHistRun
	log *Logger
	es  []error
}

func (cx *schRunContext) background() {
	go cx.process()
}

func (cx *schRunContext) pushErr(e error) error {
	if e != nil {
		cx.es = append(cx.es, e)
		cx.job.Errors++
	}
	return e
}

func (h *Scheduler) Kill(id string) *HttpErr {
	if strings.Index(id, "email:weekly:") != 0 {
		return &HttpErr{400, "bad run id", id}
	}
	rq := reqQaHistory{
		Date:      time.Now().UTC(),
		Direction: "desc",
		Limit:     100,
		EmailType: 1,
	}
	if runs, e := h.rdb.Fetch(&rq); e != nil {
		return &HttpErr{500, "can't fetch run", e.Error()}
	} else {
		for _, r := range runs {
			if strings.EqualFold(r.Id, id) {
				if n, e := h.redis.Delete(r.Id); e != nil {
					if e.Error() == "redis: nil" {
						return &HttpErr{409, "can't find run: " + r.Id, e.Error()}
					} else {
						return &HttpErr{500, "can't kill run, error: " + r.Id, e.Error()}
					}
				} else if n < 1 {
					return &HttpErr{409, "can't kill run, already dead or missing: " + r.Id, ""}
				} else {
					h.log.Notice("KILL_RUN %v OK!", r.Id)
					return nil
				}
			}
		}
		return &HttpErr{404, "can't find run: " + id, ""}
	}
}

func (x *schRunContext) logRun() {
	diff := time.Now().UTC().Sub(x.job.Created)
	ll := LL_NOTICE
	if len(x.es) != 0 {
		ll = LL_WARN
	}
	x.log.Log(ll, "DONE: %v | Took %v, count=%v", x.job.Id, fmtDuration(diff), x.job.Counter)
}

func (cx *schRunContext) updateCounters(done bool) error {
	if cx.job.Completed.Year() > 2000 {
		return nil
	}
	e := cx.sch.rdb.UpdateCounter(cx.job.Id, cx.job.Counter, cx.job.Errors, done)
	if done && e != nil {
		cx.job.Completed = time.Now().UTC()
	}
	return e
}

func (cx *schRunContext) totalCounter() int32 {
	return cx.job.Counter + cx.job.Errors
}

const DB_FLUSH_COUNTER = 10

func (cx *schRunContext) aliveCheck(lastMacId string, fastCheck bool) bool {
	if st := atomic.LoadInt32(&cx.sch.state); st == 0 {
		cx.log.Warn("RUN_KILL [shutdown] run id=%v Last macAddr=%v", cx.job.Id, lastMacId)
		return false
	} else if fastCheck {
		return true
	} else if _, e := cx.sch.redis.Get(cx.job.Id); e != nil {
		cx.log.IfWarnF(e, "RUN_KILL [triggered] redis key %v missing or connection issue.  Last macAddr=%v", cx.job.Id, lastMacId)
		return false
	}
	return true
}

func (cx *schRunContext) process() {
	defer cx.logRun()

	lastMacId := cx.job.Params.MacAddr
	cx.log.Info("process: Started")
	for batch, er := cx.sch.dev.NextFlowDeviceIds(lastMacId); cx.log.IfFatal(er) == nil && batch.HasMore; {
		if !cx.aliveCheck(lastMacId, false) {
			break
		}
		lastMacId = batch.LastId
		cx.processBatch(batch, lastMacId)
		if batch.HasMore {
			batch, er = cx.sch.dev.NextFlowDeviceIds(lastMacId)
		}
	}
	cx.log.Notice("process: Completed")

	if e := cx.updateCounters(true); e != nil {
		cx.log.IfWarnF(e, "Store results failed, retrying in 3s")
		time.Sleep(time.Second * 3)
		if e = cx.updateCounters(true); e != nil {
			cx.pushErr(cx.log.IfErrorF(e, "Unable to store run result"))
			return
		}
	}
}

func (cx *schRunContext) processBatch(batch *DeviceMacAddrBatch, lastMacId string) {
	defer panicRecover(cx.log, "processBatch: lastMacId=%v", lastMacId)
	for i, macAddr := range batch.Ids {
		if !cx.aliveCheck(macAddr, i == 0 || i%5 != 0) {
			cx.log.Notice("breaking_loop")
			break
		}
		if q, e := cx.resolveLoc(macAddr); e != nil {
			cx.pushErr(e)
		} else if e = cx.sch.QueueWork(q); e != nil {
			cx.pushErr(e)
		} else if cx.job.Counter++; cx.totalCounter()%DB_FLUSH_COUNTER == 0 {
			cx.updateCounters(false)
		}
		if cx.job.Params.Force && cx.job.Params.Limit > 0 && cx.totalCounter() >= cx.job.Params.Limit {
			batch.HasMore = false //will break the outer loop too
			break
		}
	}
	if len(batch.Ids) != 0 {
		cx.updateCounters(false)
	}
}

func (cx *schRunContext) resolveLoc(macAddr string) (*reqQueueOne, error) {
	if d, e := cx.sch.gw.GetDeviceInfo(macAddr); e != nil {
		ll := LL_WARN
		if strings.Contains(strings.ToLower(e.Error()), "not found") {
			ll = LL_INFO
		}
		cx.log.Log(ll, "resolveLoc: mac=%v -> ERROR %v", macAddr, e.Error())
		return nil, e
	} else {
		rq := cx.job.Params
		q := reqQueueOne{
			ScheduleId: cx.job.Id,
			LocId:      d.LocSummary.Id,
			Recipient:  rq.Recipient,
			Force:      rq.Force,
			DryRun:     rq.DryRun,
		}
		cx.log.Debug("resolveLoc: mac=%v -> job=%v loc=%v for %v", macAddr, q.ScheduleId, q.LocId, q.Recipient)
		return &q, nil
	}
}

// runRepo adaptors++

func (rq *reqQaHistory) buildCountRequest(res []*respQaHistRun) *QueueCountReq {
	countReq := QueueCountReq{ScheduleIds: make([]string, len(res))}
	for i, r := range res {
		countReq.ScheduleIds[i] = r.Id
		if countReq.CreatedAfter.Year() < 2000 || (r.Created.Year() > 2000 && r.Created.Before(countReq.CreatedAfter)) {
			countReq.CreatedAfter = r.Created //valid min year == smaller scan
		}
	}
	if countReq.CreatedAfter.Year() < 2000 {
		countReq.CreatedAfter = rq.Date //fall back to request date
	}
	return &countReq
}

func (q *Scheduler) FetchRuns(rq *reqQaHistory) ([]*respQaHistRun, error) {
	if res, e := q.rdb.Fetch(rq); e != nil {
		return nil, e
	} else if len(res) != 0 && rq.HandOffs { //query count enrichment
		countReq := rq.buildCountRequest(res)
		if countRes, e := q.rdb.Count(countReq); e != nil {
			q.log.IfErrorF(e, "Queue HandOffs count failed")
		} else if len(countRes.Counts) != 0 {
			rMap := make(map[string]*respQaHistRun)
			for _, r := range res {
				rMap[r.Id] = r
			}
			for id, count := range countRes.Counts {
				if r, ok := rMap[id]; ok {
					r.HandOffs = count
				}
			}
		}
		return res, nil
	} else {
		return res, nil
	}
}
