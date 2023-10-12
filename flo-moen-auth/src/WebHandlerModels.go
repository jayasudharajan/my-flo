package main

import (
	"context"
	"strings"
)

type Pingable interface {
	Ping(ctx context.Context) error
}

type cognitoErr struct {
	Type string `json:"error"`
	Desc string `json:"error_description"`
}

type CognitoUserResp struct {
	User  *MoenUser `json:"user"`
	Token *JwtDef   `json:"token"`
}

type newUserOption struct {
	FirstName  string `json:"firstName" validate:"omitempty"`
	LastName   string `json:"lastName" validate:"omitempty"`
	Email      string `json:"email" validate:"omitempty"`
	Phone      string `json:"phone" validate:"omitempty,e164"`
	Country    string `json:"country" validate:"omitempty,len=2,alpha"`
	Password   string `json:"password" validate:"omitempty"`
	Locale     string `json:"locale,omitempty" validate:"omitempty,len=5"`
	SetMissing bool   `json:"setMissing" validate:"omitempty"`
}

func (o *newUserOption) toFloRegistration(u *MoenUser) *FloRegistration {
	r := FloRegistration{
		FirstName: u.FirstName,
		LastName:  u.Lastname,
		Phone:     u.Phone,
		Email:     u.Email,
		Password:  o.Password,
		Locale:    o.Locale,
		SkipCheck: true, //always skip email send
	}
	if o.Email != "" {
		r.Email = o.Email
	}
	if o.Country != "" {
		r.Country = o.Country
	}
	if o.FirstName != "" && (!o.SetMissing || (o.SetMissing && r.FirstName == "")) {
		r.FirstName = o.FirstName
	}
	if o.LastName != "" && (!o.SetMissing || (o.SetMissing && r.LastName == "")) {
		r.LastName = o.LastName
	}
	if o.Phone != "" && (!o.SetMissing || (o.SetMissing && r.Phone == "")) {
		r.Phone = o.Phone
	}
	if r.Phone != "" {
		r.Phone = strings.ReplaceAll(r.Phone, " ", "")
	}
	return &r
}

type syncedUserResp struct {
	AccountId string `json:"accountId"`
	UserId    string `json:"userId"`
}

type tokenTradeResp struct {
	Type  string `json:"type,omitempty"`
	Token string `json:"token"`
	Use   string `json:"use,omitempty"`
}

func (t tokenTradeResp) String() string {
	return CleanJwt(t.Token)
}
