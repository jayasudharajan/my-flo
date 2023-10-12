package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	//_ "gitlab.com/flotechnologies/flo-weekly-emails/docs"
)

type Handler struct {
	ws        *WebServer
	pubGw     *pubGwSvc
	schedule  *Scheduler
	send      *Sender
	pings     []func() (string, error)
	log       *Logger
	testEmail string
}

func CreateHandler(
	ws *WebServer,
	pubGw *pubGwSvc,
	send *Sender,
	schedule *Scheduler,
	pings []func() (string, error)) *Handler {

	h := Handler{
		ws:        ws,
		pubGw:     pubGw,
		send:      send,
		schedule:  schedule,
		pings:     pings,
		log:       ws.Logger().CloneAsChild("Handler"),
		testEmail: getEnvOrDefault("FLO_DEFAULT_TEST_EMAIL", "huy+test@flotechnologies.com"),
	}
	return &h
}

// Ping godoc
// @Summary check the health status of the service and list its config data
// @Description returns status of the service
// @Tags system
// @Accept  json
// @Produce  json
// @Success 200
// @Router /ping [get]
// Health is the handler for ping
func (h *Handler) Ping(c *gin.Context) {
	started := time.Now()
	h.log.PushScope("Ping")
	defer h.log.PopScope()

	status := "ok"
	var oks map[string]int64
	if c.Request.Method == "POST" { //only health check on POST
		status, oks = h.health()
	}
	code := 200
	if status != "ok" {
		code = 503
	}

	rv := map[string]interface{}{
		"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		"app":        APP_NAME,
		"status":     status,
		"commit":     _commitSha,
		"commitTime": _commitTime,
		"host":       _hostName,
		"env":        getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
		"debug":      _log.isDebug,
		"uptime":     fmtDuration(time.Since(_start)),
	}
	if len(oks) != 0 {
		rv["ok"] = oks
	}
	rv["tookMs"] = time.Since(started).Milliseconds()
	c.JSON(code, rv)
}

func (h *Handler) health() (string, map[string]int64) {
	h.log.PushScope("health")
	defer h.log.PopScope()

	status := ""
	oks := make(map[string]int64)
	for i := 0; i < len(h.pings); i++ {
		pinger := h.pings[i]
		if pinger == nil {
			continue
		}
		pstart := time.Now()
		if n, e := pinger(); e != nil {
			status += fmt.Sprintf("can't ping: %v; ", n)
		} else {
			oks[n] = time.Since(pstart).Milliseconds()
		}
	}
	if status == "" {
		status = "ok"
	}
	return status, oks
}

func (h *Handler) Die(c *gin.Context) {
	defer signalExit()
	m := respMsg{"Good bye cruel world 💔"}
	h.log.Notice(m.Message)
	c.JSON(202, m)
}

type reqQueueHst struct {
	Date       time.Time `json:"date,omitempty" validate:"omitempty,datetime=2006-01-02T15:04:05Z07:00"`
	Direction  string    `json:"direction,omitempty" validate:"omitempty,oneof=asc desc Asc Desc ASC DESC"`
	Limit      int32     `json:"limit,omitempty" validate:"omitempty,max=500,min=1"`
	LocId      string    `json:"locId,omitempty" validate:"omitempty,min=32,max=36,uuid_rfc4122|hexadecimal"`
	UserId     string    `json:"userId,omitempty" validate:"omitempty,min=32,max=36,uuid_rfc4122|hexadecimal"`
	EmailType  int32     `json:"emailType,omitempty" validate:"omitempty,min=0,max=3200"`
	Email      string    `json:"email,omitempty" validate:"omitempty,max=128,email"`
	ScheduleId string    `json:"scheduleId,omitempty" validate:"omitempty,min=1,max=64"`
}

