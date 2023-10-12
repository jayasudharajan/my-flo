package main

import (
	"errors"
	"fmt"
	"github.com/gin-gonic/gin"
	"strings"
	"time"
)

type HomeGraphHandler interface {
	JwtCheckMidWare(c *gin.Context)
	IntentReqMidWare(c *gin.Context)

	Fulfillment(c *gin.Context)
}

type homeGraph struct {
	svc ServiceLocator
	adc AdcEnv
}

func CreateHomeGraphHandler(svc ServiceLocator) HomeGraphHandler {
	adc := svc.LocateName("AdcEnv").(AdcEnv)
	return &homeGraph{svc, adc}
}

func (h *homeGraph) allowJwtClient(clientId string) bool {
	cfg := h.adc.Get(clientId)
	return cfg != nil
}

// JwtCheckMidWare ensure Authorization header contains a valid JWT
// context variable `*JwtPayload` is set if successful
func (h *homeGraph) JwtCheckMidWare(c *gin.Context) {
	var (
		sl     = h.svc.Context(c)
		log    = sl.LocateName("Log").(Log)
		ws     = sl.SingletonName("WebServer").(WebServer)
		jwtStr = JwtTrim(c.GetHeader(AUTH_HEADER))
		jwt    = JwtPayload{}
	)
	log.PushScope("JwtChkr")
	defer log.PopScope()
	c.Set("Log", log)

	//NOTE: all ops from this point naturally requires JWT forwarded to PubGW :. we're not checking for token validity here
	if jwtStr == "" {
		ws.HttpError(c, 401, "Unauthorized: credential required", nil)
	} else if jwtRaw, e := JwtDecode(jwtStr); e != nil {
		ws.HttpError(c, 401, "Unauthorized: invalid token", e)
	} else if e = jsonMap(jwtRaw.Body, &jwt); e != nil {
		ws.HttpError(c, 401, "Unauthorized: invalid token content", e)
	} else if (jwt.ClientId != "" || jwt.TokenId != "") && !h.allowJwtClient(jwt.ClientId) {
		ws.HttpError(c, 401, "Unauthorized: token client not allowed", e)
	} else {
		c.Set("*JwtPayload", &jwt)
		log.Trace("OK for userId=%v jti=%v", jwt.FloUserId(), jwt.TokenId)
		c.Next() //allow further processing
	}
}

// use in conjunction with JwtCheckerMidWare to pull *JwtPayload from gin ctx
func (h *homeGraph) jwtPayload(c *gin.Context) *JwtPayload {
	if jwtRaw, ok := c.Get("*JwtPayload"); ok && jwtRaw != nil {
		if jwt, good := jwtRaw.(*JwtPayload); good {
			return jwt
		}
	}
	return nil
}

// IntentReqMidWare extract `*intentReq` from http req and store it in gin ctx
func (h *homeGraph) IntentReqMidWare(c *gin.Context) {
	var (
		sl  = h.svc.Context(c)
		log = sl.LocateName("Log").(Log)
		ws  = sl.SingletonName("WebServer").(WebServer)
		req = intentReq{}
	)
	log.PushScope("intentReq")
	defer log.PopScope()

	if e := ws.HttpReadBody(c, &req); e != nil { //input validation here if obj decorated
		return //do nothing, error is already written to resp
	} else {
		if any := req.WhereInputs(func(input *intentInput) bool {
			return input.Intent == string(IntentSync)
		}); len(any) == 0 { //no discovery in payload, check to see if user is in repo registry
			var (
				repo = sl.LocateName("EntityStore").(EntityStore)
				jwt  = h.jwtPayload(c)
				usr  *LinkedUser
			)
			if usr, e = repo.Get(jwt.UserId, false); e != nil {
				ie := HgIntentError{
					RequestId: req.RequestId,
					Payload:   CreateHgError("relinkRequired", e),
				}
				log.IfWarn(&ie)
				c.AbortWithStatusJSON(200, &ie)
				return
			} else if usr == nil || !strings.EqualFold(usr.UserId, jwt.UserId) {
				ie := HgIntentError{
					RequestId: req.RequestId,
					Payload:   CreateHgError("relinkRequired", errors.New("account not linked "+jwt.UserId)),
				}
				log.IfWarn(&ie)
				c.AbortWithStatusJSON(200, &ie)
				return
			}
		}
		c.Set("*intentReq", &req)
		log.Trace("OK for reqId=%v", req.RequestId)
		c.Next() //allow further processing
	}
}

// use in conjunction with IntentReqMidWare to pull *intentReq from gin ctx
func (h *homeGraph) intentReq(c *gin.Context) *intentReq {
	if raw, ok := c.Get("*intentReq"); ok && raw != nil {
		if req, good := raw.(*intentReq); good {
			return req
		}
	}
	return nil
}

func (h *homeGraph) ctx(c *gin.Context) *intentCtx {
	var (
		now = time.Now().UTC()
		sl  = h.svc.Context(c)
		log = sl.LocateName("Log").(Log)
		ws  = sl.SingletonName("WebServer").(WebServer)
		req = h.intentReq(c)
		jwt = h.jwtPayload(c)
	)
	return &intentCtx{sl, log, ws, req, jwt, c, now}
}

