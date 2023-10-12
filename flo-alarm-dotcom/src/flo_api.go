package main

import (
	"fmt"
	url2 "net/url"
	"strings"
	"time"

	"github.com/google/go-querystring/query"
	"github.com/pkg/errors"
)

// FloAPI TODO: migrate the other entities like User & Account here
type FloAPI interface {
	PingV1() error
	PingV2() error
	AdminToken() (*AdminToken, error)

	GetDevice(c *deviceCriteria) (*Device, error)
	UserLocations(userId, jwt string) ([]*Location, error)
	Location(locationId, jwt string) (*Location, error)
	SetDeviceValve(deviceId, jwt string, v *Valve) error
	GetIncidents(deviceId, jwt string, criticalOnly bool) ([]*Incident, error)
	GetUserFromToken(accessToken string) (*User, error)
	LogoutFromToken(jwt string) error

	OAuth2Token(req *OAuthRequest) (*OAuthResponse, error)
	OAuth2AuthorizeCode(req *OAuthCodeReq) (*OAuthCodeResp, error)

	GetAlarms() ([]*Alarm, error)
	AlertAction(ack *alertAck, accessToken string) error
}

type floAPI struct {
	apiV1 string
	apiV2 string //domain only, no path
	jwt   string //client token
	htu   HttpUtil
	admin AdminCredential
}

func CreateFloAPI(
	apiV1, apiV2, jwt string, htu HttpUtil, admin AdminCredential) FloAPI {

	if strings.Index(apiV1, "http") != 0 {
		apiV1 = apiV2
	}
	return &floAPI{apiV1, apiV2, jwt, htu, admin}
}

type deviceCriteria struct {
	Mac       string //mac address
	Id        string //device id
	ExpandLoc bool   //expand location info
	Jwt       string //optional token to use
}

func (c *deviceCriteria) Validate() error {
	if c == nil {
		return errors.New("Criteria is missing")
	} else if ml, dl := len(c.Mac), len(c.Id); ml == 0 && dl == 0 {
		return errors.New("Mac or Id is required")
	} else if ml > 0 && ml != 12 {
		return errors.New("Invalid Mac")
	} else if dl > 0 && dl != 36 {
		return errors.New("Invalid Id")
	} else {
		return nil
	}
}

func (c *deviceCriteria) GetUri(root string) (string, error) {
	if root == "" {
		return "", errors.New("Root path is required")
	} else if e := c.Validate(); e != nil {
		return "", e
	}

	var path string
	if c.Mac != "" {
		path = fmt.Sprintf("%s/api/v2/devices?macAddress=%s", root, c.Mac)
	} else {
		path = fmt.Sprintf("%s/api/v2/devices/%s", root, c.Id)
	}
	if c.ExpandLoc {
		if strings.Contains(path, "?") {
			path += "&"
		} else {
			path += "?"
		}
		path += "expand=location"
	}
	return path, nil
}

type gwPingResp struct {
	Date DateTime `json:"date,omitempty"`
	App  string   `json:"app"`
	Env  string   `json:"env,omitempty"`
}

func (p gwPingResp) String() string {
	return tryToJson(p)
}

func (p *floAPI) AdminToken() (*AdminToken, error) {
	tk, e := p.admin.GetToken(p.apiV1, p.htu)
	return &tk, e
}

func (p *floAPI) ping(url string) error {
	//if _log.isDebug { //NOTE: to use this, run another instance of this svc on port 9999 & uncomment locally
	//	return p.Test502()
	//}
	res := gwPingResp{}
	if e := p.htu.Do("GET", url, nil, nil, &res); e != nil {
		return e
	} else if res.App == "" {
		return errors.Errorf("ping: GET %s -> %v", url, res)
	} else {
		return nil
	}
}

func (p *floAPI) Test502() error {
	req := map[string]interface{}{
		"code":    502,
		"message": "bad connection",
	}
	return p.htu.Do("POST", "http://localhost:9999/throw", req, nil, nil)
}

