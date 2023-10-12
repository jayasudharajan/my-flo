package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/go-redis/redis/v8"

	"github.com/gin-gonic/gin"
)

type handler struct {
	sl ServiceLocator
	ws *WebServer
}

type WebHandler interface {
	Ping() gin.HandlerFunc
	SimulateInboundEvent() gin.HandlerFunc
	GetInboundEventResponse() gin.HandlerFunc
	PublishEvent() gin.HandlerFunc
	ProcessMessage() gin.HandlerFunc
}

type WebHandlerConfig struct {
	sl ServiceLocator
	ws *WebServer
}

func CreateWebHandler(c *WebHandlerConfig) WebHandler {
	return &handler{
		sl: c.sl,
		ws: c.ws,
	}
}

func (h *handler) svc(c *gin.Context) ServiceLocator {
	if sl, found := c.Get("ServiceLocator"); found && sl != nil {
		return sl.(ServiceLocator) //should pull slCp
	} else {
		var (
			slCp = h.sl.Clone()
			name = fmt.Sprintf("Handler:%v", c.HandlerName())
			log  = slCp.LocateName("*Logger").(*Logger).CloneAsChild(name)
		)
		slCp.RegisterName("*Logger", func(s ServiceLocator) interface{} { return log })
		c.Set("ServiceLocator", slCp)
		return slCp
	}
}

func (h *handler) log(c *gin.Context) *Logger {
	return h.svc(c).LocateName("*Logger").(*Logger)
}

func (h *handler) redis(c *gin.Context) *RedisConnection {
	return h.svc(c).LocateName("*RedisConnection").(*RedisConnection)
}

func (h *handler) sqsReader(c *gin.Context) *SQSReader {
	return h.svc(c).LocateName("*SQSReader").(*SQSReader)
}

func (h *handler) ebClient(c *gin.Context) AWSEventBridgeClient {
	return h.svc(c).LocateName("AWSEventBridgeClient").(AWSEventBridgeClient)
}

func (h *handler) router(c *gin.Context) EventRouter {
	return h.svc(c).LocateName("EventRouter").(EventRouter)
}

func (h *handler) entityActivityCollector(c *gin.Context) EntityActivityCollector {
	return h.svc(c).LocateName("EntityActivityCollector").(EntityActivityCollector)
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
func (h *handler) Ping() gin.HandlerFunc {
	return func(c *gin.Context) {
		code := http.StatusOK
		rv := map[string]interface{}{
			"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
			"app":        _appName,
			"status":     "OK",
			"commit":     _commitSha,
			"commitTime": _commitTime,
			"host":       _hostName,
			"env":        getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
			"debug":      _log.isDebug,
			"uptime":     time.Since(_start).String(),
		}

		if c.Request.Method == "POST" {
			checks := make(map[string]string)
			h.pingDependency(c, checks, "redis", h.redis(c).Ping)
			h.pingDependency(c, checks, "sqs", h.sqsReader(c).Ping)
			h.pingDependency(c, checks, "eventbridge", h.ebClient(c).Ping)
			h.pingDependency(c, checks, "kafka", h.entityActivityCollector(c).Ping)
			rv["checks"] = checks
			for _, v := range checks {
				if v != "OK" {
					rv["status"] = "Unavailable"
					code = http.StatusServiceUnavailable
					break
				}
			}
		}
		c.JSON(code, rv)
	}
}

func (h *handler) pingDependency(ctx context.Context, m map[string]string, name string, pinger func(ctx context.Context) error) {
	if e := pinger(ctx); e != nil {
		logError("pingDependency: %v -> %v", name, e)
		m[name] = e.Error()
	} else {
		m[name] = "OK"
	}
}

func (h *handler) SimulateInboundEvent() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("SimulateEvent")
		defer log.PopScope()
		body, err := ioutil.ReadAll(c.Request.Body)
		if err != nil {
			h.ws.HttpError(c, http.StatusBadRequest, "Could not read request body", err)
			return
		}

		wrapper := EventWrapper{}
		if err = json.Unmarshal(body, &wrapper); err != nil {
			h.ws.HttpError(c, http.StatusBadRequest, "Could not convert request body into Event Wrapper", err)
			return
		} else if err = h.router(c).RouteEvent(c, &wrapper); err != nil {
			h.ws.HttpError(c, http.StatusBadRequest, fmt.Sprintf("Failed to route event: %v", err.Error()), err)
			return
		}
		h.ws.HttpEmpty(c, http.StatusNoContent)
	}
}

