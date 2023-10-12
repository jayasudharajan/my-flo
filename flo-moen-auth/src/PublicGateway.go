package main

import (
	"context"
	"fmt"
	"net/url"
	"strings"
	"sync/atomic"
)

// PublicGateway service that interact with Flo v1 & v2 public API
type PublicGateway interface {
	Ping(ctx context.Context) error
	PingV1(ctx context.Context) error
	GetAdminToken(ctx context.Context) (AdminToken, error)

	Search(context.Context, *SearchCriteria) (*SearchResp, error)
	GetUser(ctx context.Context, uid, jwt string) (*FloUser, error)
	RegistrationExists(ctx context.Context, email string) (*FloEmailExists, error)
	RegisterUser(context.Context, *FloRegistration) error
	RegistrationToken(ctx context.Context, email string) (token string, er error)
	RegistrationConfirm(ctx context.Context, token string) (*FloToken, error)
	Impersonate(ctx context.Context, floUserId string) (*TokenImitate, error)
	Login(ctx context.Context, user, pwd string) (*FloToken, error)
	DeleteUser(ctx context.Context, userId string) error
	UnpairDevice(ctx context.Context, icdId string) error
	DeleteAccount(ctx context.Context, accountId string) error
	GetLocation(ctx context.Context, locId, jwt string) (*FloLocation, error)

	HttpUtil() HttpUtil
}

// NOTE: leaving redis out on purpose, write a cache decorator if needed later
type publicGateway struct {
	log      *Logger
	hu       HttpUtil
	root     string
	rootV1   string
	admin    *adminCredential
	valid    *Validator
	clientId string
	secret   string
}

var _pubGWOnce int32 //app domain singleton state

func CreatePublicGateway(
	log *Logger, httpUtil HttpUtil, admin *adminCredential, valid *Validator) PublicGateway {

	const (
		gwJwt      = "FLO_API_JWT"
		gwRoot     = "FLO_API_URL"
		gwV1Root   = "FLO_API_V1_URL"
		gwClientId = "FLO_CLIENT_ID"
		gwSecret   = "FLO_CLIENT_SECRET"
	)
	gw := publicGateway{
		log:      log.CloneAsChild("pGW"),
		hu:       httpUtil,
		root:     getEnvOrDefault(gwRoot, ""),
		rootV1:   getEnvOrDefault(gwV1Root, ""),
		admin:    admin,
		valid:    valid,
		clientId: getEnvOrDefault(gwClientId, ""),
		secret:   getEnvOrDefault(gwSecret, ""),
	}
	if gw.rootV1 == "" {
		gw.rootV1 = gw.root
	}
	if jwt := getEnvOrDefault(gwJwt, ""); jwt != "" {
		gw.hu.SetAuth(jwt) //override JWT
	}
	if atomic.CompareAndSwapInt32(&_pubGWOnce, 0, 1) { //run once & don't incl logic
		ll := LL_NOTICE
		if gw.root == "" || gw.rootV1 == "" {
			ll = LL_ERROR
		}
		gw.log.Log(ll, "%s=%q", gwRoot, gw.root)
		gw.log.Log(ll, "%s=%q", gwV1Root, gw.rootV1)

		if gw.hu.GetAuth() == "" {
			gw.log.Warn("%s is MISSING", gwJwt)
		}
		if gw.clientId == "" {
			gw.log.Warn("%s is MISSING", gwClientId)
		}
		if gw.secret == "" {
			gw.log.Warn("%s is MISSING", gwSecret)
		}
	}
	return &gw
}

func (p *publicGateway) HttpUtil() HttpUtil {
	return p.hu
}

func (p *publicGateway) Ping(ctx context.Context) error {
	e := p.hu.Do(ctx, "GET", p.root+"/api/v2/ping", nil, nil, nil)
	return p.log.IfWarnF(e, "Ping")
}

func (p *publicGateway) PingV1(ctx context.Context) error {
	e := p.hu.Do(ctx, "GET", p.rootV1+"/api/v1/ping", nil, nil, nil)
	return p.log.IfWarnF(e, "Ping")
}