func (p *floAPI) PingV1() error {
	url := fmt.Sprintf("%s/api/v1/ping", p.apiV1)
	return p.ping(url)
}

func (p *floAPI) PingV2() error {
	url := fmt.Sprintf("%s/api/v2/ping", p.apiV2)
	return p.ping(url)
}

func (p *floAPI) GetDevice(c *deviceCriteria) (*Device, error) {
	var (
		device   Device
		uri, err = c.GetUri(p.apiV2)
		auth     = StringPairs{AUTH_HEADER, c.Jwt}
	)
	if auth.Value == "" {
		auth.Value = p.jwt
	}
	if err = p.htu.Do("GET", uri, nil, nil, &device, auth); err != nil {
		return nil, err
	}
	return &device, nil
}

const JWT_MIN_LEN = 16

func (p *floAPI) UserLocations(userId, jwt string) ([]*Location, error) {
	if len(jwt) < JWT_MIN_LEN {
		jwt = p.jwt
	}
	var (
		all          = make([]*Location, 0)
		fetched      = -1
		total        = 0
		page         = 1
		hasMoreItems = true
		auth         = StringPairs{AUTH_HEADER, jwt}
	)

	for fetched < total && hasMoreItems {
		var (
			res Locations
			uri = fmt.Sprintf("%s/api/v2/locations?userId=%s&class=unit&expand=devices&page=%v", p.apiV2, userId, page)
			err = p.htu.Do("GET", uri, nil, nil, &res, auth)
		)
		if err != nil {
			return nil, err
		}

		for _, l := range res.Items {
			devices := make([]*Device, 0, len(l.Devices))
			for _, d := range l.Devices {
				devices = append(devices, d)
			}
			l.Devices = devices
			all = append(all, l)
		}
		total = res.Total
		fetched += len(res.Items)
		hasMoreItems = len(res.Items) > 0
		page++
	}
	return all, nil
}

func (p *floAPI) Location(locationId, jwt string) (*Location, error) {
	if len(jwt) < JWT_MIN_LEN {
		jwt = p.jwt
	}
	var (
		loc  Location
		uri  = fmt.Sprintf("%s/api/v2/locations/%s?expand=devices", p.apiV2, locationId)
		auth = StringPairs{AUTH_HEADER, jwt}
	)
	//it's not likely that a location will contain hundreds of devices, if it does,
	//we need to copy pagination logic above somehow
	if e := p.htu.Do("GET", uri, nil, nil, &loc, auth); e != nil {
		return nil, e
	} else {
		devices := make([]*Device, 0, len(loc.Devices))
		for _, d := range loc.Devices {
			devices = append(devices, d) //replace device with fake valve states potentially
		}
		loc.Devices = devices
		return &loc, nil
	}
}

func (p *floAPI) SetDeviceValve(deviceId, jwt string, v *Valve) error {
	if len(jwt) < JWT_MIN_LEN {
		jwt = p.jwt
	}
	var (
		uri  = fmt.Sprintf("%v/api/v2/devices/%v", p.apiV2, deviceId) //fw-properties
		auth = StringPairs{AUTH_HEADER, jwt}
		d    = Device{Valve: v}
	)
	return p.htu.Do("POST", uri, &d, nil, nil, auth)
}

func (p *floAPI) GetIncidents(deviceId, jwt string, criticalOnly bool) ([]*Incident, error) {
	if len(jwt) < JWT_MIN_LEN {
		jwt = p.jwt
	}
	var (
		url  = fmt.Sprintf("%s/api/v2/incidents?deviceId=%s&status=triggered&severity=critical", p.apiV2, deviceId)
		res  = incidentResp{}
		auth = StringPairs{AUTH_HEADER, jwt}
	)
	if !criticalOnly {
		url += "&severity=warning"
	}
	if e := p.htu.Do("GET", url, nil, nil, &res, auth); e != nil {
		return nil, e
	} else {
		return res.Items, nil
	}
}

