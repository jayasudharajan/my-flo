package main

import (
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
	"github.com/lestrrat-go/jwx/jwa"
	"github.com/lestrrat-go/jwx/jwk"
	"github.com/lestrrat-go/jwx/jwt"
	"io/ioutil"
	"strings"
	"time"
)

type AdcTokenManager interface {
	Env() AdcEnv
	PublicRawPem(floO2Cli string) ([]byte, error)
	PublicJWK(floO2Cli string) (interface{}, error)
	CustomToken(floO2Cli string) (res *AdcCustomTk, e error)
	PushToken(floO2Cli string, sync bool) (o *OAuthResponse, err error)
}

func CreateAdcTokenManager(log Log, htu HttpUtil, appCx *appContext, adcEnv AdcEnv) AdcTokenManager {
	return &atkMan{log, htu, appCx, adcEnv}
}

type atkMan struct {
	log    Log
	htu    HttpUtil
	appCx  *appContext
	adcEnv AdcEnv
}

func init() {
	jwt.Settings(jwt.WithFlattenAudience(true))
}

func (am *atkMan) Env() AdcEnv {
	return am.adcEnv
}

func (am *atkMan) PublicRawPem(floO2Cli string) ([]byte, error) {
	if cfg := am.adcEnv.Get(floO2Cli); cfg == nil {
		return nil, &HttpErr{404, "client_id not found", nil}
	} else if pubKey := cfg.PublicKey(); pubKey == "" {
		return nil, &HttpErr{501, "public key not configured", nil}
	} else if buf, e := ioutil.ReadFile(cfg.PublicKey()); e != nil {
		return nil, &HttpErr{500, "public key not found", nil}
	} else {
		return buf, nil
	}
}

func (am *atkMan) publicPem(floO2Cli string) (interface{}, error) {
	if buf, err := am.PublicRawPem(floO2Cli); err != nil {
		return nil, err
	} else if block, _ := pem.Decode(buf); block == nil || len(block.Bytes) == 0 || !strings.Contains(block.Type, "PUBLIC KEY") {
		return nil, errors.New("failed to decode PEM block containing public key")
	} else if pub, e := x509.ParsePKIXPublicKey(block.Bytes); e != nil {
		return nil, e
	} else {
		return pub, nil
	}
}

// PublicJWK converts ./keys/<env>/public-key.pem
func (am *atkMan) PublicJWK(floO2Cli string) (res interface{}, err error) {
	am.log.PushScope("JWK")
	defer am.log.PopScope()
	var (
		pub    interface{}
		rawKey jwk.Key //jwk.RSAPublicKey
	)
	if pub, err = am.publicPem(floO2Cli); err != nil {
		am.log.IfErrorF(err, "loadPubPem")
	} else if rawKey, err = jwk.New(pub); err != nil {
		am.log.IfErrorF(err, "jwk.New")
	} else if _, err = am.setKid(rawKey); err != nil {
		am.log.IfErrorF(err, "setKid")
	} else {
		res = rawKey
	}
	return
}

func (am *atkMan) setKid(key jwk.Key) (string, error) {
	if pubHash, e := mh3(key); e != nil {
		return "", e
	} else {
		kid := fmt.Sprintf("flo-%v:%v", am.appCx.App, pubHash)
		e = key.Set(jwk.KeyIDKey, kid)
		return kid, e
	}
}

type AdcCustomTk struct {
	Body   *adcEvtToken `json:"body"`
	Signed string       `json:"signed"` //signed custom token
}

type adcEvtToken struct {
	Issuer   string `json:"iss"`
	Scope    string `json:"scope"`
	Audience string `json:"aud"`
	IssuedAt int64  `json:"iat"`
	ExpireAt int64  `json:"exp"`
}

func (at *adcEvtToken) ToOAuthResp(access, refresh string) *OAuthResponse {
	return &OAuthResponse{
		access,
		refresh,
		int(at.ExpireAt - at.IssuedAt),
		int(at.IssuedAt),
		"adc_custom",
		at.Issuer,
		"",
	}
}

func (am *atkMan) privatePem(floO2Cli string) (interface{}, error) {
	if cfg := am.adcEnv.Get(floO2Cli); cfg == nil {
		return nil, &HttpErr{404, "client_id not found", nil}
	} else if priKey := cfg.PrivateKey(); priKey == "" {
		return nil, &HttpErr{501, "private key not configured", nil}
	} else if buf, e := ioutil.ReadFile(priKey); e != nil {
		return nil, e
	} else if block, _ := pem.Decode(buf); block == nil || len(block.Bytes) == 0 || !strings.Contains(block.Type, "PRIVATE KEY") {
		return nil, errors.New("failed to decode PEM block containing private key")
	} else {
		if x509.IsEncryptedPEMBlock(block) {
			if buf, e = x509.DecryptPEMBlock(block, []byte(cfg.KeyPass())); e != nil {
				return nil, e
			} else {
				return x509.ParsePKCS1PrivateKey(buf)
			}
		} else {
			return x509.ParsePKCS1PrivateKey(block.Bytes)
		}
	}
}

