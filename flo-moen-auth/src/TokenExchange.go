package main

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/go-redis/redis/v8"
)

// TokenExchange handle the exchange between Moen's JWT for Flo's JWT
type TokenExchange interface {
	Trade(ctx context.Context, moenJwt string) (floJwt string, err error)
	Store(ctx context.Context, moenJwt, floJwt string) error
	RemoveUser(ctx context.Context, moenId string, localOnly bool) error
}

type tokenExchange struct {
	log   *Logger
	moen  MoenAuth
	pubGW PublicGateway
	repo  SyncStore
	redis *RedisConnection //level 2 cache
	cache RamCache         //level 1 cache, should be a singleton ref here
}

func CreateTokenExchange(
	log *Logger,
	moen MoenAuth,
	pubGW PublicGateway,
	repo SyncStore,
	redis *RedisConnection,
	cache RamCache) TokenExchange {

	//TODO: subscribe to flo-moen kafka topic unlink event & clear local ramCache
	return &tokenExchange{
		log:   log.CloneAsChild("TkExch"),
		moen:  moen,
		pubGW: pubGW,
		repo:  repo,
		redis: redis,
		cache: cache}
}

// Store is for external process to store a pair of validated jwt tokens
func (tx *tokenExchange) Store(ctx context.Context, moenJwt, floJwt string) error {
	tx.log.PushScope("Store")
	defer tx.log.PopScope()

	if moenCx, e := tx.context(moenJwt); e != nil {
		return e
	} else {
		tx.put(ctx, moenCx, floJwt)
		return nil
	}
}

// Trade take takes moen access token & return flo access token
func (tx *tokenExchange) Trade(ctx context.Context, moenJwt string) (floJwt string, err error) {
	tx.log.PushScope("Trade")
	defer tx.log.PopScope()

	if moenCx, e := tx.context(moenJwt); e != nil {
		err = httpErrWrap(e, 401)
	} else if err = moenCx.Validate(); err != nil { //token chk
		tx.log.Info("context chk failed | %v", err)
	} else if err = tx.moen.VerifyJwtSignature(ctx, moenJwt, moenCx.def); err != nil {
		tx.log.Info("sig chk failed | %v", err)
	} else if floJwt, err = tx.get(ctx, moenCx); err == nil && floJwt == "" { //get frm $
		if floJwt, err = tx.source(ctx, moenCx); err == nil && floJwt != "" { //get frm api
			tx.put(ctx, moenCx, floJwt) //store $
		}
	}
	return
}

// build local context obj
func (tx *tokenExchange) context(token string) (*tokenCtx, error) {
	var (
		cx = tokenCtx{jwt: token}
		er error
	)
	cx.def, er = tx.moen.Decode(token)
	return &cx, er
}

type tokenCtx struct {
	jwt string
	def *JwtDef
}

func tokenExchangeKey(subjectId, tokenId string) string {
	return tokenExchangeSubjectKey(subjectId) + strings.ToLower(strings.ReplaceAll(tokenId, "-", ""))
}

func tokenExchangeSubjectKey(subjectId string) string {
	return strings.ToLower(fmt.Sprintf("tkxch:{%s}:", strings.ReplaceAll(subjectId, "-", "")))
}

func (tcx *tokenCtx) Key() string {
	return tokenExchangeKey(tcx.def.Subject, tcx.def.TokenId)
}

func (tcx *tokenCtx) SubjectKey() string {
	return tokenExchangeSubjectKey(tcx.def.Subject)
}

// ExpireS return how many seconds left until this item expires
func (tcx *tokenCtx) ExpireS() int {
	return int(tcx.def.ExpiresTime().Sub(time.Now()).Seconds())
}

func (tcx *tokenCtx) Validate() error {
	var (
		er     error
		err401 = func(m string) *HttpErr {
			return &HttpErr{401, m, false, nil}
		}
	)

	if tcx == nil || tcx.def == nil {
		er = err401("Token Decode Failed")
	} else if tcx.def.TokenId == "" {
		er = err401("Missing Token Id")
	} else if tcx.def.Subject == "" {
		er = err401("Missing Subject")
	} else if tcx.def.IsExpired() {
		er = err401("Token Expired")
	} else if iss := strings.ToLower(tcx.def.Issuer); iss == "" {
		er = err401("Missing Token Issuer")
	} else if !(strings.Contains(iss, "cognito") && strings.Contains(iss, "amazonaws.com")) {
		er = err401("Invalid Token Issuer")
	}
	return er
}

// attempt to pull token from local cache then redis
func (tx *tokenExchange) get(ctx context.Context, tk *tokenCtx) (floJwt string, err error) {
	ramKey := tk.Key()
	if v := tx.cache.Load(ramKey); v != nil { //pull local cache
		floJwt = v.(string)
		return
	}

	var (
		hashKey = tk.SubjectKey()
		op      = redis.ZRangeBy{Min: fmt.Sprint(tk.def.Expires), Max: fmt.Sprint(tk.def.Expires), Count: 1}
		cmd     = tx.redis._client.ZRangeByScore(ctx, hashKey, &op)
		arr     []string
	)
	if arr, err = cmd.Result(); err != nil { //pull redis
		if err == redis.Nil {
			err = nil
			tx.putRedis(ctx, tk, "")
		} else {
			tx.log.IfErrorF(err, "getCache: ZRangeByScore %q %q %q", hashKey, op.Min, op.Max)
		}
	} else if len(arr) == 1 && arr[0] != "" { //found in redis, store in local cache
		var jwtBuf []byte //unzip buffer
		if jwtBuf, err = fromGzip([]byte(arr[0])); err != nil {
			tx.log.IfErrorF(err, "getCache: fromGzip")
		} else if len(jwtBuf) > 36 {
			floJwt = string(jwtBuf)
		}
	}
	tx.cache.Store(ramKey, floJwt, tk.def.ExpiresTime()) //cache even the empty case for quicker resp
	return
}

