package main

import (
	"strings"
	"time"

	"github.com/lestrrat-go/jwx/jwk"
)

type MoenEntity struct {
	Id string `json:"id"`
}

type MoenIntegration struct {
	State string `json:"state"`
}

// MoenUserAcc is current Moen API (post Flo engineering) model
type MoenUserAcc struct {
	FirstName string `json:"firstName,omitempty"`
	Lastname  string `json:"lastName,omitempty"`
	Phone     string `json:"phoneNumber,omitempty"`
	Email     string `json:"email"`

	Id            string                      `json:"id"`
	EmailVerified bool                        `json:"emailVerified"`
	PhoneVerified bool                        `json:"phoneVerified"`
	Status        string                      `json:"status"`
	Provider      string                      `json:"identityProvider,omitempty"`
	ProviderId    string                      `json:"identityProviderId,omitempty"`
	Username      string                      `json:"username,omitempty"`
	Enabled       bool                        `json:"enabled"`
	Created       PubGwTime                   `json:"createdDate"`
	Updated       PubGwTime                   `json:"updatedDate"`
	Account       *MoenEntity                 `json:"account,omitempty"`
	Integrations  map[string]*MoenIntegration `json:"integrations,omitempty"`
}

func (ua *MoenUserAcc) AccountId() string {
	if ua == nil || ua.Account == nil {
		return ""
	}
	return ua.Account.Id
}

func (ua *MoenUserAcc) isVerified() bool {
	return ua != nil && (ua.EmailVerified || ua.PhoneVerified || isCognitoSso(ua.Username) || isOurEmail(ua.Email))
}

func (ua *MoenUserAcc) asMoenUser(iss string) *MoenUser {
	if ua == nil {
		return nil
	}
	u := MoenUser{
		Email:     ua.Email,
		Id:        ua.Id,
		Username:  ua.Username,
		Issuer:    iss,
		FirstName: ua.FirstName,
		Lastname:  ua.Lastname,
		Phone:     ua.Phone,
	}
	if aid := ua.AccountId(); aid != "" {
		u.AccountId = aid
	}
	if ua.isVerified() {
		u.Verified = "true"
	} else {
		u.Verified = "false"
	}
	return &u
}

// isOurEmail returns true if email is a known Flo or Moen's email
func isOurEmail(email string) bool {
	return strings.Contains(email, "+") && (strings.HasSuffix(email, "@flotechnologies.com") || strings.HasSuffix(email, "@fbgpg.com") || strings.HasSuffix(email, "@moen.com"))
}

func isCognitoFacebook(username string) bool {
	return strings.Index(username, "Facebook_") == 0
}

func isCognitoApple(username string) bool {
	return strings.Index(username, "SignInWithApple_") == 0
}

func isCognitoGoogle(username string) bool {
	return strings.Index(username, "Google_") == 0
}

func isCognitoSso(username string) bool {
	if username != "" {
		if isCognitoGoogle(username) || isCognitoApple(username) || isCognitoFacebook(username) {
			return true
		}
	}
	return false
}

// MoenUser is the original (v1) model that legacy system return that mimic cognito's model
type MoenUser struct {
	Verified  string `json:"email_verified,omitempty"`
	Email     string `json:"email"`
	Id        string `json:"sub"`
	Username  string `json:"username"`
	Issuer    string `json:"issuer,omitempty"`
	FirstName string `json:"firstName,omitempty"`
	Lastname  string `json:"lastName,omitempty"`
	Phone     string `json:"phone,omitempty"`
	AccountId string `json:"account_id,omitempty"`
}

func (u *MoenUser) IsVerified() bool {
	return u != nil && (strings.EqualFold(u.Verified, "true") || isCognitoSso(u.Username) || isOurEmail(u.Email))
}

func (u MoenUser) String() string {
	return tryToJson(u)
}

func (u *MoenUser) asAccountMap(floUsr *FloUser) *AccountMap {
	if u == nil {
		return nil
	}
	am := AccountMap{
		MoenId:        u.Id,
		MoenAccountId: u.AccountId,
		Issuer:        u.Issuer,
	}
	if floUsr != nil && floUsr.Id != "" {
		am.FloId = floUsr.Id
		if aid := floUsr.AccountId(); aid != "" {
			am.FloAccountId = aid
		}
	}
	return &am
}

type MoenVariablesConfig struct {
	Issuer        string         `json:"issuer"`
	MoenVariables *MoenVariables `json:"variables"`
}

type MoenVariables struct {
	MoenApi   string        `json:"moenApi"` //root url
	Uri       string        `json:"uri"`
	Region    string        `json:"region"`
	CogClient string        `json:"cogClient"`
	CogSecret string        `json:"cogSecret"`
	CogJwkUrl string        `json:"cogJwkUrl"`
	JwkSet    *jwk.Set      `json:"jwkSet"`  //local cached set
	JwkLast   time.Time     `json:"jwkLast"` //last pulled
	JwkDur    time.Duration `json:"jwkDur"`  //how long to cache for
}

func (j *JwtDef) IssueAtTime() time.Time {
	return time.Unix(j.IssueAt, 0)
}

func (j *JwtDef) ExpiresTime() time.Time {
	return time.Unix(j.Expires, 0)
}

func (j *JwtDef) IsExpired() bool {
	if j == nil {
		return true
	}
	return j.ExpiresTime().Before(time.Now())
}

func (j JwtDef) String() string {
	return tryToJson(j)
}