func (am *atkMan) privateJwk(floO2Cli string) (key jwk.Key, e error) {
	am.log.PushScope("priJwk")
	defer am.log.PopScope()

	var pri interface{}
	if pri, e = am.privatePem(floO2Cli); e != nil {
		am.log.IfErrorF(e, "loadPrivatePem")
	} else if key, e = jwk.New(pri); e != nil {
		am.log.IfErrorF(e, "jwk.New")
	} else if _, e = am.setKid(key); e != nil {
		am.log.IfErrorF(e, "setKid")
	}
	return
}

func (am *atkMan) buildAdcToken(floO2Cli string) (*adcEvtToken, error) {
	if cfg := am.adcEnv.Get(floO2Cli); cfg == nil || cfg.Issuer == "" {
		return nil, errors.New("issuer not found for client_id")
	} else {
		var (
			now  = time.Now().Unix()
			body = adcEvtToken{
				Issuer:   cfg.Issuer,
				Scope:    "standardapi",
				Audience: "~/OAuth2/Token.ashx",
				IssuedAt: now,
				ExpireAt: now + 3600,
			}
		)
		return &body, nil
	}
}

func (am *atkMan) CustomToken(floO2Cli string) (res *AdcCustomTk, e error) {
	am.log.PushScope("gen")
	defer am.log.PopScope()
	var (
		body *adcEvtToken
		bMap = make(map[string]interface{})
	)
	if body, e = am.buildAdcToken(floO2Cli); e != nil {
		am.log.IfErrorF(e, "buildAdcToken: %q", floO2Cli)
	} else if e = jsonMap(body, &bMap); e != nil {
		am.log.IfErrorF(e, "jsonMap")
	} else {
		var (
			t   = jwt.New()
			buf []byte
			key jwk.Key
		)
		for k, v := range bMap {
			t.Set(k, v)
		}
		if key, e = am.privateJwk(floO2Cli); e != nil {
			am.log.IfErrorF(e, "privateJwk")
		} else if buf, e = jwt.Sign(t, jwa.RS256, key); e != nil {
			am.log.IfErrorF(e, "jwt.Sign")
		} else {
			res = &AdcCustomTk{body, string(buf)}
		}
	}
	return
}

func (am *atkMan) exchange(customJwt, floO2Cli string) (o *OAuthResponse, err error) {
	var (
		start = time.Now()
		req   = map[string]interface{}{
			"assertion":  customJwt,
			"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
		}
		res = OAuthResponse{ClientId: floO2Cli}
	)
	if cfg := am.adcEnv.Get(floO2Cli); cfg == nil {
		err = am.log.Error("exchange: adcEnv.Get %q Not Found!", floO2Cli)
	} else if err = am.htu.Form("POST", cfg.Token, req, nil, &res); err != nil {
		am.log.IfErrorF(err, "exchange: (Form) %v", CleanToken(customJwt))
	} else if res.AccessToken != "" {
		o = &res
		if o.IatDt().Year() < 2000 {
			o.IssuedAt = int(start.Unix())
		}
		if o.ExpiresIn <= 0 { //force 5min exp if not found in resp
			o.ExpiresIn = 300
		}
		am.log.Info("exchange: %v OK | took=%v", CleanToken(customJwt), time.Since(start))
	} else {
		err = am.log.Warn("exchange: (Form) %v -> nil", CleanToken(customJwt))
	}
	return
}

func (am *atkMan) PushToken(floO2Cli string, sync bool) (*OAuthResponse, error) {
	var (
		preset  = fmt.Sprint(IfTrue(am.appCx.IsProd(), "", "true"))
		mockCfg = getEnvOrDefault("FLO_ADC_MOCK", preset)
		mock    = strings.EqualFold(mockCfg, "true")
	)
	if tk, err := am.CustomToken(floO2Cli); err != nil {
		return nil, err
	} else if mock && !am.appCx.IsProd() { //mock for all env except for prod!
		res := tk.Body.ToOAuthResp(tk.Signed, "")
		res.ClientId = floO2Cli
		return res, nil
	} else {
		return am.exchange(tk.Signed, floO2Cli)
	}
}
