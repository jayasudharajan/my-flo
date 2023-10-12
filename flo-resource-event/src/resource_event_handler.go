package main

import (
	"encoding/json"
	"errors"
	"strings"
	"sync/atomic"
	"time"

	"flotechnologies.com/flo-resource-event/src/commons/topic"

	"flotechnologies.com/flo-resource-event/src/commons/datefilter"
	"flotechnologies.com/flo-resource-event/src/commons/timeformat"
	"flotechnologies.com/flo-resource-event/src/commons/utils"
	"flotechnologies.com/flo-resource-event/src/commons/validator"

	"flotechnologies.com/flo-resource-event/src/handlers/models"
	"flotechnologies.com/flo-resource-event/src/resourceevent/resourceeventprocess"
	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/gin-gonic/gin"
	uuid "github.com/google/uuid"
)

const APP_NAME = "flo-resource-event"

const TOPIC_EVENT = "resource-event-v1"

type ResourceEventKafkaConfig struct {
	KafkaConnection *topic.KafkaConnection
	GroupId         string
	Topic           string
}

type ResourceEventHandler struct {
	ws                   *WebServer
	kConfig              *ResourceEventKafkaConfig
	kSub                 *topic.KafkaSubscription
	validate             *validator.Validator
	resourceEventService resourceeventprocess.ResourceEventProcessor
	pings                []func() (string, error)
	log                  *utils.Logger
	state                int32 //0=closed, 1=opened
}

