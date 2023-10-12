package main

import (
	"context"
	"fmt"
	"strings"

	"github.com/pkg/errors"
)

// PublicGateway TODO: migrate the other entities like User & Account here
type PublicGateway interface {
	PingV1(ctx context.Context) error
	PingV2(ctx context.Context) error

	GetDevice(c *deviceCriteria) (*Device, error)
	UserLocations(userId, jwt string) ([]*Location, error)
	Location(locationId, jwt string) (*Location, error)
	SetDeviceValve(deviceId, jwt string, v *Valve) error
	GetIncidents(deviceId, jwt string) ([]*Incident, error)
	GetUserFromToken(accessToken string) (*User, error)
	LogoutFromToken(jwt string) error
	OAuth2(req *OAuthRequest) (*OAuthResponse, error)

	GetSerial(mac string) (*SerialInfo, error)

	//TODO: migrate update device fw from device_control.go 137
}

type publicGateway struct {
	apiV1      string
	apiV2      string //domain only, no path
	jwt        string //client token
	htu        *httpUtil
	fakeBroken BrokenValves
	admin      *adminCredential
}

func CreatePublicGateway(
	apiV1, apiV2, jwt string, htu *httpUtil, broken BrokenValves, admin *adminCredential) PublicGateway {

	if strings.Index(apiV1, "http") != 0 {
		apiV1 = apiV2
	}
	return &publicGateway{apiV1, apiV2, jwt, htu, broken, admin}
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
	Date PubGwTime `json:"date,omitempty"`
	App  string    `json:"app"`
	Env  string    `json:"env,omitempty"`
}

func (p gwPingResp) String() string {
	return tryToJson(p)
}

func (p *publicGateway) ping(url string) error {
	res := gwPingResp{}
	if e := p.htu.Do("GET", url, nil, nil, &res); e != nil {
		return e
	} else if res.App == "" {
		return errors.Errorf("ping: GET %s -> %v", url, res)
	} else {
		return nil
	}
}

func (p *publicGateway) PingV1(ctx context.Context) error {
	url := fmt.Sprintf("%s/api/v1/ping", p.apiV1)
	return p.ping(url)
}

func (p *publicGateway) PingV2(ctx context.Context) error {
	url := fmt.Sprintf("%s/api/v2/ping", p.apiV2)
	return p.ping(url)
}

func (p *publicGateway) GetDevice(c *deviceCriteria) (*Device, error) {
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
	return p.augmentValve(&device), nil
}

func (p *publicGateway) augmentValve(device *Device) *Device {
	if device != nil && device.Valve != nil {
		if p.fakeBroken.IsAny(device.Id, device.MacAddress) {
			device.Valve.LastKnown = "broken"
		}
	}
	return device
}

const JWT_MIN_LEN = 8

func (p *publicGateway) UserLocations(userId, jwt string) ([]*Location, error) {
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
				devices = append(devices, p.augmentValve(d))
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

func (p *publicGateway) Location(locationId, jwt string) (*Location, error) {
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
			devices = append(devices, p.augmentValve(d)) //replace device with fake valve states potentially
		}
		loc.Devices = devices
		return &loc, nil
	}
}

func (p *publicGateway) SetDeviceValve(deviceId, jwt string, v *Valve) error {
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

func (p *publicGateway) GetIncidents(deviceId, jwt string) ([]*Incident, error) {
	if len(jwt) < JWT_MIN_LEN {
		jwt = p.jwt
	}
	var (
		url  = fmt.Sprintf("%s/api/v2/incidents?deviceId=%s&severity=warning&severity=critical&status=triggered", p.apiV2, deviceId)
		res  = incidentResp{}
		auth = StringPairs{AUTH_HEADER, jwt}
	)
	if e := p.htu.Do("GET", url, nil, nil, &res, auth); e != nil {
		return nil, e
	} else {
		return res.Items, nil
	}
}

func (p *publicGateway) GetUserFromToken(jwt string) (*User, error) {
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

func (p *publicGateway) LogoutFromToken(jwt string) error {
	var (
		uri  = fmt.Sprintf("%s/api/v2/session/logout", p.apiV2)
		auth = StringPairs{AUTH_HEADER, jwt}
	)
	return p.htu.Do("POST", uri, nil, nil, nil, auth)
}

func (p *publicGateway) OAuth2(req *OAuthRequest) (*OAuthResponse, error) {
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

type SerialInfo struct {
	Product   string `json:"product,omitempty"`
	PCBA      string `json:"pcba,omitempty"`
	Year      int32  `json:"year,omitempty"`
	Mac       string `json:"device_id,omitempty"`
	DayOfYear int32  `json:"day_of_year,omitempty"`
	Site      string `json:"site,omitempty"`
	Serial    string `json:"sn,omitempty"`
	Valve     string `json:"valve,omitempty"`
}

type serialResp struct {
	Items []*SerialInfo `json:"items,omitempty"`
}

func (p *publicGateway) GetSerial(mac string) (*SerialInfo, error) {
	var tk StringPairs
	if jwt, e := p.admin.GetToken(p.apiV1, p.htu); e != nil {
		return nil, e
	} else if jwt.Token == "" {
		return nil, errors.New("can't fetch admin token")
	} else {
		tk = StringPairs{AUTH_HEADER, jwt.Token}
	}

	var (
		url  = fmt.Sprintf("%v/api/v1/stockicds/sn?device_id=%v", p.apiV1, mac)
		resp = serialResp{}
	)
	if e := p.htu.Do("GET", url, nil, nil, &resp, tk); e != nil {
		return nil, e
	} else if len(resp.Items) != 0 {
		return resp.Items[0], nil
	} else {
		return nil, nil
	}
}
