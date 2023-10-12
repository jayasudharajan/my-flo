package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
)

type Handler struct {
	svcLoc ServiceLocator
}

type WebHandler interface {
	Ping() gin.HandlerFunc
	Die() gin.HandlerFunc
	Catch(w *WebServer) gin.HandlerFunc
	ThrowDirective() gin.HandlerFunc

	MessageRetrievalById() gin.HandlerFunc
	MessagesByDevice() gin.HandlerFunc
	UserLink() gin.HandlerFunc
	UserUnLink() gin.HandlerFunc
	DeviceCleanup() gin.HandlerFunc

	ParseAndStoreDirectiveMiddleware() gin.HandlerFunc
	TokenCheckMiddleware() gin.HandlerFunc

	UserAuthorization() gin.HandlerFunc
	UserRefreshToken() gin.HandlerFunc
	RevokeAccess() gin.HandlerFunc
	UserProfile() gin.HandlerFunc

	DeviceDiscovery() gin.HandlerFunc
	DeviceDiscoverDebug() gin.HandlerFunc
	ValveControl() gin.HandlerFunc
	ReportState() gin.HandlerFunc
	ReportStateDebug() gin.HandlerFunc
}

func CreateWebHandler(svcLoc ServiceLocator) WebHandler {
	return &Handler{svcLoc}
}

func (h *Handler) svc(c *gin.Context) ServiceLocator {
	if svc, ok := c.Get("ServiceLocator"); ok {
		return svc.(ServiceLocator)
	} else {
		s := h.svcLoc.Clone()
		c.Set("ServiceLocator", s)
		return s
	}
}

func (h *Handler) log(c *gin.Context) *Logger {
	return h.svc(c).LocateName("*Logger").(*Logger)
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
func (h *Handler) Ping() gin.HandlerFunc {
	return func(c *gin.Context) {
		var (
			started = time.Now()
			status  = "OK"
			code    = http.StatusOK
			log     = h.log(c).PushScope("Ping")
		)
		defer log.PopScope()
		rv := map[string]interface{}{
			"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
			"app":        _appName,
			"status":     status,
			"commit":     _commitSha,
			"branch":     _commitBranch,
			"commitTime": _commitTime,
			"host":       _hostName,
			"env":        getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
			"debug":      log.isDebug,
			"uptime":     time.Since(_appStart).String(),
		}
		if c.Request.Method == "POST" { //deep ping
			var (
				svc    = h.svc(c)
				redis  = svc.SingletonName("*RedisConnection").(*RedisConnection)
				kafka  = svc.SingletonName("*KafkaConnection").(*KafkaConnection)
				pgSql  = svc.SingletonName("*PgSqlDb").(*PgSqlDb)
				pubGw  = svc.LocateName("PublicGateway").(PublicGateway)
				trace  = c.Query("trace") != ""
				checks = make(map[string]string) //TODO: maybe add SNS ping?
			)
			h.pingDependency(c, checks, "redis", redis.Ping, trace)
			h.pingDependency(c, checks, "kafka", kafka.Ping, trace)
			h.pingDependency(c, checks, "pqSql", pgSql.Ping, trace)
			h.pingDependency(c, checks, "pubGW", pubGw.PingV2, trace)
			h.pingDependency(c, checks, "pubGW_v1", pubGw.PingV1, trace)

			rv["checks"] = checks
			for _, v := range checks {
				if v != "OK" {
					rv["status"] = "Unavailable"
					code = http.StatusServiceUnavailable
					break
				}
			}
		}
		if strings.EqualFold(c.Query("log"), "true") {
			defer func(r interface{}, t time.Time) {
				log.Info("%vms | %v", time.Since(t).Milliseconds(), tryToJson(r))
			}(rv, started)
		}
		rv["took"] = time.Since(started).String()
		c.JSON(code, rv)
	}
}

func (h *Handler) Die() gin.HandlerFunc {
	return func(c *gin.Context) {
		go func() {
			h.log(c).Notice("Goodbye 💔")
			time.Sleep(time.Second / 2)
			os.Exit(0)
		}()
		c.Data(204, "text/html", nil)
	}
}

func (h *Handler) processCatch(he *HttpErr) *HttpErr {
	if he.Code < 400 {
		he.Code = 500
	} else if he.Code == 408 || he.Code == 504 {
		if n, _ := strconv.ParseFloat(he.Message, 64); n > 0 {
			time.Sleep(time.Duration(n) * time.Second)
			he.Message = fmt.Sprintf("Slept for %v seconds", n)
		} else {
			time.Sleep(time.Second * 11) //ensure timeout
		}
	}
	if he.Message == "" {
		he.Message = "Something went wrong*"
	}
	return he
}

func (h *Handler) Catch(w *WebServer) gin.HandlerFunc {
	return func(c *gin.Context) {
		he := new(HttpErr)
		if e := w.HttpReadBody(c, he); e != nil {
			return //already wrote error
		} else {
			he = h.processCatch(he)
			c.JSON(he.Code, he)
		}
	}
}

// ThrowDirective NOTE: no token check middleware
func (h *Handler) ThrowDirective() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("ThrowDirective")
		defer log.PopScope()

		payload, _ := c.Get("Directive")
		envelope := payload.(*DirectiveMessage)

		he := new(HttpErr)
		if e := jsonMap(envelope.Directive.Payload, he); e != nil {
			he.Code = 500
			he.Message = e.Error()
		} else {
			he = h.processCatch(he)
		}
		log.Info("return -> %v", he.String())
		c.JSON(he.Code, he)
	}
}