// insert into local cache & redis
func (tx *tokenExchange) put(ctx context.Context, tk *tokenCtx, jwt string) {
	if tk.ExpireS() > 10 {
		tx.cache.Store(tk.Key(), jwt, tk.def.ExpiresTime())
		go tx.putRedis(ctx, tk, jwt)
	}
}

func (tx *tokenExchange) putRedis(ctx context.Context, tk *tokenCtx, jwt string) {
	panicRecover(tx.log, "putRedis")

	var jwtBuf []byte //gzip buffer to reduce space
	if jwt == "" {
		jwtBuf = []byte{}
	} else if buf, e := toGzip([]byte(jwt)); e != nil {
		tx.log.IfErrorF(e, "putRedis: toGzip")
		return
	} else {
		jwtBuf = buf
	}

	var (
		sk  = tk.SubjectKey()
		z   = redis.Z{Score: float64(tk.def.Expires), Member: jwtBuf}
		cmd = tx.redis._client.ZAddNX(ctx, sk, &z)
	)
	if n, e := cmd.Result(); e != nil && e != redis.Nil {
		tx.log.IfErrorF(e, "putRedis: ZAddNX %q %v", sk, z)
	} else {
		var (
			now = fmt.Sprint(time.Now().Unix())
			rm  = tx.redis._client.ZRemRangeByScore(ctx, sk, "-inf", now) //clean stale keys
		)
		if _, e = rm.Result(); e != nil && e != redis.Nil {
			tx.log.IfWarnF(e, "putRedis: ZRemRangeByScore %q -inf %q", sk, now)
		}
		if n > 0 { //if set ok, update expiration
			if _, e = tx.redis.Expire(ctx, sk, tk.ExpireS()+60); e != nil && e != redis.Nil {
				tx.log.IfWarnF(e, "putRedis: Expire %q", sk)
			}
		}
	}
}

// RemoveUser force expiration of all jwt related to token subject
func (tx *tokenExchange) RemoveUser(ctx context.Context, moenId string, localOnly bool) error {
	tx.log.PushScope("RmUsr", moenId)
	defer tx.log.PopScope()

	hashKey := tokenExchangeSubjectKey(moenId)
	tx.cache.EvictMatch(hashKey) //local eviction first
	if !localOnly {              //nuke redis
		if _, e := tx.redis.Delete(ctx, hashKey); e != nil && e != redis.Nil { //nuke the whole map
			tx.log.IfErrorF(e, "redis Del %q", hashKey)
			return e
		}
	}
	return nil
}

// most costly way to generate token, no cache
func (tx *tokenExchange) source(ctx context.Context, moenCx *tokenCtx) (floJwt string, err error) {
	tx.log.PushScope("source")
	defer tx.log.PopScope()

	var (
		usr *MoenUser
		acc *AccountMap
		ftk *TokenImitate
	)
	if usr, err = tx.moen.GetUser(ctx, moenCx.jwt); err == nil {
		if !usr.IsVerified() {
			err = tx.log.Warn("Moen User is not Verified")
		} else if acc, err = tx.repo.GetMap(ctx, usr.Id, "", moenCx.def.Issuer); err == nil {
			if acc == nil || acc.FloId == "" {
				err = tx.log.Warn("Moen User is not Synced")
			} else {
				if acc.NeedRepair() && usr.AccountId != "" {
					go tx.fixSyncData(ctx, usr, acc) //side thread ops
				}
				if ftk, err = tx.pubGW.Impersonate(ctx, acc.FloId); err != nil {
					tx.log.IfErrorF(err, "Impersonation error")
				} else if floJwt = ftk.Token; floJwt == "" {
					err = tx.log.Error("Impersonation failed")
				} else {
					tx.log.Debug("OK for Moen tid=%s", moenCx.def.TokenId)
				}
			}
		}
	}
	if err != nil {
		err = httpErrWrap(err, 401)
	}
	return
}

func (tx *tokenExchange) fixSyncData(ctx context.Context, moe *MoenUser, og *AccountMap) {
	defer panicRecover(tx.log, "fixSyncData: %v", og)
	var (
		fx  = false //dirty marker
		acc = *og   //make a copy
	)
	if acc.MoenAccountId == "" && moe.AccountId != "" {
		acc.MoenAccountId = moe.AccountId
		fx = true
	}
	if acc.Issuer == "" && moe.Issuer != "" {
		acc.Issuer = moe.Issuer
		fx = true
	}
	if acc.FloAccountId == "" && acc.FloId != "" {
		if flo, e := tx.pubGW.GetUser(ctx, acc.FloId, ""); e != nil {
			tx.log.IfWarnF(e, "fixSyncData: pubGW.GetUser %v", acc.FloId)
		} else if aid := flo.AccountId(); aid != "" {
			acc.FloAccountId = aid
			fx = true
		}
	}
	if fx {
		tx.log.Notice("fixSyncData: %v => %v", tryToJson(og), tryToJson(&acc))
		tx.repo.Save(ctx, &acc)
	}
}
