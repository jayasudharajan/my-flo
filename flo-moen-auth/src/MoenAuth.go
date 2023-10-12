package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/lestrrat-go/jwx/jws"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"

	"github.com/lestrrat-go/jwx/jwa"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	cognito "github.com/aws/aws-sdk-go/service/cognitoidentityprovider"
	"github.com/go-redis/redis/v8"
	"github.com/lestrrat-go/jwx/jwk"
)

// MoenAuth service that interact with moen system
type MoenAuth interface {
	Ping(ctx context.Context) error
	GetUser(ctx context.Context, jwt string) (*MoenUser, error)
	Decode(jwt string) (*JwtDef, error)
	VerifyJwtSignature(ctx context.Context, jwt string, def *JwtDef) error
	PreCacheJwkSet(ctx context.Context, offset time.Duration, issuer string) error
	IssuerValid(iss string) bool
}

type moenAuth struct {
	log      *Logger
	http     HttpUtil
	redis    *RedisConnection
	valid    *Validator
	mux      sync.RWMutex
	moenVars map[string]*MoenVariables
}

func CreateMoenAuth(
	log *Logger, http HttpUtil, redis *RedisConnection, valid *Validator) MoenAuth {

	a := moenAuth{
		log:   log.CloneAsChild("MoenAuth"),
		http:  http,
		redis: redis,
		valid: valid,
	}
	a.loadPresets()
	return &a
}

func (a *moenAuth) loadPresets() {
	if len(a.moenVars) != 0 {
		return //already loaded
	}
	var (
		minDur    = time.Minute
		cfgDur, _ = time.ParseDuration(getEnvOrDefault("FLO_JWK_CACHE_DUR", (time.Minute * 5).String())) //default val
	)
	if cfgDur < minDur {
		cfgDur = minDur
	}

	jsonFile, err := os.Open("moen-variables.json")
	if err != nil {
		panic(a.log.IfFatalF(err, "loadPresets: file open")) //ends here
	}
	defer jsonFile.Close()
	var (
		byteValue, _    = ioutil.ReadAll(jsonFile)
		variablesConfig []MoenVariablesConfig
	)
	if err = json.Unmarshal(byteValue, &variablesConfig); err != nil {
		panic(a.log.IfFatalF(err, "loadPresets: unmarshal")) //ends here
	}

	varMap := make(map[string]*MoenVariables)
	for _, v := range variablesConfig {
		v.MoenVariables.JwkDur = cfgDur
		varMap[v.Issuer] = v.MoenVariables
	}
	a.moenVars = varMap
}

func (a *moenAuth) IssuerValid(iss string) bool {
	_, ok := a.moenVars[iss]
	return ok
}

func (a *moenAuth) getUserSource(ctx context.Context, jwt string, def *JwtDef) (moenUser *MoenUser, err error) {
	moenVars := a.getMoenVarsByIssuer(def.Issuer)
	if moenVars == nil {
		err = &HttpErr{401, "Unknown Issuer", false, nil}
		a.log.IfWarnF(err, "getUserSource: issuer='%v' | jwt= %v", def.Issuer, CleanJwt(jwt))
		return
	}
	fetchMoenApi := strings.EqualFold(getEnvOrDefault("FLO_MOEN_USER_VIA_MOEN_API", ""), "true")
	//by default, fetch everything from new Moen API
	if fetchMoenApi && moenVars.MoenApi != "" {
		if moenUser, err = a.getUserMoenAPI(ctx, jwt, def.Issuer, moenVars); err != nil { //check against AWS cognito: preferred
			if he, ok := err.(*HttpErr); ok && he.Code == 502 || he.Code == 503 {
				a.log.IfWarnF(err, "getUser cognitoDirectly from %s -> %v | %v", def.Issuer, he.Code, he.Trace)
				err = nil //falls through on purpose for resilient, we just don't get moen_account_id.  This happens during Moen code pushes
			} else {
				a.log.IfErrorF(err, "getUser cognitoDirectly from %s", def.Issuer)
				return
			}
		}
	}
	// after revamp of auth, all moen tokens can be read by cognito
	if moenUser == nil && strings.Contains(def.Scope, "aws.cognito.signin.user.admin") {
		if moenUser, err = a.getUserCognitoSDK(ctx, jwt, def); err != nil { //check against AWS cognito: preferred
			a.log.IfErrorF(err, "getUser cognitoDirectly from %s", def.Issuer)
			return
		}
	}
	// otherwise, try the old way
	if moenUser == nil {
		if moenUser, err = a.getUserCognitoAPI(ctx, jwt, moenVars); err != nil {
			a.log.IfErrorF(err, "getUser cognito oauth endpoint from %s", def.Issuer)
			return
		}
	}
	return
}