func (h *Handler) pingDependency(ctx context.Context, m map[string]string, name string, pingMe func(ctx context.Context) error, trace bool) {
	ll := IfLogLevel(trace, LL_DEBUG, LL_TRACE)
	_log.Log(ll, "pingDependency: START %v", name)
	if e := pingMe(ctx); e != nil {
		_log.IfWarnF(e, "pingDependency: FAILED %v", name)
		m[name] = e.Error()
	} else {
		_log.Log(ll, "pingDependency: OK %v", name)
		m[name] = "OK"
	}
}

func (h *Handler) isLambdaReq(c *gin.Context) bool {
	return c.Request.Method == "POST" && strings.Index(c.Request.URL.Path, "/lambda/") == 0
}

func (h *Handler) ParseAndStoreDirectiveMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !h.isLambdaReq(c) {
			c.Next()
			return
		}
		var m DirectiveMessage
		if err := c.ShouldBindWith(&m, binding.JSON); err != nil {
			h.respondWithError(c, http.StatusBadRequest, nil)
			return
		}

		if len(m.Directive.Header.MessageId) >= 12 { //only store directives with valid IDs
			logger := h.log(c)
			logger.PushScope("Msg", m.Directive.Header.MessageId) //we never pop this, logger will be destroyed
			sl := h.svc(c)
			sl.RegisterName("*Logger", func(s ServiceLocator) interface{} { //modify logger registration
				return logger //return this scoped logger instead, good for this request
			})

			go func(ctx context.Context, msg DirectiveMessage) {
				defer panicRecover(logger, "StoreDirective: %v", msg.Directive.Header) //handle possible crashes & log it
				store := sl.LocateName("EntityStore").(EntityStore)
				store.StoreDirective(ctx, &msg)
			}(c, m) //save on another thread
		}

		c.Set("Directive", &m)
		c.Next()
	}
}

func (h *Handler) verifyAccessToken(token string, sl ServiceLocator) (*User, *HttpErr) {
	var (
		pubGw     = sl.LocateName("PublicGateway").(PublicGateway)
		user, err = pubGw.GetUserFromToken(token)
	)
	if err != nil {
		switch e := err.(type) {
		case *HttpErr:
			if e.Code == 401 || e.Code == 403 {
				return nil, &HttpErr{401, "unauthorized", e}
			}
			return nil, e
		default:
			return nil, &HttpErr{500, "token verification", e}
		}
	} else if user == nil || user.Id == "" {
		return nil, &HttpErr{500, "token resolution failed", nil}
	}
	return user, nil
}

func (h *Handler) verifyIntegrationExists(ctx context.Context, userId string, sl ServiceLocator) *HttpErr {
	store := sl.LocateName("EntityStore").(EntityStore)
	if found, e := store.UserExists(ctx, userId); e != nil {
		return &HttpErr{500, "integration verification", e}
	} else if !found {
		return &HttpErr{403, "integration missing", nil}
	} else { //found!
		return nil
	}
}