func (p *floAPI) GetUserFromToken(jwt string) (*User, error) {
	var (
		user User
		uri  = fmt.Sprintf("%s/api/v2/users/me", p.apiV2)
		auth = StringPairs{AUTH_HEADER, jwt}
		err  = p.htu.Do("GET", uri, nil, nil, &user, auth)
	)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (p *floAPI) LogoutFromToken(jwt string) error {
	var (
		uri  = fmt.Sprintf("%s/api/v2/session/logout", p.apiV2)
		auth = StringPairs{AUTH_HEADER, jwt}
	)
	return p.htu.Do("POST", uri, nil, nil, nil, auth)
}

// OAuthRequest generic model for multiple usage
type OAuthRequest struct {
	ClientId     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
	GrantType    string `json:"grant_type"`
	RefreshToken string `json:"refresh_token,omitempty"`
	Code         string `json:"code,omitempty"`
	RedirectUri  string `json:"redirect_uri,omitempty"`
	State        string `json:"state,omitempty"`
}

// OAuthResponse generic model for multiple usage
type OAuthResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
	IssuedAt     int    `json:"issued_at,omitempty"`
	TokenType    string `json:"token_type"`
	UserId       string `json:"user_id"`
	ClientId     string `json:"client_id,omitempty"`
}

func (o2 *OAuthResponse) IatDt() time.Time {
	if o2 == nil || o2.IssuedAt == 0 {
		return time.Time{}
	}
	return time.Unix(int64(o2.IssuedAt), 0).UTC()
}

func (o2 *OAuthResponse) ExpDt() time.Time {
	if iat := o2.IatDt(); iat.Year() > 0 {
		return iat.Add(time.Duration(o2.ExpiresIn) * time.Second).UTC()
	} else {
		return time.Time{}
	}
}

func (p *floAPI) OAuth2Token(req *OAuthRequest) (*OAuthResponse, error) {
	var (
		res OAuthResponse
		uri = fmt.Sprintf("%s/api/v1/oauth2/token", p.apiV1)
	)
	if err := p.htu.Do("POST", uri, req, nil, &res); err != nil {
		return nil, err
	} else {
		return &res, nil
	}
}

type OAuthCodeReq struct {
	AccessToken string `json:"-" url:"-"`
	ClientId    string `json:"client_id" url:"client_id"`
	RedirectUrl string `json:"redirect_uri" url:"redirect_uri"`
	RespType    string `json:"response_type" url:"response_type"` //should be 'code'
	State       string `json:"state,omitempty" url:"state,omitempty"`
}

func (oa *OAuthCodeReq) Normalize() *OAuthCodeReq {
	if oa != nil {
		if oa.RespType == "" {
			oa.RespType = "code"
		}
		if oa.ClientId == "" {
			oa.ClientId = getEnvOrExit("FLO_CLIENT_ID")
		}
	}
	return oa
}

func (oa *OAuthCodeReq) Validate() error {
	if oa == nil {
		return errors.New("nil reference")
	} else if oa.ClientId == "" {
		return errors.New("invalid client_id")
	} else if strings.Index(oa.RedirectUrl, "http") != 0 {
		return errors.New("invalid redirect_url")
	} else if oa.RespType == "" {
		return errors.New("missing response_type")
	} else if len(oa.AccessToken) < 12 || strings.Count(oa.AccessToken, ".") != 2 {
		return errors.New("invalid access_token")
	} else {
		return nil
	}
}

func (oa *OAuthCodeReq) PathAndQuery() (url string, e error) {
	if oa == nil {
		e = errors.New("nil binding")
		return
	}
	var params url2.Values
	if params, e = query.Values(oa); e == nil {
		url = fmt.Sprintf("/api/v1/oauth2/authorize?%v", params.Encode())
	}
	return
}

type OAuthCodeResp struct {
	Code        string `json:"code,omitempty"`
	State       string `json:"state,omitempty"`
	RedirectUrl string `json:"redirect_uri"`
}

