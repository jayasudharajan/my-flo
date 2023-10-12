package main

import (
	"encoding/base64"
	"fmt"
	"math"
	"regexp"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"
)

type SyncState int32

const (
	SYNC_UNKNOWN    = 0   //default system state
	SYNC_EXISTS     = 200 //synced
	SYNC_MISSING    = 404 //email not found on Flo DB
	SYNC_INCOMPLETE = 409 //email matches on both side but not synced
	SYNC_ERROR      = 500
)

type AccountState struct {
	User  *FloUser
	State SyncState
}

type FloEntity struct {
	Id string `json:"id"`
}

func (fe FloEntity) String() string {
	return fmt.Sprintf("{id:%v}", fe.Id)
}

type FloUser struct {
	Id        string         `json:"id"`
	Email     string         `json:"email"`
	Phone     string         `json:"phoneMobile,omitempty"`
	FirstName string         `json:"firstName"`
	LastName  string         `json:"lastName"`
	IsActive  bool           `json:"isActive"`
	Account   *FloEntity     `json:"account,omitempty"`
	Locations []*FloLocation `json:"locations,omitempty"`
	Devices   []*FloDevice   `json:"devices,omitempty"`
}

func (fu *FloUser) AccountId() string {
	if fu == nil || fu.Account == nil {
		return ""
	}
	return fu.Account.Id
}

type FloLocation struct {
	Id       string       `json:"id"`
	Name     string       `json:"nickname,omitempty"`
	Address  string       `json:"address,omitempty"`
	Address2 string       `json:"address2,omitempty"`
	City     string       `json:"city,omitempty"`
	State    string       `json:"state,omitempty"`
	PostCode string       `json:"postalCode,omitempty"`
	Country  string       `json:"country,omitempty"`
	Timezone string       `json:"timezone,omitempty"`
	Devices  []*FloDevice `json:"devices,omitempty"`
	Account  *FloEntity   `json:"account,omitempty"`
}

func (fl *FloLocation) AccountId() string {
	if fl == nil || fl.Account == nil {
		return ""
	}
	return fl.Account.Id
}

type FloDevice struct {
	Id      string `json:"id"`
	MacAddr string `json:"macAddress"`
	Name    string `json:"nickname,omitempty"`
	Type    string `json:"deviceType,omitempty"`
	Model   string `json:"deviceModel,omitempty"`
	//Mode string `json:"systemMode"`
	//State string `json:"valveState"`
	//IsPaired bool `json:"isPaired"`
	//IsConnected bool `json:"isConnected"`
	Location *FloEntity `json:"location,omitempty"`
}

func (fd *FloDevice) LocationId() string {
	if fd == nil || fd.Location == nil {
		return ""
	}
	return fd.Location.Id
}

type FloRegistration struct {
	Email     string `json:"email" validate:"required,email,max=512"`
	FirstName string `json:"firstName" validate:"required,min=1"`
	LastName  string `json:"lastName" validate:"required,min=1"`
	Password  string `json:"password" validate:"required,min=8,max=256"`
	Phone     string `json:"phone" validate:"omitempty,e164"`
	Locale    string `json:"locale" validate:"omitempty,len=5"` //localization: US-en, CA-fr
	Country   string `json:"country" validate:"required,len=2,alpha"`
	SkipCheck bool   `json:"skipEmailSend,omitempty" validate:"omitempty"`
}

func (r *FloRegistration) SetRandomPassword() *FloRegistration {
	if r.Password == "" {
		var (
			hash, _ = mh3(r)
			buf     = []rune(strings.ReplaceAll(uuid.New().String()+hash, "-", ""))
			n       = int(math.Max(float64(time.Now().Unix()/7), 3))
		)
		if n%2 == 0 {
			buf[0] = unicode.ToUpper(buf[0])
		}
		for i, c := range buf {
			if i%n == 0 {
				buf[i] = unicode.ToUpper(c) //randomly upper case
			}
		}
		r.Password = base64.StdEncoding.EncodeToString([]byte(string(buf))) //shorten pwd
	}
	return r
}

var _numOnlyRe = regexp.MustCompile(`[\+0-9]+`)

func (r *FloRegistration) Normalize() *FloRegistration {
	r.Email = strings.ToLower(r.Email)
	if r.Phone != "" {
		r.Phone = strings.Join(_numOnlyRe.FindAllString(r.Phone, -1), "")
		if pl := len(r.Phone); pl >= 5 && r.Phone[0] != '+' {
			r.Phone = "+" + r.Phone
		}
	}
	if r.Country == "" {
		r.Country = "US"
	} else {
		r.Country = strings.ToUpper(r.Country)
	}
	return r
}

func (r FloRegistration) String() string {
	return fmt.Sprintf("%s %s <%s>", r.FirstName, r.LastName, r.Email)
}

type RegistrationResult struct {
	User  *FloUser  `json:"user"`
	Token *FloToken `json:"token"`
}

type EntityEventEnvelope struct {
	Date   PubGwTime   `json:"date"`
	Type   string      `json:"type"`
	Action string      `json:"action"`
	Item   interface{} `json:"item"`
}

func (ev EntityEventEnvelope) String() string {
	return tryToJson(ev)
}

type LinkEvent struct {
	User     interface{}    `json:"user,omitempty"`
	Location interface{}    `json:"location,omitempty"`
	External ExternalEntity `json:"external"`
}

type ExternalEntity struct {
	Vendor string      `json:"vendor"`
	Type   string      `json:"type"`
	Id     string      `json:"id"`
	Entity interface{} `json:"entity,omitempty"`
}

type SyncLookup struct {
	MoenId string `json:"moenId" schema:"moenId" url:"moenId" validate:"omitempty,uuid4_rfc4122"`
	FloId  string `json:"floId" schema:"floId" url:"floId" validate:"omitempty,uuid4_rfc4122"`
	Issuer string `json:"issuer" schema:"issuer" url:"issuer" validate:"omitempty,min=3,max=256"`
}

type SyncDataRes struct {
	MoenId    string `json:"moenId"`
	FloId     string `json:"floId"`
	Issuer    string `json:"issuer"`
	MoenAccId string `json:"moenAccountId,omitempty"`
	FloAccId  string `json:"floAccountId,omitempty"`
}
