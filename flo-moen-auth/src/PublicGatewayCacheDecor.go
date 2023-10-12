package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"github.com/go-redis/redis/v8"
)

// CreatePublicGatewayCached return a decorator that cache a few select public gateway calls
func CreatePublicGatewayCached(
	base PublicGateway,
	moeAuth MoenAuth,
	repo SyncStore,
	red *RedisConnection,
	log *Logger) PublicGateway {

	sec, _ := strconv.Atoi(getEnvOrDefault("FLO_PGW_USER_CACHE_TTLS", "300"))
	return &pubGwCacheDecor{
		base,
		moeAuth,
		repo,
		red,
		log.CloneAsChild("pgw$"),
		clampInt(sec, 30, 3600)}
}

type pubGwCacheDecor struct {
	base    PublicGateway
	moeAuth MoenAuth
	repo    SyncStore
	red     *RedisConnection
	log     *Logger
	usrTTLS int
}

func (p *pubGwCacheDecor) HttpUtil() HttpUtil {
	return p.base.HttpUtil()
}

func (p *pubGwCacheDecor) Ping(ctx context.Context) error {
	return p.base.Ping(ctx)
}

func (p *pubGwCacheDecor) PingV1(ctx context.Context) error {
	return p.base.PingV1(ctx)
}

func (p *pubGwCacheDecor) GetAdminToken(ctx context.Context) (AdminToken, error) {
	return p.base.GetAdminToken(ctx)
}

func (p *pubGwCacheDecor) Search(ctx context.Context, criteria *SearchCriteria) (*SearchResp, error) {
	return p.base.Search(ctx, criteria)
}

func (p *pubGwCacheDecor) usrCacheAllow(ctx context.Context, uid, authTk string) bool {
	if uid != "" {
		if authTk == "" {
			return true //will use admin token anyway, this one is allowed
		}
		if jwt, e := JwtDefDecode(authTk, p.log); e == nil && jwt != nil {
			var acc *AccountMap
			if jwt.Subject != "" && strings.Contains(strings.ToLower(jwt.Issuer), "cognito") { //moen token
				if e = p.moeAuth.VerifyJwtSignature(ctx, authTk, jwt); e == nil {
					if acc, e = p.repo.GetMap(ctx, jwt.Subject, "", jwt.Issuer); e == nil && acc != nil {
						return strings.EqualFold(acc.FloId, uid)
					}
				}
			} else if jwt.Head.Algorithm == "HS256" && jwt.UserId != "" { //assumes flo token is legit
				return strings.EqualFold(jwt.UserId, uid)
			}
		}
	}
	return false
}

func (p *pubGwCacheDecor) usrKey(uid string) string {
	k := fmt.Sprintf("fma:gw:usr:{%s}", strings.ToLower(strings.ReplaceAll(uid, "-", "")))
	if p.log.isDebug {
		k += "_" //so we don't mess w/ what's deployed
	}
	return k
}

func (p *pubGwCacheDecor) GetUser(ctx context.Context, uid, jwt string) (usr *FloUser, err error) {
	k := p.usrKey(uid)
	if cacheReadOk := p.usrCacheAllow(ctx, uid, jwt); cacheReadOk { //security check or we could accidentally give up user info
		if usr = p.cacheGetUser(ctx, k); usr != nil {
			return //cache hit!
		}
	}
	if usr, err = p.base.GetUser(ctx, uid, jwt); err == nil && usr != nil { //save to cache
		go p.cachePutUser(ctx, k, usr)
	}
	return
}

func (p *pubGwCacheDecor) cacheGetUser(ctx context.Context, key string) (usr *FloUser) {
	if js, e := p.red.Get(ctx, key); e != nil {
		if e != redis.Nil {
			p.log.IfWarnF(e, "cacheGetUser: redis get %v", key)
		}
	} else if jl := len(js); jl > 3 && js[0] == '{' && js[jl-1] == '}' {
		usr = &FloUser{}
		if e = json.Unmarshal([]byte(js), usr); e != nil {
			p.log.IfWarnF(e, "cacheGetUser: unmarshal %v", js)
			usr = nil
		}
	}
	if usr != nil {
		p.log.Trace("cacheGetUser: HIT %v", key)
	} else {
		p.log.Trace("cacheGetUser: MISS %v", key)
	}
	return
}

func (p *pubGwCacheDecor) cachePutUser(ctx context.Context, key string, usr *FloUser) {
	defer panicRecover(p.log, "cachePutUser: %v", key)

	if js, e := json.Marshal(usr); e != nil {
		p.log.IfWarnF(e, "cachePutUser: marshal %v", key)
	} else if _, e = p.red.Set(ctx, key, js, p.usrTTLS); e != nil {
		p.log.IfWarnF(e, "cachePutUser: redis set %v", key)
	} else {
		p.log.Trace("cachePutUser: OK %v", key)
	}
}

func (p *pubGwCacheDecor) RegistrationExists(ctx context.Context, email string) (*FloEmailExists, error) {
	return p.base.RegistrationExists(ctx, email)
}

func (p *pubGwCacheDecor) RegisterUser(ctx context.Context, registration *FloRegistration) error {
	return p.base.RegisterUser(ctx, registration)
}

func (p *pubGwCacheDecor) RegistrationToken(ctx context.Context, email string) (token string, er error) {
	return p.base.RegistrationToken(ctx, email)
}

func (p *pubGwCacheDecor) RegistrationConfirm(ctx context.Context, token string) (*FloToken, error) {
	return p.base.RegistrationConfirm(ctx, token)
}

func (p *pubGwCacheDecor) Impersonate(ctx context.Context, floUserId string) (*TokenImitate, error) {
	return p.base.Impersonate(ctx, floUserId)
}

func (p *pubGwCacheDecor) Login(ctx context.Context, user, pwd string) (*FloToken, error) {
	return p.base.Login(ctx, user, pwd)
}

func (p *pubGwCacheDecor) DeleteUser(ctx context.Context, userId string) error {
	return p.base.DeleteUser(ctx, userId)
}

func (p *pubGwCacheDecor) UnpairDevice(ctx context.Context, icdId string) error {
	return p.base.UnpairDevice(ctx, icdId)
}

func (p *pubGwCacheDecor) DeleteAccount(ctx context.Context, accountId string) error {
	return p.base.DeleteAccount(ctx, accountId)
}

func (p *pubGwCacheDecor) GetLocation(ctx context.Context, locId, jwt string) (*FloLocation, error) {
	return p.base.GetLocation(ctx, locId, jwt)
}