func (p *publicGateway) Search(ctx context.Context, req *SearchCriteria) (*SearchResp, error) {
	p.log.PushScope("Search", req.Query)
	defer p.log.PopScope()
	if e := p.valid.Struct(req); e != nil {
		p.log.Notice("validate: %v", e)
		return nil, httpErrWrap(e, 400)
	}

	var (
		resp = SearchResp{}
		url  = fmt.Sprintf("%s/api/v1/info/users?size=%v&page=%v", p.rootV1, req.Size, req.Page)
	)
	if sp, e := p.adminAuthHeader(ctx); e != nil {
		return nil, e
	} else if er := p.hu.Do(ctx, "POST", url, req, nil, &resp, *sp); er != nil {
		switch et := er.(type) {
		case *HttpErr:
			if et.Code < 500 {
				p.log.Notice(et.Message)
			} else {
				p.log.Warn(et.Message)
			}
			return nil, et
		default:
			return nil, p.log.IfErrorF(er, "Unknown Error")
		}
	} else {
		return &resp, nil
	}
}

func (p *publicGateway) adminAuthHeader(ctx context.Context) (*StringPairs, error) {
	if tk, e := p.GetAdminToken(ctx); e != nil {
		return nil, e
	} else if tk.Token == "" {
		return nil, p.log.Warn("Token Fetch Failed")
	} else {
		return &StringPairs{AUTH_HEADER, tk.Token}, nil
	}
}

func (p *publicGateway) GetAdminToken(ctx context.Context) (tk AdminToken, err error) {
	p.log.PushScope("adminJWT")
	defer p.log.PopScope()

	if p.admin == nil {
		err = p.log.Warn("Admin credential missing")
	} else if tk, err = p.admin.GetToken(ctx, p.rootV1, p.hu); err != nil {
		p.log.IfErrorF(err, "credential err")
	}
	return
}

func (p *publicGateway) GetUser(ctx context.Context, uid, jwt string) (*FloUser, error) {
	p.log.PushScope("GetUsr", uid)
	defer p.log.PopScope()

	if e := p.valid.Value(uid, VALID_UUID); e != nil {
		p.log.Notice("invalid uid %v", e)
		return nil, httpErrWrap(e, 400)
	} else {
		uid = strings.ToLower(uid)
	}
	var (
		url = fmt.Sprintf("%s/api/v2/users/%s?expand=locations", p.root, uid)
		res = FloUser{}
		sp  *StringPairs
		e   error
	)
	if jwt != "" {
		sp = &StringPairs{AUTH_HEADER, jwt}
	} else if sp, e = p.adminAuthHeader(ctx); e != nil {
		return nil, e
	}

	if e = p.hu.Do(ctx, "GET", url, nil, nil, &res, *sp); e != nil {
		switch et := e.(type) {
		case *HttpErr:
			if et.Code < 500 {
				p.log.Notice(et.Message)
			} else {
				p.log.Warn(et.Message)
			}
			return nil, et
		default:
			return nil, p.log.IfErrorF(e, "Unknown Error")
		}
	} else {
		return &res, nil
	}
}

const VALID_EMAIL = "required,email,max=512"

// RegistrationExists step 0: check if email is taken
func (p *publicGateway) RegistrationExists(ctx context.Context, email string) (*FloEmailExists, error) {
	p.log.PushScope("RegExists", email)
	defer p.log.PopScope()

	if sp, e := p.adminAuthHeader(ctx); e != nil {
		return nil, e
	} else if e = p.valid.Value(email, VALID_EMAIL); e != nil {
		return nil, httpErrWrap(e, 400)
	} else {
		var (
			url = fmt.Sprintf("%s/api/v2/users/register?email=%s", p.root, url.QueryEscape(email))
			res = FloEmailExists{}
		)
		if e = p.hu.Do(ctx, "GET", url, nil, nil, &res, *sp); e != nil {
			switch et := e.(type) {
			case *HttpErr:
				if et.Code >= 500 {
					p.log.Warn(et.Message)
				} else {
					p.log.Notice(et.Message)
				}
			default:
				p.log.IfErrorF(e, "Unknown Error")
			}
			return nil, e
		} else {
			return &res, nil
		}
	}
}

// RegisterUser step 1: attempt registration, confirmation email will be sent
func (p *publicGateway) RegisterUser(ctx context.Context, reg *FloRegistration) error {
	sp, e := p.adminAuthHeader(ctx)
	if e == nil {
		e = p.hu.Do(ctx, "POST", p.root+"/api/v2/users/register", reg, nil, nil, *sp)
	}
	return e
}

// RegistrationToken step 2: fetch single use confirmation token (included in confirmation email)
func (p *publicGateway) RegistrationToken(ctx context.Context, email string) (token string, er error) {
	if e := p.valid.Value(email, VALID_EMAIL); e != nil {
		return "", httpErrWrap(e, 400)
	}
	var (
		url = fmt.Sprintf("%s/api/v2/users/register/token?email=%s", p.root, url.QueryEscape(email))
		sp  *StringPairs
		tk  = gwTokenResp{}
	)
	if sp, er = p.adminAuthHeader(ctx); er == nil {
		if er = p.hu.Do(ctx, "GET", url, nil, nil, &tk, *sp); er == nil {
			token = tk.Token
		}
	}
	return
}