type intentCtx struct {
	sl      ServiceLocator
	log     Log
	ws      WebServer
	req     *intentReq
	jwt     *JwtPayload
	gc      *gin.Context
	created time.Time
}

func (ic *intentCtx) Req() *intentReq {
	return ic.req
}
func (ic *intentCtx) AuthHeader() string {
	return ic.gc.GetHeader(AUTH_HEADER)
}
func (ic *intentCtx) Jwt() *JwtPayload {
	if raw, ok := ic.gc.Get("*JwtPayload"); ok {
		tk, _ := raw.(*JwtPayload)
		return tk
	}
	return nil
}
func (ic *intentCtx) UserId() string {
	return ic.jwt.FloUserId()
}
func (ic *intentCtx) Log() Log {
	return ic.log
}
func (ic *intentCtx) Elapsed() time.Duration {
	if start, ok := ic.gc.Get("StartTime"); ok && start != nil {
		if dt, good := start.(time.Time); good && dt.Year() > 2006 {
			return time.Since(dt)
		}
	}
	return time.Since(ic.created)
}
func (ic intentCtx) String() string {
	var (
		inputs   []*intentInput
		jti, usr string
	)
	if ic.jwt != nil {
		usr = ic.jwt.FloUserId()
		jti = ic.jwt.TokenId
	}
	if ic.req != nil {
		inputs = ic.req.Inputs
	}
	return fmt.Sprintf("usr=%v jti=%v inputs=%v", usr, jti, tryToJson(inputs))
}

func (h *homeGraph) Fulfillment(c *gin.Context) {
	ctx := h.ctx(c)
	ctx.log.PushScope("Fulfill", ctx.req.RequestId)
	defer ctx.log.PopScope()

	if count := len(ctx.req.Inputs); count != 1 {
		ctx.ws.HttpError(c, 400, fmt.Sprintf("Bad Request: Inputs count must be 1 instead of %v", count), nil)
		return
	}
	input := ctx.req.Inputs[0]
	ctx.log.PushScope(fmt.Sprintf("{%v}", input.Intent))
	defer ctx.log.PopScope()

	if logic := ctx.sl.LocateName(input.Intent); logic != nil {
		if intent, ok := logic.(IntentInvoker); ok && intent != nil {
			ctx.log.Debug("Invoke | %v", ctx)
			if payload, err := h.invoke(intent, ctx); err != nil {
				h.respErrAbort(ctx, err)
			} else if payload == nil { //panic recovered
				he := CreateHgError("hardError", errors.New("invoke panic recovered: "+ctx.req.RequestId))
				h.respOk(ctx, &intentResp{ctx.req.RequestId, he})
			} else { //wrap intent resp envelope
				h.respOk(ctx, &intentResp{ctx.req.RequestId, payload})
			}
			return
		}
	}
	h.respErrAbort(ctx, &HttpErr{400, "Bad Request: Invalid Intent - " + input.Intent, nil})
	return
}

func (h *homeGraph) invoke(intent IntentInvoker, ctx *intentCtx) (interface{}, error) {
	defer panicRecover(ctx.log, "invoke")
	if payload, err := intent.Invoke(ctx); err != nil {
		return nil, err
	} else {
		return payload, nil
	}
}

type intentResp struct {
	RequestId string      `json:"requestId"`
	Payload   interface{} `json:"payload"`
}

func (h *homeGraph) respOk(ctx *intentCtx, res *intentResp) {
	ctx.gc.JSON(200, res)
	ctx.log.Debug("Invoke | OK took=%v", ctx.Elapsed())
}

func (h *homeGraph) respErrAbort(ctx *intentCtx, e error) {
	var (
		inner    error
		httpResp = func(er, inner error) {
			ctx.log.IfErrorF(er, "userId=%v jti=%v %v | %v",
				ctx.jwt.FloUserId(), ctx.jwt.TokenId, tryToJson(ctx.req.Inputs), inner)
			ctx.gc.AbortWithStatusJSON(200, er) //hg spec demands 200 for hg domain error
		}
	)
	if wrp, ok := e.(ErrorWrapped); ok {
		inner = wrp
	}
	switch v := e.(type) {
	case *HttpErr:
		code := hgErrCode(v.Code)
		wrp := HgIntentError{ctx.req.RequestId, CreateHgError(code, v), nil}
		httpResp(&wrp, v)
	case *HgError: //wrap it as an intent err
		wrp := HgIntentError{ctx.req.RequestId, v, nil}
		httpResp(&wrp, inner)
	case *HgIntentError, *HgDevicesError: //straight through
		httpResp(v, inner)
	default:
		ctx.ws.HttpThrow(ctx.gc, e) //api level exception, fall back to http protocol handling
	}
}

func hgErrCode(httpErrCode int) string {
	code := "hardError"
	switch httpErrCode {
	case 400:
		code = "valueOutOfRange"
	case 401:
		code = "relinkRequired"
	case 403:
		code = "authFailure"
	case 404:
		code = "deviceNotFound"
	case 502, 503:
		code = "transientError"
	}
	return code
}