func (q *reqQueueHst) GetKeys() (string, string, string) {
	return q.LocId, q.UserId, q.Email
}
func (q *reqQueueHst) SetUser(userId string) {
	q.UserId = userId
}
func (r *reqQueueHst) Normalize() {
	if r.Date.Year() < 2000 {
		r.Date = time.Now().UTC()
	} else {
		r.Date = r.Date.UTC()
	}
	if r.Direction == "" {
		r.Direction = "desc"
	} else {
		r.Direction = strings.ToLower(r.Direction)
	}
	if r.Limit < 1 {
		r.Limit = 100
	}
}

type respQueue struct {
	Params       reqQueueHst    `json:"params,omitempty"`
	ResultsCount int            `json:"resultsCount,omitempty"` //how many items being returned
	Results      []*emailQueued `json:"results,omitempty"`
}
type emailQueued struct {
	Id           int64                  `json:"id,omitempty" validate:"omitempty,min=0"`
	ScheduleId   string                 `json:"schedule_id,omitempty" validate:"omitempty,min=1,max=64"`
	LocId        string                 `json:"locId,omitempty" validate:"required,uuid_rfc4122"`
	UserId       string                 `json:"userId,omitempty" validate:"required,uuid_rfc4122"`
	Email        string                 `json:"email,omitempty" validate:"required,email,max=128"`
	EmailType    int32                  `json:"emailType,omitempty" validate:"required,min=1,max=3200"`
	TemplateId   string                 `json:"templateId,omitempty" validate:"required,min=1,max=128"`
	TemplateData map[string]interface{} `json:"templateData,omitempty" validate:"-"`
	Created      time.Time              `json:"created,omitempty" validate:"omitempty,datetime"`
	Request      map[string]interface{} `json:"req,omitempty" validate:"-"`
	Error        string                 `json:"err,omitempty" validate:"omitempty,max=5120"`
}

type ILocUser interface {
	GetKeys() (locId, userId, email string)
	SetUser(userId string)
	Normalize()
}

func (h *Handler) validateLocUser(req ILocUser, defaultKeysOK bool, c *gin.Context) bool {
	req.Normalize()
	locId, userId, email := req.GetKeys()
	if !defaultKeysOK && email == "" && userId == "" && locId == "" {
		h.ws.HttpError(c, 400, "email, userId or locId is required", nil)
		return false
	} else if userId != "" && email != "" {
		h.ws.HttpError(c, 400, "only userId or email can be used, not both", nil)
		return false
	} else if !defaultKeysOK && locId == "" && email != "" { //TODO: remove this clause once we have email search implemented
		h.ws.HttpError(c, 501, "email only input is not implemented", nil)
		return false
	} else {
		if userId == "" && email != "" {
			if emailInfos, e := h.pubGw.SearchUser(email); e == nil {
				if el := len(emailInfos); el == 1 {
					userId = emailInfos[0].UserId
					req.SetUser(userId)
				} else if el > 1 { //ambiguous request
					a := ambiguousResp{
						Params: map[string]interface{}{
							"email": email,
						},
						Choices: make([]interface{}, el),
					}
					for i, n := range emailInfos {
						a.Choices[i] = n
					}
					h.log.Info("ambiguous %v | %v", email, a.Choices)
					c.JSON(300, a)
					return false
				}
			}
			if userId == "" {
				m := respMsg{"user not found via email " + email}
				if locId == "" {
					h.ws.HttpError(c, 404, m.Message, nil)
					return false
				} else { //still ok if locId is provided, we might still find something
					h.log.Trace(m.Message)
				}
			}
		}
	}
	return true
}

// Queue godoc
// @Summary check send history
// @Description
// @Tags system
// @Accept  json
// @Produce  json
// @Success 200
// @Router /queue [get]
// QueueHistory is the handler for fetch queue history
func (h *Handler) QueueHistory(c *gin.Context) {
	h.log.PushScope("QHstr")
	defer h.log.PopScope()

	req := new(reqQueueHst)
	req.Normalize()
	if e := h.ws.HttpReadQuery(c, req); e != nil {
		return
	} else if !h.validateLocUser(req, true, c) {
		return
	}

	if items, e := h.send.FetchQueued(req); e != nil {
		h.ws.HttpError(c, 500, "fetch error", e)
	} else {
		h.log.Debug("found %v", len(items))
		c.JSON(200, respQueue{Params: *req, ResultsCount: len(items), Results: items})
	}
}