func CreateResourceEventHandler(
	ws *WebServer,
	kConfig *ResourceEventKafkaConfig,
	validate *validator.Validator,
	resourceEventService resourceeventprocess.ResourceEventProcessor,
	pings []func() (string, error)) *ResourceEventHandler {

	h := ResourceEventHandler{
		ws:                   ws,
		kConfig:              kConfig,
		validate:             validate,
		resourceEventService: resourceEventService,
		pings:                pings,
		log:                  ws.Logger().CloneAsChild("hndlr"),
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
func (h *ResourceEventHandler) Health(c *gin.Context) {
	h.log.PushScope("Health")
	defer h.log.PopScope()
	var (
		started = time.Now()
		code    = 200
		status  = "OK"
		rv      = map[string]interface{}{
			"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
			"app":        APP_NAME,
			"status":     status,
			"commit":     _commitSha,
			"commitTime": _commitTime,
			"host":       _hostName,
			"env":        utils.GetEnvOrDefault("ENV", utils.GetEnvOrDefault("ENVIRONMENT", "local")),
			"debug":      utils.Log().IsDebug,
			"uptime":     utils.FmtDuration(time.Since(_start)),
		}
	)
	if c.Request.Method == "POST" {
		oks := make(map[string]string)
		for i := 0; i < len(h.pings); i++ {
			pinger := h.pings[i]
			if n, e := pinger(); e != nil {
				oks[n] = e.Error()
				code = 503
				status = "Unavailable"
			} else {
				h.log.Trace("Health: %v OK", GetFunctionName(pinger))
				oks[n] = "OK"
			}
		}
		rv["checks"] = oks
	}
	rv["tookMs"] = time.Since(started).Milliseconds()
	if strings.EqualFold(c.Query("log"), "true") {
		defer func(r interface{}, t time.Time) {
			h.log.Info("%vms | %v", time.Since(t).Milliseconds(), utils.TryToJson(r))
		}(rv, started)
	}
	c.JSON(code, rv)
}

func (h *ResourceEventHandler) ProcessResourceEventPost(c *gin.Context) {
	h.log.PushScope("ProcessResourceEventPost")
	defer h.log.PopScope()

	var req models.ExternalResourceEvent

	if e := h.ws.HttpReadBody(c, &req); e != nil {
		c.JSON(400, models.MsgResp{"Error binding resource event process request"})
		return
	}

	if err := h.validate.Struct(req); err != nil {
		c.JSON(400, utils.HttpErr{400, "Error while validating resource event process request for accountId" + req.AccountId.String(), err.Error()})
		return
	}

	if err := h.resourceEventService.ProcessResourceEvent(req); err != nil {
		c.JSON(500, utils.HttpErr{500, "ProcessResourceEventPost failed for accountId " + req.AccountId.String(), err.Error()})
		return
	}
	c.JSON(200, req)
}

func (h *ResourceEventHandler) TestPublishResourceEvent(c *gin.Context) {
	var req models.ExternalResourceEvent

	if e := h.ws.HttpReadBody(c, &req); e != nil {
		c.JSON(400, models.MsgResp{"Error binding resource event process request"})
		return
	}

	if err := h.validate.Struct(req); err != nil {
		c.JSON(400, utils.HttpErr{400, "Error while validating resource event process request for accountId" + req.AccountId.String(), err.Error()})
		return
	}

	if err := h.kConfig.KafkaConnection.Publish(h.kConfig.Topic, req, []byte(req.AccountId.String())); err != nil {
		c.JSON(500, utils.HttpErr{500, "TestPublishResourceEvent failed for accountId " + req.AccountId.String(), err.Error()})
		return
	}
	c.JSON(200, req)
}

func (h *ResourceEventHandler) AllResourceEventByAccountIdGet(c *gin.Context) {
	h.log.PushScope("AllResourceEventByAccountIdGet")
	defer h.log.PopScope()

	accountId := c.Query("accountId")
	accountUuid, parseError := uuid.Parse(accountId)

	if parseError != nil {
		c.JSON(400, utils.HttpErr{
			Code:    400,
			Message: "Required account id to get all resource events",
			Trace:   "",
		})
		return
	}

	fromDateQuery := c.Query("from")
	toDateQuery := c.Query("to")
	dateFilter := datefilter.DateFilter{}

	if fromDateQuery == "" || toDateQuery == "" {
		c.JSON(400, utils.HttpErr{
			Code:    400,
			Message: "date from and to must be specified for accountId " + accountId,
			Trace:   "",
		})
		return
	}

	fromDate, parseError := time.Parse(timeformat.TIME_FMT_TZ_OFFSET, fromDateQuery)
	if parseError != nil {
		c.JSON(400, utils.HttpErr{
			Code:    400,
			Message: "Couldn't parse from date for accountId " + accountId,
			Trace:   "",
		})
		return
	}
	dateFilter.From = fromDate

	toDate, parseError := time.Parse(timeformat.TIME_FMT_TZ_OFFSET, toDateQuery)
	if parseError != nil {
		c.JSON(400, utils.HttpErr{
			Code:    400,
			Message: "Couldn't parse from date for accountId " + accountId,
			Trace:   "",
		})
		return
	}
	dateFilter.To = toDate

	resourceEvents, err := h.resourceEventService.GetAllResourceEventByAccountId(accountUuid, dateFilter)

	if err != nil {
		c.JSON(500, utils.HttpErr{500, "AllResourceEventByAccountIdGet failed for accountId " + accountId, err.Error()})
		return
	}

	if len(resourceEvents) == 0 {
		c.JSON(404, utils.HttpErr{404, "No resource events found for accountId " + accountId, ""})
		return
	}

	c.JSON(200, resourceEvents)
}

func (h *ResourceEventHandler) Open() {
	if atomic.CompareAndSwapInt32(&h.state, 0, 1) {
		utils.RetryIfError(h.subscribe, time.Second*15, h.log)
		h.log.Info("Opened")
	}
}

func (h *ResourceEventHandler) Close() {
	if atomic.CompareAndSwapInt32(&h.state, 1, 0) {
		if h.kSub != nil {
			h.kSub.Close()
			h.kSub = nil
		}
		h.log.Info("Closed")
	}
}

func (h *ResourceEventHandler) subscribe() error {
	if atomic.LoadInt32(&h.state) != 1 {
		return errors.New("subscribe: not opened")
	}

	if sub, e := h.kConfig.KafkaConnection.Subscribe(h.kConfig.GroupId, []string{h.kConfig.Topic}, h.consume); e != nil {
		return h.log.IfWarnF(e, "subscribe topic=%q group=%q", h.kConfig.Topic, h.kConfig.GroupId)
	} else {
		if h.kSub != nil {
			h.kSub.Close()
		}
		h.kSub = sub
	}

	h.log.Notice("subscribe: OK!")

	return nil
}

func (h *ResourceEventHandler) consume(msg *kafka.Message) {
	if ml := len(msg.Value); ml < 64 || msg.Value[0] != '{' || msg.Value[ml-1] != '}' {
		return //skip
	}
	var (
		evt = models.ExternalResourceEvent{}
		e   error
	)

	h.log.Notice("kafka consumer message value", msg.Value)

	if e = json.Unmarshal(msg.Value, &evt); e != nil {
		h.log.IfErrorF(e, "consume: unmarshal")
		return
	}

	if err := h.validate.Struct(evt); err != nil {
		h.log.IfErrorF(e, "consume: validate message")
		return
	}

	h.log.Trace("%v", evt)
	if err := h.resourceEventService.ProcessResourceEvent(evt); err != nil {
		h.log.IfErrorF(e, "consume: process resource event message")
		return
	}
}
