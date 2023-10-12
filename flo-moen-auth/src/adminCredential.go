package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

type AdminCredential interface {
	GetToken(ctx context.Context, root string, http HttpUtil) (tk AdminToken, err error)
}

// wrapper that hold admin credential and logic to exchange this for an admin token
type adminCredential struct {
	Username string     `json:"username"`
	Password string     `json:"password"`
	Token    AdminToken `json:"-"`
}

func (a adminCredential) String() string {
	return fmt.Sprintf("admCred[%s]", a.Username)
}

func DefaultAdminCredential() AdminCredential {
	return &adminCredential{
		Username: getEnvOrDefault("FLO_API_ADMIN_USR", ""),
		Password: getEnvOrDefault("FLO_API_ADMIN_PWD", ""),
	}
}

func (a *adminCredential) getTkSrc(ctx context.Context, root string, http HttpUtil) (tk AdminToken, err error) {
	defer panicRecover(_log, "getTkSrc: "+root)
	var (
		url = root + "/api/v1/users/auth"
		ah  = StringPairs{AUTH_HEADER, ""} //rm built in header
		atk = AdminToken{}
	)
	if err = http.Do(ctx, "POST", url, a, nil, &atk, ah); err != nil {
		_log.IfFatalF(err, "admin login failed") //do nothing here
	} else if atk.Token != "" {
		a.Token = atk
	} else {
		err = _log.Error("admin token extraction failed")
	}
	return
}

func (a *adminCredential) GetToken(ctx context.Context, root string, http HttpUtil) (tk AdminToken, err error) {
	if root == "" {
		err = errors.New("invalid root URL")
	} else if http == nil {
		err = errors.New("httpUtil is nil")
	} else if diff := a.Token.Decay(); diff <= 0 {
		tk, err = a.getTkSrc(ctx, root, http)
	} else if diff <= time.Hour {
		_log.Info("FETCH_AHEAD getTkSrc")
		go a.getTkSrc(ctx, root, http) //fetch ahead before tk exp
	}
	tk = a.Token
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
