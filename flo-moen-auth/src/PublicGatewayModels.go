package main

import (
	"fmt"
	"strings"
	"time"
)

type SearchCriteria struct {
	Query string `json:"query,omitempty" schema:"-" validate:"min=3,max=256"`
	Size  int32  `json:"-" schema:"size" validate:"min=0,max=200"`
	Page  int32  `json:"-" schema:"page" validate:"min=0"`
}

func (s *SearchCriteria) Normalize() *SearchCriteria {
	if s.Size < 1 {
		s.Size = 10
	}
	if s.Page < 1 {
		s.Page = 1
	}
	s.Query = strings.ToLower(strings.TrimSpace(s.Query))
	return s
}

type SearchResp struct {
	Total int32         `json:"total"`
	Items []*SearchItem `json:"items,omitempty"`
}

type SearchItem struct {
	Id        string         `json:"id"`
	Email     string         `json:"email"`
	FirstName string         `json:"firstname"`
	LastName  string         `json:"lastname"`
	Phone     string         `json:"phone_mobile,omitempty"`
	IsActive  bool           `json:"is_active"`
	Account   SearchAccount  `json:"account"`
	Devices   []SearchDevice `json:"devices,omitempty"`
	Locations []SearchLoc    `json:"geo_locations"`
	//IsSystemUser bool `json:"is_system_user"`
	//Source string `json:"source"`
}

type SearchAccount struct {
	AccountId string `json:"account_id"`
}

type SearchDevice struct {
	Id       string `json:"id"`
	MacAddr  string `json:"device_id"`
	Name     string `json:"nickname"`
	Model    string `json:"device_model"`
	Type     string `json:"device_type"`
	IsPaired bool   `json:"is_paired"`
	LocId    string `json:"location_id"`
	//TargetMode  string `json:"target_system_mode"`
	//TargetState string `json:"target_valve_state"`
}

type SearchLoc struct {
	LocId    string `json:"location_id"`
	Name     string `json:"nickname"` //not sure if this is coming through via API
	Address  string `json:"address,omitempty"`
	Address2 string `json:"address2,omitempty"`
	City     string `json:"city,omitempty"`
	PostCode string `json:"postal_code,omitempty"`
	Region   string `json:"state_or_province,omitempty"`
	Country  string `json:"country"`
	Timezone string `json:"timezone,omitempty"`
}

func (l *SearchLoc) toFloLocation() *FloLocation {
	return &FloLocation{
		Id:       l.LocId,
		Name:     l.Name, //not sure if this is available via search
		Address:  l.Address,
		Address2: l.Address2,
		City:     l.City,
		State:    l.Region,
		PostCode: l.PostCode,
		Country:  l.Country,
		Timezone: l.Timezone,
	}
}

func (d *SearchDevice) toFloDevice() *FloDevice {
	fd := FloDevice{
		Id:      d.Id,
		MacAddr: d.MacAddr,
		Name:    d.Name,
		Model:   d.Model,
		Type:    d.Type,
	}
	if d.LocId != "" {
		fd.Location = &FloEntity{d.LocId}
	}
	return &fd
}

func (o *SearchItem) toFloUser() *FloUser {
	if o == nil {
		return nil
	}
	u := FloUser{
		Id:        o.Id,
		Email:     o.Email,
		Phone:     o.Phone,
		FirstName: o.FirstName,
		LastName:  o.LastName,
		IsActive:  o.IsActive,
	}
	if o.Account.AccountId != "" {
		u.Account = &FloEntity{o.Account.AccountId}
	}
	if lc := len(o.Locations); lc > 0 {
		u.Locations = make([]*FloLocation, 0, lc)
		for _, l := range o.Locations {
			u.Locations = append(u.Locations, l.toFloLocation())
		}
	}
	if dc := len(o.Devices); dc > 0 {
		u.Devices = make([]*FloDevice, 0, dc)
		for _, d := range o.Devices {
			u.Devices = append(u.Devices, d.toFloDevice())
		}
	}
	return &u
}

type RegistrationConfirm struct {
	ClientId string `json:"clientId"`
	Secret   string `json:"clientSecret"`
	Token    string `json:"token"`
}

type FloToken struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresInS   int64  `json:"expires_in"`
	UserId       string `json:"user_id"`
	ExpiresAt    string `json:"expires_at"`
	IssuedAt     string `json:"issued_at"`
}

func (t *FloToken) Bearer() *FloToken {
	if t.TokenType == "" && t.AccessToken != "" {
		t.TokenType = "Bearer"
	}
	return t
}

func (t *FloToken) AccessTokenValue() string {
	if t.TokenType != "" {
		return fmt.Sprintf("%s %s", t.TokenType, t.AccessToken)
	}
	return t.AccessToken
}

func (t *FloToken) ExpiresIn() time.Duration {
	return time.Duration(t.ExpiresInS) * time.Second
}

func (t *FloToken) Expires() time.Time {
	const dtFmt = "2006-01-02T15:04:05.999Z"
	dt, _ := time.ParseInLocation(dtFmt, t.ExpiresAt, time.UTC)
	return dt
}

func (t *FloToken) Issued() time.Time {
	const dtFmt = "2006-01-02T15:04:05.999Z"
	dt, _ := time.ParseInLocation(dtFmt, t.IssuedAt, time.UTC)
	return dt
}

type gwTokenResp struct {
	Token string `json:"token"`
}

type FloEmailExists struct {
	Registered bool `json:"isRegistered"`
	Pending    bool `json:"isPending"`
}

//admin credentials
type floAuthReq struct {
	UserName string `json:"username" validate:"required,email,max=512"`
	Password string `json:"password" validate:"required,min=8,max=256"`
}

type TokenImitate struct {
	Token string `json:"token"`
	Now   int64  `json:"timeNow"`
	ExpS  int64  `json:"tokenExpiration"`
}

func (t TokenImitate) String() string {
	return CleanJwt(t.Token)
}

func (t *TokenImitate) IssuedAt() time.Time {
	return time.Unix(t.Now, 0)
}

func (t *TokenImitate) ExpiresIn() time.Duration {
	return time.Duration(t.ExpS) * time.Second
}

func (t *TokenImitate) ExpiresAt() time.Time {
	return t.IssuedAt().Add(t.ExpiresIn())
}

func (t *TokenImitate) IsExpired() bool {
	return t.ExpiresAt().Before(time.Now())
}

type loginReq struct {
	ClientId     string `json:"client_id" validate:"required,uuid4_rfc4122"`
	ClientSecret string `json:"client_secret" validate:"required,min=6,max=256"`
	GrantType    string `json:"grant_type" validate:"required,min=6,max=32"`
	UserName     string `json:"username" validate:"required,email,max=512"`
	Password     string `json:"password" validate:"required,min=8,max=256"`
}

// safe toString
func (l *loginReq) String() string {
	return fmt.Sprintf("client_id=%s,username=%s", l.ClientId, l.UserName)
}
