package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	//_ "gitlab.com/flotechnologies/flo-moen-auth/docs"
)

// WebHandler broker http request & response with other services. Its job is mainly formatting & validation
type WebHandler interface {
	Ping(c *gin.Context) //endpoints w/o Authorization middleware
	TokenTrade(c *gin.Context)
	LookupSyncIds(c *gin.Context)
	CacheInvalidate(c *gin.Context)

	EnsureAuthorizedDecorator(c *gin.Context) //middlewares

	GetMoenUser(c *gin.Context)
	CheckSync(c *gin.Context)
	GetFloUser(c *gin.Context)
	CreateFloUser(c *gin.Context)
	SyncFloUser(c *gin.Context)
	UnSyncFloUser(c *gin.Context)
	SyncAuthorizedUser(c *gin.Context)

	GetFloLocMap(c *gin.Context)
	PutFloLocMap(c *gin.Context)
	RemoveFloLocMap(c *gin.Context)
}

type webHandler struct {
	locator  ServiceLocator
	ws       *WebServer
	authPath func(ctx *gin.Context) bool
}

func CreateWebHandler(sl ServiceLocator, web *WebServer, authPath func(ctx *gin.Context) bool) WebHandler {
	return &webHandler{sl, web, authPath}
}

func (h *webHandler) svc(c *gin.Context) ServiceLocator {
	if sl, found := c.Get("ServiceLocator"); found && sl != nil {
		return sl.(ServiceLocator) //should pull slCp
	} else {
		var (
			slCp = h.locator.Clone()
			log  = slCp.LocateName("*Logger").(*Logger).CloneAsChild("Hndlr")
		)
		slCp.RegisterName("*Logger", func(s ServiceLocator) interface{} { return log })
		c.Set("ServiceLocator", slCp)
		return slCp
	}
}