type reqQueueOne struct {
	ScheduleId string `json:"scheduleId,omitempty" validate:"omitempty,min=1,max=64"`
	LocId      string `json:"locId,omitempty" validate:"omitempty,uuid_rfc4122|hexadecimal"`
	UserId     string `json:"userId,omitempty" validate:"omitempty,min=32,max=36,uuid_rfc4122|hexadecimal"`
	Email      string `json:"email,omitempty" validate:"omitempty,max=128,email"`
	Recipient  string `json:"recipient,omitempty" validate:"omitempty,max=128,email"`
	Template   string `json:"template,omitempty" validate:"omitempty,min=1,max=128"`
	Locale     string `json:"locale,omitempty" validate:"omitempty,min=2,max=5"`
	UnitSystem string `json:"unitSystem,omitempty" validate:"omitempty,min=1,max=64"`
	Force      bool   `json:"force,omitempty"`
	DryRun     bool   `json:"dryRun,omitempty"`
}

func (q reqQueueOne) String() string {
	return tryToJson(q)
}
func (q *reqQueueOne) GetKeys() (string, string, string) {
	return q.LocId, q.UserId, q.Email
}
func (q *reqQueueOne) SetUser(userId string) {
	q.UserId = userId
}
func (r *reqQueueOne) Normalize() {
	if r.Email != "" {
		r.Email = strings.ToLower(r.Email)
	}
	if r.Recipient != "" {
		r.Recipient = strings.ToLower(r.Recipient)
	}
}

type respQueueOne struct {
	Params   reqQueueOne `json:"params,omitempty"`
	Message  string      `json:"message,omitempty"`
	Resolved []*locInfo  `json:"resolved,omitempty"`
}
type locInfo struct {
	LocId string      `json:"locId,omitempty"`
	Users []*userInfo `json:"Users,omitempty"`
}

func (l *locInfo) HasUser(userId string) bool {
	u := l.GetUser(userId)
	return u != nil
}

func (l *locInfo) GetUser(userId string) *userInfo {
	if userId != "" {
		for _, u := range l.Users {
			if strings.EqualFold(u.UserId, userId) {
				return u
			}
		}
	}
	return nil
}

type userInfo struct {
	UserId string `json:"userId,omitempty"`
	Email  string `json:"email,omitempty"`
	Name   string `json:"name,omitempty"`
}

type respMsg struct {
	Message string `json:"message,omitempty"`
}

type ambiguousResp struct {
	Params  map[string]interface{} `json:"ambiguous"`
	Choices []interface{}          `json:choices`
}

func (q *reqQueueOne) Clone() (*reqQueueOne, error) {
	if q == nil {
		return nil, errors.New("nil ref")
	}
	if js, e := json.Marshal(q); e != nil {
		return nil, e
	} else {
		r := reqQueueOne{}
		if e := json.Unmarshal(js, &r); e != nil {
			return nil, e
		} else {
			return &r, nil
		}
	}
}