// TokenCheckMiddleware verify that access token provided in scope is still valid
func (h *Handler) TokenCheckMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !h.isLambdaReq(c) {
			c.Next()
			return
		}
		var (
			directive, _ = c.Get("Directive")
			m            = directive.(*DirectiveMessage)
			s            *Scope
		)
		if m.Directive.Endpoint != nil && m.Directive.Endpoint.Scope != nil {
			s = m.Directive.Endpoint.Scope
		} else {
			var scopePayload ScopePayload
			if err := jsonMap(m.Directive.Payload, &scopePayload); err == nil {
				s = &scopePayload.Scope
			}
		}

		if s == nil || s.Type != "BearerToken" || s.Token == "" {
			h.respondWithError(c, 401, errors.New("missing scope or token"))
			return
		}

		var (
			sl    = h.svc(c)
			token = "Bearer " + s.Token
		)
		if user, err := h.verifyAccessToken(token, sl); err != nil {
			h.respondWithError(c, err.Code, err)
		} else if err = h.verifyIntegrationExists(c, user.Id, sl); err != nil {
			h.respondWithError(c, err.Code, err)
		} else {
			c.Set("User", user)
			c.Set("UserId", user.Id)
			c.Set("Token", token)
			c.Next()
		}
	}
}

// MessageRetrievalById NOTE: no middleware
func (h *Handler) MessageRetrievalById() gin.HandlerFunc {
	return func(c *gin.Context) {
		msgId := c.Params.ByName("messageId")
		if msgId == "" {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"message": "Message ID expected"})
			return
		}

		log := h.log(c).PushScope("MessageRetrievalById", msgId)
		defer log.PopScope()
		var (
			inspect = h.svc(c).LocateName("Inspector").(Inspector)
			m, err  = inspect.GetMessageById(c, msgId)
		)
		if err != nil {
			log.IfErrorF(err, "fail")
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"message": "Error getting message."})
			return
		}
		if m == nil {
			log.IfWarnF(err, "not found")
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{"message": "Directive/Event not found"})
			return
		}
		log.Info("OK")
		c.JSON(http.StatusOK, m)
	}
}

// MessagesByDevice NOTE: no middleware
func (h *Handler) MessagesByDevice() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("MessagesByDevice")
		defer log.PopScope()

		var (
			deviceId = c.Params.ByName("deviceId")
			limit, _ = strconv.Atoi(c.Query("limit"))
			inspect  = h.svc(c).LocateName("Inspector").(Inspector)
			filter   = MessageByDevice{deviceId, int32(limit)}
		)
		if filter.Limit < 0 {
			filter.Limit = 0
		}
		if res, e := inspect.GetDeviceMessages(c, &filter); e != nil {
			c.AbortWithStatusJSON(500, e)
		} else {
			c.JSON(200, res)
		}
	}
}

func (h *Handler) DeviceCleanup() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("DeviceCleanup")
		defer log.PopScope()

		var (
			rq      = CleanReq{}
			cleaner = h.svc(c).SingletonName("Cleanup").(Cleanup)
		)
		if e := c.BindJSON(&rq); e != nil {
			c.AbortWithStatusJSON(400, &HttpErr{400, e.Error(), e})
		} else if s, yes := cleaner.AlreadyCleaned(c, &rq); yes {
			msg := fmt.Sprintf("Already sync within %v by %v", cleaner.MaxInterval().String(), s)
			c.AbortWithStatusJSON(409, &HttpErr{409, msg, nil})
		} else {
			go cleaner.CleanDevices(c, &rq)
			c.JSON(202, &rq)
		}
	}
}

// UserAuthorization NOTE: no token check middleware
func (h *Handler) UserAuthorization() gin.HandlerFunc {
	return func(c *gin.Context) {
		logger := h.log(c).PushScope("UserAuthorization")
		defer logger.PopScope()

		var (
			payload, _ = c.Get("Directive")
			envelope   = payload.(*DirectiveMessage)
			accSync    = h.svc(c).LocateName("AccountSync").(AccountSync)
		)
		if authEvt, err := accSync.AuthorizationCodeGrant(c, envelope); err != nil {
			h.respondWithError(c, http.StatusUnauthorized, err)
		} else {
			logger.Info("code grant OK")
			c.JSON(http.StatusOK, authEvt)
		}
	}
}

// UserRefreshToken NOTE: no token check middleware
func (h *Handler) UserRefreshToken() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("UserRefreshToken")
		defer log.PopScope()

		var (
			payload, _ = c.Get("Directive")
			envelope   = payload.(*DirectiveMessage)
			accSync    = h.svc(c).LocateName("AccountSync").(AccountSync)
		)
		//log.Debug("UserRefreshToken: refreshing access token | messageId=%v", envelope.Directive.Header.MessageId)
		if evt, err := accSync.RefreshToken(c, envelope); err != nil {
			h.respondWithError(c, http.StatusUnauthorized, err)
		} else {
			log.Debug("refresh OK")
			c.JSON(http.StatusOK, evt)
		}
	}
}

