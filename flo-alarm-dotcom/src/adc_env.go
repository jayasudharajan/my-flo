package main

import (
	b64 "encoding/base64"
	"encoding/json"
	"github.com/pkg/errors"
	"io/ioutil"
	"strings"
	"sync"
)

type AdcEnv interface {
	Load(noEmpty bool) error
	Get(floCliId string) *adcEnvCfg
}

type adcEnv struct {
	cliMap map[string]*adcEnvCfg //flo Oauth2 client_id key -> adc push token EP URI
	cliLok sync.Mutex
}

type adcEnvCfg struct {
	Token  string `json:"token"`
	Notify string `json:"notify"`
	Key    string `json:"key"`
	Pwd    string `json:"pwd,omitempty"`
	PwdEnv string `json:"pwd_env,omitempty"`
	Issuer string `json:"iss"`
}

func (ac *adcEnvCfg) PrivateKey() string {
	return ac.Key
}

func (ac *adcEnvCfg) PublicKey() string {
	const pk = "/private-key."
	if strings.Contains(ac.Key, pk) { //for safety, so we don't return private key path by accident on parse err
		return strings.ReplaceAll(ac.Key, pk, "/public-key.")
	}
	return ""
}

func (ac *adcEnvCfg) KeyPass() string {
	if ac.PwdEnv != "" {
		return getEnvOrDefault(ac.PwdEnv, ac.Pwd)
	}
	return ac.Pwd
}

func CreateAdcEnv() AdcEnv {
	return &adcEnv{cliLok: sync.Mutex{}}
}

func (am *adcEnv) Load(noEmpty bool) error {
	if am.cliMap == nil { //double check lock
		am.cliLok.Lock()
		defer am.cliLok.Unlock()
		if am.cliMap == nil {
			var (
				jsCfg  = getEnvOrDefault("FLO_ADC_OAUTH2_CLIENT_JSON", "") //allow direct JSON cfg override
				name   = getEnvOrDefault("FLO_ADC_OAUTH2_CLIENT_CFG", "./keys/adc_env.json")
				cliMap = make(map[string]*adcEnvCfg)
				e      error
				buf    []byte
				isFile = false
			)
			if jl := len(jsCfg); jl > 8 {
				if jsCfg[0] == '{' && jsCfg[jl-1] == '}' {
					buf = []byte(jsCfg) //probably json buffer
				} else if buf, e = b64.StdEncoding.DecodeString(jsCfg); e != nil { //probably base64
					return errors.Wrapf(e, "adcEnv.Load: B64 DecodeString %v", jsCfg)
				}
			}
			if len(buf) == 0 {
				isFile = true
				if buf, e = ioutil.ReadFile(name); e != nil {
					return errors.Wrapf(e, "adcEnv.Load: ReadFile %v", name)
				}
			}
			if e = json.Unmarshal(buf, &cliMap); e != nil {
				return errors.Wrapf(e, "adcEnv.Load: Unmarshal %v", IfTrue(isFile, name, jsCfg))
			} else if len(cliMap) != 0 {
				if noEmpty {
					delete(cliMap, "")
				}
				am.cliMap = cliMap
			}
		}
	}
	return nil
}

func (am *adcEnv) Get(floCliId string) *adcEnvCfg {
	if am.cliMap != nil {
		if o, ok := am.cliMap[floCliId]; ok && o != nil && o.Key != "" && o.Issuer != "" && strings.Index(o.Token, "http") == 0 {
			cfg := *o   //make a copy
			return &cfg //return copy
		}
	}
	return nil
}