func (h *Handler) queueOneStrategies(r *locInfo, req *reqQueueOne) *reqQueueOne {
	if len(r.Users) == 0 {
		return nil
	}
	if req.UserId == "" && req.Email == "" { //queue entire location strategy
		if q, e := req.Clone(); e != nil {
			h.log.IfWarnF(e, "can't clone")
		} else {
			q.LocId = r.LocId
			h.schedule.QueueWork(q)
			return q
		}
	} else if req.UserId != "" { //find only specific user id strategy
		for _, u := range r.Users {
			if !strings.EqualFold(req.UserId, u.UserId) {
				continue
			} else if q, e := req.Clone(); e != nil {
				h.log.IfWarnF(e, "can't clone")
			} else {
				if req.LocId == "" {
					q.LocId = r.LocId
				} else if r.LocId != q.LocId {
					break
				}
				q.UserId = u.UserId
				h.schedule.QueueWork(q)
				return q
			}
		}
	} else if req.Email != "" { //find only specific email strategy
		for _, u := range r.Users {
			if !strings.EqualFold(req.Email, u.Email) {
				continue
			} else if q, e := req.Clone(); e != nil {
				h.log.IfWarnF(e, "can't clone")
			} else {
				if req.LocId == "" {
					q.LocId = r.LocId
				} else if r.LocId != q.LocId {
					break
				}
				q.UserId = u.UserId
				q.Email = u.Email
				h.schedule.QueueWork(q)
				return q
			}
		}
	}
	return nil
}

// Queue godoc
// @Summary force a send
// @Description
// @Tags system
// @Accept  json
// @Produce  json
// @Success 202
// @Router /queue [post]
// QueueOne is the handler for enqueue of 1 test location or user email
func (h *Handler) QueueOne(c *gin.Context) {
	h.log.PushScope("Queue1")
	defer h.log.PopScope()

	req := reqQueueOne{
		DryRun:    true,
		Force:     true,
		Recipient: h.testEmail,
	}
	if e := h.ws.HttpReadBody(c, &req); e != nil {
		return
	} else if !h.validateLocUser(&req, false, c) {
		return
	} else if req.ScheduleId != "" {
		h.ws.HttpError(c, 400, "scheduleId can not be set directly", nil)
		return
	}

	resp := respQueueOne{Params: req, Message: "accepted"}
	if req.UserId != "" { //attempt user resolution
		if usr, e := h.pubGw.GetUser(req.UserId); e == nil && usr != nil {
			resp.Resolved = usr.ToLocInfos()
		}
	} else if req.LocId == "" && req.Email != "" {
		h.ws.HttpError(c, 501, "email only request not implemented", nil)
		return
	}
	if len(resp.Resolved) == 0 && req.LocId != "" { //attempt location resolution
		if loc, e := h.pubGw.GetLocViaCache(req.LocId); e == nil && loc != nil {
			if loc.IsMultiUnit() {
				h.ws.HttpError(c, 400, "location is multi-unit: "+req.LocId, nil)
				return
			}
			resp.Resolved = []*locInfo{loc.ToLocInfo()}
		}
	}
	if len(resp.Resolved) == 0 { //found nothing
		h.ws.HttpError(c, 404, "entity not found", nil)
		return
	}

	queued := make([]*locInfo, 0)
	for _, r := range resp.Resolved {
		if q := h.queueOneStrategies(r, &req); q != nil {
			if q.UserId == "" {
				queued = append(queued, r)
			} else if u := r.GetUser(q.UserId); u != nil {
				l := locInfo{LocId: r.LocId, Users: []*userInfo{u}}
				queued = append(queued, &l)
			}
		}
	}
	if ql := len(queued); ql == 0 {
		h.ws.HttpError(c, 404, "no matching entity", nil)
	} else {
		resp.Resolved = queued
		h.log.Debug("found | %v -> %v", req, queued)
		c.JSON(202, resp)
	}
}

type reqQaHistory struct {
	Date      time.Time `json:"date,omitempty" validate:"omitempty,datetime=2006-01-02T15:04:05Z07:00"`
	Direction string    `json:"direction,omitempty" validate:"omitempty,oneof=asc desc Asc Desc ASC DESC"`
	Limit     int32     `json:"limit,omitempty" validate:"omitempty,max=500,min=1"`
	EmailType int32     `json:"emailType,omitempty" validate:"omitempty,min=0"`
	DryRun    *bool     `json:"dryRun,omitempty" validate:"omitempty"`
	HandOffs  bool      `json:"handOffs,omitempty"`
}