// RegistrationConfirm step 3: confirm a user email (forcefully) using the token from step 2 since Moen email is already confirmed
func (p *publicGateway) RegistrationConfirm(ctx context.Context, token string) (*FloToken, error) {
	p.log.PushScope("RegConf")
	defer p.log.PopScope()

	if len(token) < 16 {
		p.log.Warn("Token Missing")
		return nil, &HttpErr{400, "Token Missing", false, nil}
	} else if len(p.clientId) < 8 || len(p.secret) < 8 {
		p.log.Error("ClientId or ClientSecret Missing")
		return nil, &HttpErr{500, "Service Configuration Missing", false, nil}
	}
	var (
		reg  = RegistrationConfirm{Token: token, ClientId: p.clientId, Secret: p.secret}
		url  = p.root + "/api/v2/users/register/verify"
		done = FloToken{}
	)
	if sp, e := p.adminAuthHeader(ctx); e != nil {
		return nil, e
	} else if e = p.hu.Do(ctx, "POST", url, reg, nil, &done, *sp); e != nil {
		return nil, e
	} else {
		return &done, nil
	}
}

// Impersonate issue a Flo JWT token for the provided userId
func (p *publicGateway) Impersonate(ctx context.Context, floUserId string) (*TokenImitate, error) {
	var (
		url = fmt.Sprintf("%s/api/v1/auth/user/%s/impersonate", p.rootV1, floUserId)
		req = floAuthReq{p.admin.Username, p.admin.Password}
		tk  = TokenImitate{}
	)
	if e := p.valid.Value(floUserId, "required,uuid4_rfc4122"); e != nil {
		return nil, httpErrWrap(e, 400)
	} else if e = p.hu.Do(ctx, "POST", url, &req, nil, &tk); e != nil {
		return nil, e
	}
	return &tk, nil
}

func (p *publicGateway) Login(ctx context.Context, user, pwd string) (*FloToken, error) {
	var (
		url = fmt.Sprintf("%s/api/v1/oauth2/token", p.rootV1)
		req = loginReq{p.clientId, p.secret, "password", user, pwd}
		tk  = FloToken{}
	)
	if e := p.valid.Struct(req); e != nil {
		return nil, httpErrWrap(e, 400)
	} else if e = p.hu.Do(ctx, "POST", url, &req, nil, &tk); e != nil {
		return nil, e
	}
	return &tk, nil
}

func (p *publicGateway) DeleteUser(ctx context.Context, userId string) error {
	sp, e := p.adminAuthHeader(ctx)
	if e == nil {
		e = p.hu.Do(ctx, "DELETE", p.root+"/api/v2/users/"+userId, nil, nil, nil, *sp)
	}
	return e
}

func (p *publicGateway) UnpairDevice(ctx context.Context, icdId string) error {
	sp, e := p.adminAuthHeader(ctx)
	if e == nil {
		e = p.hu.Do(ctx, "DELETE", p.root+"/api/v2/devices/"+icdId, nil, nil, nil, *sp)
	}
	return e
}

func (p *publicGateway) DeleteAccount(ctx context.Context, accountId string) error {
	sp, e := p.adminAuthHeader(ctx)
	if e == nil {
		e = p.hu.Do(ctx, "DELETE", p.root+"/api/v2/accounts/"+accountId, nil, nil, nil, *sp)
	}
	return e
}

func (p *publicGateway) GetLocation(ctx context.Context, locId, jwt string) (loc *FloLocation, e error) {
	if e = p.valid.Value(locId, VALID_UUID); e != nil {
		p.log.Notice("GetLocation: %v | %v", locId, e)
		return
	}
	var (
		url = fmt.Sprintf("%v/api/v2/locations/%v", p.root, locId)
		sp  *StringPairs
	)
	if jwt != "" {
		sp = &StringPairs{AUTH_HEADER, jwt}
	} else if sp, e = p.adminAuthHeader(ctx); e != nil {
		return
	}

	loc = new(FloLocation)
	if e = p.hu.Do(ctx, "GET", url, nil, nil, loc, *sp); e != nil {
		p.log.IfErrorF(e, "GetLocation: %v", locId)
		loc = nil
	}
	return
}