// RevokeAccess NOTE: no token check middleware
func (h *Handler) RevokeAccess() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("RevokeAccess")
		defer log.PopScope()

		var (
			payload, _ = c.Get("Directive")
			envelope   = payload.(*DirectiveMessage)
			accSync    = h.svc(c).LocateName("AccountSync").(AccountSync)
		)
		if evt, err := accSync.RevokeAccess(c, envelope); err != nil {
			h.respondWithError(c, http.StatusUnauthorized, err)
		} else {
			log.Debug("unlink & logout OK for messageId %v", envelope.Directive.Header.MessageId)
			c.JSON(http.StatusOK, evt)
		}
	}
}

func (h *Handler) UserProfile() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("UserProfile")
		defer log.PopScope()

		var (
			userId       = c.GetString("UserId")
			user, _      = c.Get("User")
			directive, _ = c.Get("Directive")
			accSync      = h.svc(c).LocateName("AccountSync").(AccountSync)
		)
		userProfileEvent := accSync.GetUserProfile(c, user.(*User), directive.(*DirectiveMessage))
		log.Info("OK for user %s", userId)
		c.JSON(http.StatusOK, userProfileEvent)
	}
}

func (h *Handler) DeviceDiscoverDebug() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("DeviceDiscoverDebug")
		defer log.PopScope()

		var (
			userId    = c.Params.ByName("userId")
			sl        = h.svc(c)
			token     = sl.LocateName("FloJWT").(string)
			disco     = sl.LocateName("DeviceDiscovery").(DeviceDiscovery)
			directive = DirectiveMessage{
				Directive: Directive{
					Header: Header{
						Namespace:      "Alexa.Discovery",
						Name:           "Discover",
						PayloadVersion: "3",
						MessageId:      "dbg-" + strings.ReplaceAll(uuid.New().String(), "-", ""),
					},
					Payload: DiscoveryPayload{
						Scope: &Scope{
							Type:  "Bearer",
							Token: fmt.Sprintf("fake.oauth.token%v", time.Now().UTC().Unix()),
						},
					},
				},
			}
		)
		if len(userId) != 36 {
			h.respondWithError(c, 400, errors.New("invalid userId"))
		} else {
			discoveryEvent := disco.Discover(c, token, userId, &directive)
			log.Info("OK for user %s", userId)
			c.JSON(http.StatusOK, discoveryEvent)
		}
	}
}

func (h *Handler) DeviceDiscovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("DeviceDiscovery")
		defer log.PopScope()

		var (
			userId       = c.GetString("UserId")
			token        = c.GetString("Token")
			directive, _ = c.Get("Directive")
			sl           = h.svc(c)
			disco        = sl.LocateName("DeviceDiscovery").(DeviceDiscovery)
		)

		discoveryEvent := disco.Discover(c, token, userId, directive.(*DirectiveMessage))
		log.Info("OK for user %s", userId)
		c.JSON(http.StatusOK, discoveryEvent)
	}
}

func (h *Handler) ValveControl() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("ValveControl")
		defer log.PopScope()

		userId := c.GetString("UserId")
		token := c.GetString("Token")
		directive, _ := c.Get("Directive")

		directiveMsg := directive.(*DirectiveMessage)
		if directiveMsg.Directive.Endpoint == nil || directiveMsg.Directive.Endpoint.EndpointId == "" {
			h.respondWithError(c, http.StatusBadRequest, nil)
			return
		}

		devCtrl := h.svc(c).LocateName("DeviceControl").(DeviceControl)
		if evt, err := devCtrl.SetValveState(c, token, userId, directiveMsg); err != nil {
			h.handleError(c, err)
		} else {
			log.Info("OK for device %v by user %v -> %v",
				directiveMsg.Directive.Endpoint.EndpointId, userId, directiveMsg.Directive.Payload)
			c.JSON(http.StatusAccepted, evt) //async promise
		}
	}
}

// UserLink NOTE: no middleware
func (h *Handler) UserLink() gin.HandlerFunc {
	return func(c *gin.Context) {
		var (
			userId  = c.Params.ByName("userId")
			accSync = h.svc(c).LocateName("AccountSync").(AccountSync)
		)
		if res, e := accSync.LinkUser(c, userId); e != nil {
			h.handleError(c, e)
		} else {
			c.JSON(201, res)
		}
	}
}

// UserUnLink NOTE: no middleware
func (h *Handler) UserUnLink() gin.HandlerFunc {
	return func(c *gin.Context) {
		var (
			userId  = c.Params.ByName("userId")
			accSync = h.svc(c).LocateName("AccountSync").(AccountSync)
		)
		if res, e := accSync.UnLinkUser(c, userId, ""); e != nil {
			h.handleError(c, e)
		} else {
			c.JSON(200, res)
		}
	}
}