func (h *reqQaHistory) Normalize() *reqQaHistory {
	if h.Date.Year() > 2000 {
		h.Date = h.Date.UTC()
	} else {
		h.Date = time.Now().UTC()
	}
	if h.Direction == "" {
		h.Direction = "desc"
	} else {
		h.Direction = strings.ToLower(h.Direction)
	}
	if h.Limit < 1 {
		h.Limit = 100
	}
	return h
}

type respQaHistory struct {
	Params reqQaHistory     `json:"params,omitempty"`
	Runs   []*respQaHistRun `json:"runs,omitempty"`
}
type respQaHistRun struct {
	Id        string       `json:"id"`
	EmailType int32        `json:"emailType"`
	Params    *reqQueueAll `json:"params,omitempty"`
	Counter   int32        `json:"counter"`
	Errors    int32        `json:"errors,omitempty"`
	Completed time.Time    `json:"completed,omitempty"`
	Created   time.Time    `json:"created"`
	HandOffs  int32        `json:"handOffs,omitempty"`
}

// Queue godoc
// @Summary check run history
// @Description
// @Tags system
// @Accept  json
// @Produce  json
// @Success 202
// @Router /queue/all [get]
// QueueOne is the handler to re-run all email jobs
func (h *Handler) QueueAllHistory(c *gin.Context) {
	p := new(reqQaHistory)
	if e := h.ws.HttpReadQuery(c, p); e != nil {
		return
	} else {
		p.Normalize()
		res := respQaHistory{Params: *p}
		if res.Runs, e = h.schedule.FetchRuns(p); e != nil {
			h.ws.HttpError(c, 500, "run history fetch failed", e)
			return
		}
		c.JSON(200, res)
	}
}

type reqQueueAll struct {
	Recipient string `json:"recipient,omitempty" validate:"omitempty,max=128,email"`
	Force     bool   `json:"force,omitempty"`
	DryRun    bool   `json:"dryRun,omitempty"`
	Limit     int32  `json:"limit,omitempty" validate:"omitempty,min=0,max=500"`
	MacAddr   string `json:"macAddr,omitempty" validate:"omitempty,mac|hexadecimal"`
	TTLS      int64  `json:"ttls,omitempty" validate:"omitempty,min=0"`
}

func (a *reqQueueAll) Normalize() *reqQueueAll {
	if a.Limit < 0 {
		a.Limit = 100
	}
	if a.Recipient != "" {
		a.Recipient = strings.ToLower(a.Recipient)
		if !a.DryRun && (a.Limit < 1 || a.Limit > 10) {
			a.Limit = 10
		}
	}
	a.MacAddr = strings.ToLower(a.MacAddr)
	return a
}

type respQueueAll struct {
	Id      string       `json:"id,omitempty"`
	Message string       `json:"message,omitempty"`
	Params  *reqQueueAll `json:"params,omitempty"`
}

// Queue godoc
// @Summary force a run
// @Description
// @Tags system
// @Accept  json
// @Produce  json
// @Success 202
// @Router /queue/all [post]
// QueueOne is the handler to re-run all email jobs
func (h *Handler) QueueAll(c *gin.Context) {
	req := reqQueueAll{ //default values for safety
		DryRun:    true,
		Limit:     10,
		Recipient: h.testEmail,
		Force:     true,
	}
	if e := h.ws.HttpReadBody(c, &req); e != nil {
		return
	} else if res, e := h.schedule.Run(req.Normalize()); e != nil {
		c.JSON(e.Code, e)
	} else {
		c.JSON(202, res)
	}
}

func (h *Handler) KillAll(c *gin.Context) {
	id := c.Param("id")
	if e := h.schedule.Kill(id); e != nil {
		h.ws.HttpError(c, e.Code, e.Message, nil)
		return
	} else {
		c.JSON(202, nil)
	}
}