func (a *moenAuth) getMoenVarsByIssuer(issuer string) *MoenVariables {
	variables, ok := a.moenVars[issuer]

	if !ok {
		for v := range a.moenVars {
			//default to prod environment if a value is not find for that issuer
			if strings.Contains(v, "us-east") {
				variables = a.moenVars[v]
			}
		}
	}
	return variables
}

var _moenAuthJwkCacheScheduled int32 = 0 //only 1 pending pre-cache task

// PreCacheJwkSet ensure local set of JWK is fresh
func (a *moenAuth) PreCacheJwkSet(ctx context.Context, offset time.Duration, issuer string) error {
	if a == nil {
		return nil
	}
	moenVars := a.getMoenVarsByIssuer(issuer)
	a.mux.RLock()
	if moenVars.JwkSet == nil || time.Since(moenVars.JwkLast)+offset > moenVars.JwkDur {
		a.mux.RUnlock()
		a.mux.Lock() //switch to a stronger lock
		defer a.mux.Unlock()

		if set, e := jwk.Fetch(ctx, moenVars.CogJwkUrl); e != nil { //fetch from cognito
			a.log.IfErrorF(e, "PreCacheJwkSet: from %s", moenVars.CogJwkUrl)
			return e
		} else if set == nil || set.Len() == 0 {
			return a.log.Error("returned set has no keys")
		} else {
			moenVars.JwkSet = &set
		}

		if atomic.CompareAndSwapInt32(&_moenAuthJwkCacheScheduled, 0, 1) { //schedule next run
			go func() {
				defer panicRecover(a.log, "PreCacheJwkSet sleep thread")
				exp := time.Second * -10 //pre-cache 10s before expiration
				time.Sleep(moenVars.JwkDur - exp + time.Second)
				atomic.StoreInt32(&_moenAuthJwkCacheScheduled, 0)
				a.PreCacheJwkSet(ctx, exp, issuer)
			}()
		}
	} else {
		a.mux.RUnlock()
	}
	return nil
}

func (a *moenAuth) VerifyJwtSignature(ctx context.Context, jwt string, def *JwtDef) error {
	a.log.PushScope("verifySig", CleanJwt(jwt))
	defer a.log.PopScope()

	jwt = trimJwt(jwt)
	if keyMatches, e := a.getJwk(ctx, def.Head.KeyId, def.Issuer); e != nil {
		return &HttpErr{401, "key mismatched", false, e}
	} else {
		for _, m := range keyMatches {
			var (
				buf  = []byte(jwt)
				al   = jwa.SignatureAlgorithm(def.Head.Algorithm)
				raw  interface{}
				kBuf []byte
			)
			if e = m.Raw(&raw); e != nil {
				a.log.IfErrorF(e, "key extract failed")
				return errors.New("key extraction failed")
			} else if kBuf, e = jws.Verify(buf, al, raw); e != nil {
				a.log.IfWarnF(e, "parse")
				return &HttpErr{401, "token signature error", false, e}
			} else if len(kBuf) != 0 {
				return nil //OK!
			} //else continue loop
		}
		return &HttpErr{401, "token key not matched", false, nil}
	}
}

