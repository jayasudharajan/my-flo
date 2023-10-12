package main

import (
	"errors"
	"fmt"
	"time"
)

//admin credentials
type floAuthReq struct {
	UserName string `json:"username" validate:"required,email,max=512"`
	Password string `json:"password" validate:"required,min=8,max=256"`
}

type AdminCredential interface {
	GetToken(root string, http HttpUtil) (tk AdminToken, err error)
	GetCredential() *floAuthReq
}

//wrapper that hold admin credential and logic to exchange this for an admin token
type adminCredential struct {
	Username string     `json:"username"`
	Password string     `json:"password"`
	Token    AdminToken `json:"-"`
	log      Log        `json:"-"`
}

func (ac *adminCredential) GetCredential() *floAuthReq {
	return &floAuthReq{ac.Username, ac.Password}
}

func (ac adminCredential) String() string {
	return fmt.Sprintf("admCred[%s]", ac.Username)
}

func CreateAdminCredential(log Log) AdminCredential {
	return &adminCredential{
		Username: getEnvOrDefault("FLO_API_ADMIN_USR", ""),
		Password: getEnvOrDefault("FLO_API_ADMIN_PWD", ""),
		log:      log,
	}
}

func (ac *adminCredential) getTkSrc(root string, http HttpUtil) (tk AdminToken, err error) {
	defer panicRecover(ac.log, "getTkSrc: "+root)
	var (
		url = root + "/api/v1/users/auth"
		ah  = StringPairs{AUTH_HEADER, ""} //rm built in header
		atk = AdminToken{}
	)
	if err = http.Do("POST", url, ac, nil, &atk, ah); err != nil {
		ac.log.IfFatalF(err, "admin login failed") //do nothing here
	} else if atk.Token != "" {
		ac.Token = atk
	} else {
		err = ac.log.Error("admin token extraction failed")
	}
	return
}

func (ac *adminCredential) GetToken(root string, http HttpUtil) (tk AdminToken, err error) {
	if root == "" {
		err = errors.New("invalid root URL")
	} else if http == nil {
		err = errors.New("httpUtil is nil")
	} else if diff := ac.Token.Decay(); diff <= 0 {
		tk, err = ac.getTkSrc(root, http)
	} else if diff <= time.Hour {
		ac.log.Info("FETCH_AHEAD getTkSrc")
		go ac.getTkSrc(root, http) //fetch ahead before tk exp
	}
	tk = ac.Token
	return
}

type AdminToken struct {
	Token   string `json:"token"`
	Expires int64  `json:"tokenExpiration"` //sec
	Issued  int64  `json:"timeNow"`         //unix time
}

func (at *AdminToken) IssuedTime() time.Time {
	if at == nil {
		return time.Time{}
	}
	return time.Unix(at.Issued, 0).UTC()
}

func (at *AdminToken) ExpirationDuration() time.Duration {
	if at == nil {
		return 0
	}
	return time.Duration(at.Expires) * time.Second
}

func (at *AdminToken) ExpiresTime() time.Time {
	if at == nil {
		return time.Time{}
	}
	var (
		dur = at.ExpirationDuration()
		iss = at.IssuedTime()
	)
	return iss.Add(dur)
}

func (at *AdminToken) Decay() time.Duration {
	if at == nil || at.Expires <= 0 || len(at.Token) < 36 {
		return 0
	}
	diff := at.ExpiresTime().Sub(time.Now().UTC())
	return diff
}

func (at *AdminToken) AuthHeader() *StringPairs {
	if at == nil || at.Token == "" {
		return nil
	}
	return &StringPairs{AUTH_HEADER, at.Token}
}