// ReportStateDebug NOTE: no middleware
// easy way to report state for a device for admins.  This EP is read only & is not exposed to lambdas or pubGW
func (h *Handler) ReportStateDebug() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("ReportStateDebug")
		defer log.PopScope()

		var (
			deviceId  = c.Params.ByName("deviceId")
			sLoc      = h.svc(c)
			token     = sLoc.LocateName("FloJWT").(string)
			devSt     = sLoc.LocateName("DeviceState").(DeviceState)
			directive = DirectiveMessage{
				Directive: Directive{
					Header: Header{
						MessageId:        "debug-" + strings.ReplaceAll(newUUID(), "-", ""),
						CorrelationToken: "debug_" + time.Now().UTC().Format(time.RFC3339),
					},
					Endpoint: &Endpoint{EndpointId: deviceId},
				},
			}
		)
		if len(deviceId) != 36 {
			h.respondWithError(c, 400, errors.New("invalid deviceId"))
		} else if report, err := devSt.BuildStateReport(c, token, &directive); err != nil {
			h.handleError(c, err)
		} else {
			log.Debug("OK for device %s", deviceId)
			c.JSON(http.StatusOK, report)
		}
	}
}

func (h *Handler) ReportState() gin.HandlerFunc {
	return func(c *gin.Context) {
		log := h.log(c).PushScope("ReportState")
		defer log.PopScope()

		userId := c.GetString("UserId")
		token := c.GetString("Token")
		directive, _ := c.Get("Directive")

		directiveMsg := directive.(*DirectiveMessage)
		if directiveMsg.Directive.Endpoint == nil || directiveMsg.Directive.Endpoint.EndpointId == "" {
			h.respondWithError(c, http.StatusBadRequest, nil)
			return
		}

		devSt := h.svc(c).LocateName("DeviceState").(DeviceState)
		if evt, err := devSt.BuildStateReport(c, token, directiveMsg); err != nil {
			h.handleError(c, err)
		} else {
			log.Info("OK for device %s by user %s", directiveMsg.Directive.Endpoint.EndpointId, userId)
			c.JSON(http.StatusOK, evt)
		}
	}
}

func (h *Handler) handleError(c *gin.Context, err error) {
	switch e := err.(type) {
	case *HttpErr:
		h.respondWithError(c, e.Code, e)
		return
	case *ValidationErr:
		h.respondWithError(c, http.StatusBadRequest, e)
		return
	default:
		h.respondWithError(c, http.StatusInternalServerError, e)
		return
	}
}

func (h *Handler) buildErrPayload(code int, err error) *ErrorPayload {
	var (
		codeName = httpCodeToRing(code)
		msg      = "Something went wrong."
	)
	switch code {
	case http.StatusUnauthorized:
		msg = "Missing or invalid access token."
		if err != nil {
			msg = err.Error()
		}
	case http.StatusForbidden:
		msg = "No integration or access."
		if err != nil {
			msg = err.Error()
		}
	case http.StatusGatewayTimeout:
		msg = "Time out."
		if err != nil {
			msg = err.Error()
		}
	case http.StatusBadRequest:
		msg = "Malformed directive."
	}
	return &ErrorPayload{Type: codeName, Message: msg}
}

func (h *Handler) respondWithError(c *gin.Context, code int, err error) {
	var (
		p                 = h.buildErrPayload(code, err)
		messageId         string
		endpoint          *Endpoint
		directive, exists = c.Get("Directive")
	)
	if exists {
		directiveMsg, _ := directive.(*DirectiveMessage)
		messageId = directiveMsg.Directive.Header.MessageId
		endpoint = directiveMsg.Directive.Endpoint
	}
	if messageId == "" {
		messageId = strings.ReplaceAll(newUUID(), "-", "")
	}

	var res EventMessage
	res.Event.Header = Header{
		Namespace:      "Alexa",
		Name:           "ErrorResponse",
		MessageId:      messageId,
		PayloadVersion: "3",
	}
	res.Event.Payload = p
	res.Event.Endpoint = endpoint

	log := h.log(c)
	if err != nil {
		if code >= http.StatusInternalServerError {
			log.IfErrorF(err, "%v - %v", code, p.Type)
		} else {
			log.IfWarnF(err, "%v - %v", code, p.Type)
		}
	} else {
		log.Notice("%v - %v | %v", code, p.Type, err)
	}
	c.AbortWithStatusJSON(code, res)
}