func (a *moenAuth) getJwk(ctx context.Context, kid, issuer string) ([]jwk.Key, error) {
	a.log.PushScope("getJwk", kid)
	defer a.log.PopScope()

	moenVars := a.getMoenVarsByIssuer(issuer)
	jwkset := *moenVars.JwkSet
	if e := a.PreCacheJwkSet(ctx, 0, issuer); e != nil {
		return nil, e
	} else if keys, ok := jwkset.LookupKeyID(kid); !ok {
		return nil, a.log.Error("token key not found")
	} else {
		return []jwk.Key{keys}, nil
	}
}

func trimJwt(jwt string) string {
	if ix := strings.LastIndex(jwt, " "); ix >= 0 {
		jwt = jwt[ix+1:] //remove Bearer
	}
	return strings.TrimSpace(jwt)
}

func (a *moenAuth) userCacheKey(jwt string, def *JwtDef) (string, error) {
	a.log.PushScope("usrK")
	defer a.log.PopScope()

	if hash, e := mh3(jwt); e != nil {
		a.log.IfErrorF(e, "mh3 jwt")
		return "", e
	} else {
		uid := strings.ReplaceAll(def.Subject, "-", "")
		return strings.ToLower(fmt.Sprintf("fl_mo:oa2_m:{%s}:%s", uid, hash)), nil
	}
}

// getUserCognitoSDK fetch user info from cognito sdk directly
func (a *moenAuth) getUserCognitoSDK(ctx context.Context, jwt string, def *JwtDef) (*MoenUser, error) {
	a.log.PushScope("getUserCognitoSDK")
	var (
		moenVars      = a.getMoenVarsByIssuer(def.Issuer)
		conf          = &aws.Config{Region: aws.String(moenVars.Region)}
		sess, _       = session.NewSession(conf)
		cognitoClient = cognito.New(sess)
		tw            = trimJwt(jwt)
	)
	tracing.WrapInstaawssdk(sess, tracing.Instana)
	resp, err := cognitoClient.GetUserWithContext(ctx, &cognito.GetUserInput{AccessToken: &tw})
	if err != nil {
		a.log.IfError(err)
		return nil, err
	}

	var (
		usr     = MoenUser{}
		attrMap = make(map[string]string)
	)
	for _, at := range resp.UserAttributes {
		if at.Value != nil {
			attrMap[*at.Name] = *at.Value
		}
	}

	attrGetter := func(key string) string {
		if val, ok := attrMap[key]; ok {
			return val
		}
		return ""
	}
	usr.Id = attrGetter("sub")
	if resp.Username != nil {
		usr.Username = *resp.Username
	}
	usr.Issuer = def.Issuer
	usr.Email = attrGetter("email")
	usr.Verified = attrGetter("email_verified")
	usr.Phone = attrGetter("phone")
	usr.FirstName = attrGetter("custom:firstName")
	usr.Lastname = attrGetter("custom:lastName")
	if usr.Id == "" {
		return nil, nil
	}
	return &usr, nil
}

// getUserCognitoAPI get user info from public cognito API
func (a *moenAuth) getUserCognitoAPI(ctx context.Context, jwt string, moenVars *MoenVariables) (*MoenUser, error) {
	a.log.PushScope("getUserCognitoAPI")
	defer a.log.PopScope()

	var (
		auth = StringPairs{AUTH_HEADER, jwt}
		url  = fmt.Sprintf("%s/oauth2/userInfo", moenVars.Uri)
		usr  = MoenUser{}
	)
	if e := a.http.Do(ctx, "GET", url, nil, nil, &usr, auth); e != nil {
		a.log.IfError(e)
		return nil, e
	} else if usr.Id != "" {
		return &usr, nil
	} else {
		return nil, nil
	}
}