func (h *handler) GetInboundEventResponse() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("GetInboundEventResponse")
		defer log.PopScope()

		requestID := c.Params.ByName("requestID")
		if requestID == "" {
			h.ws.HttpError(c, http.StatusBadRequest, "Invalid request id", fmt.Errorf("request ID %v is invalid", requestID))
			return
		}

		key := fmt.Sprintf("cloudsync:event:receive:response:log:%v", requestID)
		responseInfo, err := h.redis(c).Get(c, key)
		if err != nil {
			if err != redis.Nil {
				log.Error("error getting request data from redis %v", requestID)
				h.ws.HttpError(c, http.StatusInternalServerError, "Could not fetch request data", err)
				return
			}
			h.ws.HttpError(c, http.StatusNotFound, fmt.Sprintf("Event with id %v not found", requestID), err)
			return
		} else if responseInfo == "" {
			h.ws.HttpError(c, 501, fmt.Sprintf("Event with id %v not supported", requestID), nil)
			return
		}

		responseJSON := make(map[string]interface{})
		err = json.Unmarshal([]byte(responseInfo), &responseJSON)
		if err != nil {
			log.Error("%v", err.Error())

			c.JSON(http.StatusInternalServerError, ErrorPayload{
				Type:    "Internal Server Error",
				Message: fmt.Sprintf("Error converting json: %s", responseInfo),
			})
			return
		}

		c.JSON(http.StatusOK, responseJSON)
	}
}

func (h *handler) PublishEvent() gin.HandlerFunc {
	return func(c *gin.Context) {
		var (
			log = h.log(c).PushScope("PublishEvent")
			req = EventRequestBody{}
		)
		defer log.PopScope()
		if err := h.ws.HttpReadBody(c, &req); err != nil {
			return
		}

		inp := EventBridgeClientPublishInput{
			MessageType:   req.Entity,
			MessageAction: req.Action,
			Payload:       req.Payload,
			RequestID:     c.GetHeader("x-request-id"),
		}
		if err := h.ebClient(c).Publish(c, &inp); err != nil {
			h.ws.HttpError(c, http.StatusInternalServerError, "Publish Error", err)
			return
		}
		h.ws.HttpEmpty(c, http.StatusNoContent)
	}
}

func (h *handler) ProcessMessage() gin.HandlerFunc {
	return func(c *gin.Context) {
		var (
			log = h.log(c).PushScope("ProcessMessage")
			typ = c.Param("type")
			act = c.Param("action")
			id  = c.Query("id")
		)
		defer log.PopScope()
		if typ == "" || act == "" {
			h.ws.HttpError(c, 400, "type & action parameters are required", nil)
		} else if buf, e := ioutil.ReadAll(c.Request.Body); e != nil {
			h.ws.HttpError(c, 400, "input body can not be empty", e)
		} else {
			defer c.Request.Body.Close()
			if bl := len(buf); !(bl > 2 && buf[0] == '{' && buf[bl-1] == '}') {
				h.ws.HttpError(c, 400, "input body is not JSON", nil)
				return
			}

			if id == "" {
				ent := FloEntity{}
				if e = json.Unmarshal(buf, &ent); e != nil {
					h.ws.HttpError(c, 400, "can not unmarshal JSON body", e)
					return
				} else if ent.ID == "" {
					h.ws.HttpError(c, 400, "body is missing id property, please provide as query param or JSON body field", e)
					return
				} else {
					id = ent.ID
				}
			}
			var (
				req = EntityActivityMessage{
					Id:     id,
					Date:   time.Now().Format(TIME_FMT_PUBGW),
					Type:   typ,
					Action: act,
					Item:   buf,
				}
				proc = h.entityActivityCollector(c)
				res  *EventBridgeClientPublishInput
			)
			if res, e = proc.Process(c, &req); e != nil {
				h.ws.HttpError(c, 500, e.Error(), e)
			} else if res == nil {
				c.JSON(204, nil)
			} else {
				c.JSON(200, new(procEvtBrdResp).Set(res))
			}
		}
	}
}

// proxy EventBridgeClientPublishInput to debug API resp
type procEvtBrdResp struct {
	MessageType   string      `json:"type"`
	MessageAction string      `json:"action"`
	Payload       interface{} `json:"payload"`
	RequestId     string      `json:"requestId"`
}

func (r *procEvtBrdResp) Set(o *EventBridgeClientPublishInput) *procEvtBrdResp {
	if o != nil {
		r.RequestId = o.RequestID
		r.MessageType = o.MessageType
		r.MessageAction = o.MessageAction
		r.Payload = o.Payload
	}
	return r
}
