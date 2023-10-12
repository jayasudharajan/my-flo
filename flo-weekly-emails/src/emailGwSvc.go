package main

import (
	"fmt"
	"net/url"
	"strings"
	"time"
)

const (
	ENVVAR_MAIL_GW_URI = "FLO_MAIL_GW_URI"
	ENVVAR_MAIL_GW_JWT = "FLO_MAIL_GW_JWT"
)

type emailGwSvc struct {
	uri       string
	http      *httpUtil
	validator *Validator
	log       *Logger
}

func CreateEmailGwSvc(validator *Validator, log *Logger) *emailGwSvc {
	m := emailGwSvc{
		validator: validator,
		uri:       getEnvOrDefault(ENVVAR_MAIL_GW_URI, ""),
		log:       log.CloneAsChild("Relay"),
	}
	if strings.Index(m.uri, "http") != 0 {
		m.log.Fatal("CreateEmailGwSvc: missing or invalid %v | %v", ENVVAR_MAIL_GW_URI, m.uri)
		return nil
	}
	m.http = CreateHttpUtil(getEnvOrDefault(ENVVAR_MAIL_GW_JWT, ""), m.log, 0)
	return &m
}

type QueueResp struct {
	Id string `json:"id,omitempty"`
}

type EmailMessage struct {
	ClientAppName string            `json:"client_app_name" validate:"required,min=1,max=64"`
	TimeStamp     time.Time         `json:"time_stamp" validate:"omitempty"`
	EmailMetaData map[string]string `json:"email_meta_data" validate:"omitempty"`
	Recipients    []*Recipient      `json:"recipients" validate:"required,min=1,max=100,dive,required"`
	Id            string            `json:"id" validate:"omitempty,min=32,max=36,uuid_rfc4122|hexadecimal"`
	WebHook       string            `json:"web_hook" validate:"omitempty,max=1024,url"`
}

type Recipient struct {
	Name         string         `json:"name" validate:"omitempty,min=1,max=128"`
	EmailAddress string         `json:"email_address" validate:"omitempty,max=128,email"`
	Data         *RecipientData `json:"data" validate:"omitempty,dive"`
}
type RecipientData struct {
	TemplateId        string        `json:"template_id" validate:"required,min=1,max=128"`
	EspAccount        string        `json:"esp_account" validate:"omitempty,min=1,max=1024"`
	EmailTemplateData *TemplateData `json:"email_template_data" validate:"omitempty,dive"`
}
type TemplateData struct {
	Data map[string]interface{} `json:"data" validate:"omitempty"`
}

func (m *emailGwSvc) Queue(msg *EmailMessage) (*QueueResp, error) {
	started := time.Now()
	m.log.PushScope("mailQ", msg.Id)
	defer m.log.PopScope()

	res := QueueResp{}
	if e := m.validator.Struct(msg); e != nil {
		return nil, m.log.IfWarnF(e, "validate msg failed")
	} else if e := m.http.Do("POST", m.uri+"/queue", msg, nil, &res); e != nil {
		return nil, e
	} else {
		m.log.Trace("%vms %v | %v", time.Since(started).Milliseconds(), msg.EmailMetaData, res)
		return &res, nil
	}
}

type UnSubTypeResp struct {
	UnSubscribed []string `json:"unSubscribed,omitempty"`
	Allowed      []string `json:"allowed,omitempty"`
}

//map returned with key=email, value=true if unSubscribed & false if not, missing email in db will not be in returned map
func (m *emailGwSvc) IsUnsubscribed(emails []string) (map[string]bool, error) {
	m.log.PushScope("UnSub?")
	defer m.log.PopScope()

	uri := fmt.Sprintf("%v/unsubscribe/email-type/1?emailsCsv=%v", m.uri, url.QueryEscape(strings.Join(emails, ",")))
	unSubs := UnSubTypeResp{}
	if e := m.http.Do("GET", uri, nil, nil, &unSubs); e != nil {
		return nil, e
	}
	res := make(map[string]bool)
	for _, s := range unSubs.Allowed {
		res[strings.ToLower(s)] = false
	}
	for _, u := range unSubs.UnSubscribed {
		res[strings.ToLower(u)] = true
	}
	return res, nil
}

func (m *emailGwSvc) Ping() error {
	e := m.http.Do("GET", m.uri+"/ping?log=true", nil, nil, nil)
	return m.log.IfWarnF(e, "Ping")
}