func (a *moenAuth) getUserMoenAPI(ctx context.Context, jwt, iss string, moenVars *MoenVariables) (*MoenUser, error) {
	a.log.PushScope("getUserMoenAPI")
	defer a.log.PopScope()

	var (
		auth = StringPairs{AUTH_HEADER, jwt}
		url  = fmt.Sprintf("%s/v1/users/me", moenVars.MoenApi)
		acc  = MoenUserAcc{}
	)
	if e := a.http.Do(ctx, "GET", url, nil, nil, &acc, auth); e != nil {
		a.log.IfError(e)
		return nil, e
	} else if acc.Id != "" {
		return acc.asMoenUser(iss), nil
	} else {
		return nil, nil
	}
}

func (a *moenAuth) getUserCache(ctx context.Context, key string) (*MoenUser, error) {
	a.log.PushScope("$get")
	defer a.log.PopScope()

	usr := &MoenUser{}
	if js, e := a.redis.Get(ctx, key); e != nil && e != redis.Nil {
		a.log.IfErrorF(e, "redis get key %v", key)
		return nil, e
	} else if len(js) >= 36 {
		if e = json.Unmarshal([]byte(js), usr); e != nil {
			a.log.IfErrorF(e, "deserialize buf %v", js)
			return nil, e
		} else if usr.Id != "" { //found in redis
			return usr, nil
		}
	}
	return nil, nil
}

func (a *moenAuth) putUserCache(ctx context.Context, key string, def *JwtDef, usr *MoenUser) error {
	a.log.PushScope("$put").Debug("putUserCache %v -> %v", key, usr)
	defer panicRecover(a.log, "putUserCache %v -> %v", key, usr)
	defer a.log.PopScope()

	exp := time.Hour / 2
	if def != nil {
		if diff := def.ExpiresTime().Sub(time.Now()); diff > time.Second*2 {
			exp = diff - time.Second
		}
	}
	if _, e := a.redis.Set(ctx, key, tryToJson(usr), int(exp.Seconds())); e != nil {
		a.log.IfWarnF(e, "redis set key %v", key)
		return e
	}
	return nil
}

func (a *moenAuth) GetUser(ctx context.Context, jwt string) (usr *MoenUser, err error) {
	a.log.PushScope("GetUser")
	defer a.log.PopScope()

	var (
		key string
		def *JwtDef
	)
	if def, err = a.Decode(jwt); err != nil {
		//do nothing
	} else if key, err = a.userCacheKey(jwt, def); err != nil {
		//do nothing
	} else if usr, err = a.getUserCache(ctx, key); err != nil {
		//do nothing
	} else if usr == nil {
		if usr, err = a.getUserSource(ctx, jwt, def); err == nil && usr != nil {
			go a.putUserCache(ctx, key, def, usr)
		}
	}

	if usr != nil {
		if usr.Id == "" {
			usr = nil
		} else if err == nil && !usr.IsVerified() {
			err = &HttpErr{403, "Token Bearer Account is not Verified", false, nil}
			a.log.Notice("%v %v", err, usr) //only allow verified users
		} else {
			if def != nil && usr.Issuer == "" {
				usr.Issuer = def.Issuer //ensure we have this value always
			}
			if usr.Email == "" { //SEE: TRIT-3863
				if isCognitoFacebook(usr.Username) { //exception for FB, Flo requires Email. No email about the flood here 😢
					usr.Email = fmt.Sprintf("%v@facebook.com", usr.Id) //should be <fb-usr-name>@facebook.com. we don't have that 🤦‍♂️
					a.log.Debug("assigned FAKE_FB_EMAIL %v", usr)
				} else {
					a.log.Notice("NO_EMAIL %v", usr) //only allow verified users
				}
			}
		}
	}
	return
}

func (a *moenAuth) Ping(ctx context.Context) error {
	var e error
	for v := range a.moenVars {
		e = a.http.Do(ctx, "GET", a.moenVars[v].Uri, nil, nil, nil)
		a.log.IfWarnF(e, "Ping: cognito %s", a.moenVars[v].Uri)
	}
	return e
}

func (a *moenAuth) Decode(jwt string) (*JwtDef, error) {
	a.log.PushScope("Decode")
	defer a.log.PopScope()
	return JwtDefDecode(jwt, a.log)
}