func (h *webHandler) log(c *gin.Context) *Logger {
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
func (h *webHandler) Ping(c *gin.Context) {
	var (
		started = time.Now()
		sl      = h.svc(c)
		app     = sl.LocateName("*appContext").(*appContext)
	)
	rv := map[string]interface{}{
		"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
		"app":        app.App,
		"status":     "OK",
		"branch":     app.CodeBranch,
		"commit":     app.CodeHash,
		"commitTime": app.CodeTime,
		"host":       app.Host,
		"env":        app.Env,
		"debug":      h.log(c).isDebug,
		"uptime":     time.Since(app.Start).String(),
	}
	if c.Request.Method == "POST" { //deep ping
		var (
			errAr = make([]string, 0)
			stats = make(map[string]string)
			log   = h.log(c)
		)
		safePing := func(name string, p Pingable) error { //crash proofing
			defer panicRecover(log, "Ping: %v", name)
			return p.Ping(c)
		}
		check := func(name string, p Pingable) {
			if e := safePing(name, p); e != nil {
				stats[name] = e.Error()
				errAr = append(errAr, name)
			} else {
				stats[name] = "OK"
			}
		}

		check("redis", sl.LocateName("*RedisConnection").(*RedisConnection))
		check("pgsql", sl.LocateName("*PgSqlDb").(*PgSqlDb))
		check("auth", sl.LocateName("MoenAuth").(MoenAuth))

		pGw := sl.LocateName("PublicGateway").(PublicGateway)
		check("pubGWv2", pGw)
		check("pubGWv1", &pingAdaptor{pGw.PingV1})

		actMon := sl.SingletonName("ActivityMonitor").(ActivityMonitor)
		check("kafka", actMon)

		if len(errAr) > 0 {
			rv["status"] = strings.Join(errAr, ", ") + " failed"
		}
		rv["checks"] = stats
	}
	rv["took"] = time.Since(started).String()
	c.JSON(200, rv)
}

type pingAdaptor struct {
	png func(ctx context.Context) error
}

func (p *pingAdaptor) Ping(ctx context.Context) error {
	return p.png(ctx)
}

// EnsureAuthorizedDecorator Ensure request has Moen Cognito JWT in Authorization header & store it in gin context
func (h *webHandler) EnsureAuthorizedDecorator(c *gin.Context) {
	log := h.log(c).PushScope("EnsureAuthorized")
	if h.authPath != nil && !h.authPath(c) {
		log.Trace("EnsureAuthorized: SKIP %v %v", c.Request.Method, c.Request.URL)
		c.Next() //skipping auth check for this path
		return
	}

	if jwt := c.GetHeader(AUTH_HEADER); len(jwt) < 36 {
		h.ws.HttpError(c, 401, "Missing or Invalid JWT", nil)
	} else {
		ma := h.svc(c).LocateName("MoenAuth").(MoenAuth)
		if def, er := ma.Decode(jwt); er != nil {
			h.ws.HttpError(c, 401, er.Error(), er)
		} else if er = ma.VerifyJwtSignature(c, jwt, def); er != nil {
			h.ws.HttpError(c, 401, "Bad Token Signature", er)
		} else if def.IsExpired() {
			h.ws.HttpError(c, 401, "Token Expired!", er)
		} else if usr, e := ma.GetUser(c, jwt); e != nil {
			switch et := e.(type) {
			case *HttpErr:
				if et.IsJSON {
					cog := cognitoErr{}
					if jsErr := json.Unmarshal([]byte(et.Message), &cog); jsErr != nil {
						log.IfWarnF(e, "EnsureAuthorized: unmarshal cognitoErr %v", et.Message)
					} else if cog.Type != "" || cog.Desc != "" {
						et.Message = fmt.Sprintf("EnsureAuthorized: %v - %v", cog.Type, cog.Desc)
						et.IsJSON = false
					}
				}
				h.ws.HttpError(c, et.Code, et.Message, et.Trace)
			default:
				h.ws.HttpError(c, 500, "EnsureAuthorized Failed", nil)
			}
		} else {
			c.Set("*MoenUser", usr)
			log.PopScope().PushScope("Usr", usr.Id).Trace("EnsureAuthorized: OK %v", usr)

			c.Next()
		}
	}
}

func (h *webHandler) user(c *gin.Context) *MoenUser {
	if u, found := c.Get("*MoenUser"); found && u != nil {
		return u.(*MoenUser)
	} else {
		return nil
	}
}

func (h *webHandler) jwt(c *gin.Context) *JwtDef {
	if o, found := c.Get("*JwtDef"); found && o != nil {
		return o.(*JwtDef) //pull from cache
	} else if tk := c.Request.Header.Get(AUTH_HEADER); len(tk) >= 36 {
		if def, e := JwtDefDecode(tk, h.log(c)); e == nil && def != nil {
			c.Set("*JwtDef", def) //cache put
			return def
		}
	}
	return nil
}

func (h *webHandler) GetMoenUser(c *gin.Context) {
	res := CognitoUserResp{}
	res.User = h.user(c)
	res.Token = h.jwt(c)
	c.JSON(200, &res)
}

func (h *webHandler) CheckSync(c *gin.Context) {
	var (
		usr  = h.user(c)
		sync = h.svc(c).LocateName("AccountSync").(AccountSync)
	)
	if code, e := sync.IsSync(c, usr); e != nil {
		h.ws.HttpError(c, h.maxInt(500, code), "Sync Check Error", e)
	} else {
		h.ws.HttpEmpty(c, int(code))
	}
}

func (_ *webHandler) maxInt(a int32, bs SyncState) int {
	b := int32(bs)
	if a >= b {
		return int(a)
	} else {
		return int(b)
	}
}

func (h *webHandler) GetFloUser(c *gin.Context) {
	var (
		usr  = h.user(c)
		sync = h.svc(c).LocateName("AccountSync").(AccountSync)
	)
	if acc, e := sync.GetFloUser(c, usr); e != nil {
		h.ws.HttpError(c, h.maxInt(500, acc.State), "Sync Check Error.", e)
	} else if acc.User == nil {
		if acc.State == 404 {
			c.JSON(404, HttpErr{404, "Matching Email Not Found", false, nil})
		} else {
			h.ws.HttpEmpty(c, int(acc.State))
		}
	} else {
		c.JSON(int(acc.State), acc.User)
	}
}

func (h *webHandler) LookupSyncIds(c *gin.Context) {
	var (
		sync    = h.svc(c).LocateName("AccountSync").(AccountSync)
		look    = SyncLookup{}
		rmCache = strings.EqualFold(c.Query("sync"), "true") //synchronous op, combine cache flush
	)
	if h.ws.HttpReadQuery(c, &look) != nil {
		return
	}
	if rmCache && (look.FloId != "" || look.MoenId != "") {
		h.popCache(c, &look)
	}
	if acc, e := sync.GetSyncData(c, &look); e != nil {
		if he, ok := e.(*HttpErr); ok && he.Code >= 400 && he.Code < 500 {
			h.ws.HttpError(c, he.Code, he.Message, he)
		} else {
			h.ws.HttpError(c, 500, "Id Lookup Error", nil)
		}
	} else if acc != nil && acc.FloId != "" && acc.MoenId != "" {
		c.JSON(200, acc)
	} else {
		c.JSON(404, &HttpErr{404, "Id Not Found", false, nil})
	}
}

func (h *webHandler) CacheInvalidate(c *gin.Context) {
	look := SyncLookup{}
	if h.ws.HttpReadQuery(c, &look) != nil {
		return
	} else if look.MoenId == "" && look.FloId == "" {
		c.JSON(400, &HttpErr{400, "floId or moenId is required", false, nil})
		return
	}
	h.popCache(c, &look)
	c.JSON(204, nil)
}

func (h *webHandler) popCache(c *gin.Context, look *SyncLookup) {
	var (
		sync = h.svc(c).LocateName("AccountSync").(AccountSync)
		ev   = LinkEvent{}
	)
	if look.FloId != "" {
		ev.User = &FloEntity{Id: look.FloId}
	}
	if look.MoenId != "" {
		ev.External.Id = look.MoenId
		ev.External.Vendor = "moen"
		ev.External.Type = "user"
	}
	sync.UserCacheClean(&ev)
}

func (h *webHandler) CreateFloUser(c *gin.Context) {
	var (
		usr  = h.user(c)
		sl   = h.svc(c)
		sync = sl.LocateName("AccountSync").(AccountSync)
		exch = sl.LocateName("TokenExchange").(TokenExchange)
		op   = newUserOption{}
	)
	if h.ws.HttpReadBody(c, &op) != nil {
		//do nothing, ws already returned
	} else if rr, e := sync.RegisterUser(c, usr, &op); e != nil {
		switch et := e.(type) {
		case *HttpErr:
			c.AbortWithStatusJSON(et.Code, et)
		default:
			h.ws.HttpError(c, 500, "Create Account Error", e)
		}
	} else {
		authArr := strings.Split(c.Request.Header.Get(AUTH_HEADER), " ")
		if al := len(authArr); al > 0 {
			exch.Store(c, authArr[al-1], rr.Token.Bearer().AccessTokenValue()) //precache in token exchange
		}
		url := getEnvOrDefault("FLO_API_URL", "")
		url = fmt.Sprintf("%s/api/v2/users/%s", url, rr.User.Id)
		c.Header("Location", url)
		c.JSON(201, syncedUserResp{rr.User.AccountId(), rr.User.Id})
	}
}

func (h *webHandler) SyncFloUser(c *gin.Context) {
	var (
		moe = h.user(c) //moen user
		acc = h.svc(c).LocateName("AccountSync").(AccountSync)
	)
	if flo, e := acc.LinkUser(c, moe); e != nil {
		switch et := e.(type) {
		case *HttpErr:
			c.AbortWithStatusJSON(et.Code, et)
		default:
			h.ws.HttpError(c, 500, "Sync Account Error", e)
		}
	} else {
		c.JSON(200, syncedUserResp{flo.AccountId(), flo.Id})
	}
}

func (h *webHandler) UnSyncFloUser(c *gin.Context) {
	var (
		moe              = h.user(c) //moen user
		acc              = h.svc(c).LocateName("AccountSync").(AccountSync)
		forced           = strings.EqualFold(c.Query("forced"), "true")
		deleteFloAccount = strings.EqualFold(c.Query("account"), "true")
	)
	if e := acc.UnLinkUser(c, moe, forced, deleteFloAccount); e != nil {
		switch et := e.(type) {
		case *HttpErr:
			c.AbortWithStatusJSON(et.Code, et)
		default:
			h.ws.HttpError(c, 500, "UnSync Account Error", e)
		}
	} else {
		h.ws.HttpEmpty(c, 200) //empty body OK
	}
}

func (h *webHandler) SyncAuthorizedUser(c *gin.Context) {
	var req = floAuthReq{}
	if e := h.ws.HttpReadBody(c, &req); e == nil {
		var (
			moe = h.user(c)
			acc = h.svc(c).LocateName("AccountSync").(AccountSync)
			flo *FloUser
		)
		if flo, e = acc.LinkAuthorized(c, moe, req.UserName, req.Password); e != nil {
			switch et := e.(type) {
			case *HttpErr:
				c.AbortWithStatusJSON(et.Code, et)
			default:
				h.ws.HttpError(c, 500, "Sync Authorized Account Error", e)
			}
		} else {
			c.JSON(200, syncedUserResp{flo.AccountId(), flo.Id})
		}
	} //else case already return http err
}

// TokenTrade EP does not rely on Authorization middleware on purpose for better performance, it will be heavily used
func (h *webHandler) TokenTrade(c *gin.Context) {
	var (
		sl   = h.svc(c)
		auth = c.Request.Header.Get(AUTH_HEADER)
		exch = sl.LocateName("TokenExchange").(TokenExchange)
	)
	if auth == "" {
		h.ws.HttpError(c, 401, "Authorization Missing", nil)
	} else if tkStr, e := exch.Trade(c, auth); e != nil {
		h.ws.HttpErrorResp(c, e)
	} else {
		var (
			arr = strings.Split(tkStr, " ")
			use = "access"
		)
		if al := len(arr); al == 1 {
			c.JSON(200, tokenTradeResp{"", arr[0], use})
		} else if al == 2 {
			c.JSON(200, tokenTradeResp{arr[0], arr[1], use})
		} else {
			h.ws.HttpError(c, 500, "Token Exception", nil)
		}
	}
}

func (h *webHandler) GetFloLocMap(c *gin.Context) {
	var (
		repo  = h.svc(c).LocateName("LocationStore").(LocationStore)
		match = getLocMatch{}
		page  = skipLimPage{}
		locs  []*SyncLoc
	)
	if e := h.ws.HttpReadQuery(c, &match); e != nil {
		return //do nothing, err reported by func
	} else if e = h.ws.HttpReadQuery(c, &page); e != nil {
		return //do nothing, err reported by func
	} else if locs, e = repo.GetList(c, &match, &page); e != nil {
		h.ws.HttpErrorResp(c, e)
	} else {
		if locs == nil {
			locs = make([]*SyncLoc, 0)
		}
		c.JSON(200, &locMapResp{&match, &page, locs, ""})
	}
}

type locMapResp struct {
	Match   *getLocMatch `json:"match,omitempty"`
	Page    *skipLimPage `json:"page,omitempty"`
	Items   []*SyncLoc   `json:"items"`
	Message string       `json:"message,omitempty"`
}

type locLinkReq struct {
	FloId  string `json:"floId" validate:"required,uuid4_rfc4122"`
	MoenId string `json:"moenId" validate:"required,uuid4_rfc4122"`
}

func (ll locLinkReq) String() string {
	return fmt.Sprintf("flo=%v,moe=%v", ll.FloId, ll.MoenId)
}

func (h *webHandler) PutFloLocMap(c *gin.Context) {
	var (
		acc = h.svc(c).LocateName("AccountSync").(AccountSync)
		req = locLinkReq{}
	)
	if e := h.ws.HttpReadBody(c, &req); e != nil {
		return //do nothing, err already handled
	} else if e = acc.LinkLocation(c, &req); e != nil {
		h.ws.HttpErrorResp(c, e)
	} else {
		h.ws.HttpEmpty(c, 200)
	}
}

func (h *webHandler) RemoveFloLocMap(c *gin.Context) {
	var (
		acc   = h.svc(c).LocateName("AccountSync").(AccountSync)
		match = getLocMatch{}
		locs  []*SyncLoc
	)
	if e := h.ws.HttpReadQuery(c, &match); e != nil {
		return //do nothing, err reported by func
	} else if locs, e = acc.UnLinkLocation(c, &match); e != nil {
		h.ws.HttpErrorResp(c, e)
	} else {
		var (
			code = 200
			resp = locMapResp{&match, nil, locs, ""}
		)
		if len(locs) == 0 {
			code = 404
			if resp.Items == nil {
				resp.Items = make([]*SyncLoc, 0)
			}
			resp.Message = "No location removed"
		}
		c.JSON(code, &resp)
	}
}