func (ar *OAuthCodeResp) ParseCode() (*OAuthCodeResp, error) {
	var e error
	if ar == nil {
		e = errors.New("nil binding")
	} else if ar.RedirectUrl == "" {
		e = errors.New("redirect_url is empty")
	} else {
		var u *url2.URL
		if u, e = url2.Parse(ar.RedirectUrl); e == nil {
			qm := u.Query()
			if err := qm.Get("error"); err != "" {
				e = errors.New(err)
			} else if ar.Code = qm.Get("code"); ar.Code == "" {
				e = errors.New("code is missing in redirect_url")
			}
			ar.State = qm.Get("state")
		}
	}
	return ar, e
}

type codeAcceptReq struct {
	Accept bool `json:"accept"`
}

func (p *floAPI) OAuth2AuthorizeCode(req *OAuthCodeReq) (*OAuthCodeResp, error) {
	var pathQuery string
	if e := req.Normalize().Validate(); e != nil {
		return nil, errors.Wrap(e, "OAuth2AuthorizeCode validation")
	} else if pathQuery, e = req.PathAndQuery(); e != nil {
		return nil, errors.Wrap(e, "OAuth2AuthorizeCode query param build")
	}

	var (
		auth = StringPairs{AUTH_HEADER, req.AccessToken}
		pay  = codeAcceptReq{true}
		res  = &OAuthCodeResp{}
	)
	if e := p.htu.Do("POST", p.apiV1+pathQuery, &pay, nil, res, auth); e != nil {
		return nil, errors.Wrap(e, "OAuth2AuthorizeCode post")
	} else if res, e = res.ParseCode(); e != nil {
		return nil, errors.Wrap(e, "OAuth2AuthorizeCode response")
	} else {
		return res, nil
	}
}

type alarmRes struct {
	Items []*Alarm `json:"items"`
}

func (p *floAPI) GetAlarms() ([]*Alarm, error) {
	tk, e := p.admin.GetToken(p.apiV2, p.htu)
	if e != nil {
		return nil, e
	}
	var (
		jwt = StringPairs{AUTH_HEADER, tk.Token}
		url = fmt.Sprintf("%s/api/v2/alarms", p.apiV2)
		res = alarmRes{Items: make([]*Alarm, 0)}
	)
	if e = p.htu.Do("GET", url, nil, nil, &res, jwt); e != nil {
		return nil, e
	} else {
		return res.Items, nil
	}
}

type alertAck struct {
	DeviceId  string  `json:"deviceId"`
	AlarmIds  []int32 `json:"alarmIds"`
	SnoozeSec int32   `json:"snoozeSeconds"`
}

func (p *floAPI) AlertAction(ackIn *alertAck, jwt string) error {
	if ackIn == nil {
		return errors.New("ack is nil")
	} else if len(ackIn.AlarmIds) == 0 {
		return errors.New("ack.AlarmIds is empty")
	}

	if jwt == "" {
		if tk, e := p.admin.GetToken(p.apiV2, p.htu); e != nil {
			return e
		} else {
			jwt = tk.Token
		}
	} else if strings.Index(jwt, "Bearer") != 0 {
		jwt = "Bearer " + jwt
	}

	var (
		auth  = StringPairs{AUTH_HEADER, jwt}
		url   = fmt.Sprintf("%s/api/v2/alerts/action", p.apiV2)
		idMap = make(map[int32]bool)
		ack   = alertAck{
			ackIn.DeviceId,
			make([]int32, 0, len(ackIn.AlarmIds)),
			ackIn.SnoozeSec,
		}
	)
	for _, id := range ackIn.AlarmIds {
		idMap[id] = true //ensure unique
	}
	for id := range idMap {
		ack.AlarmIds = append(ack.AlarmIds, id)
	}
	if e := p.htu.Do("POST", url, &ack, nil, nil, auth); e != nil {
		return e
	}
	return nil
}
