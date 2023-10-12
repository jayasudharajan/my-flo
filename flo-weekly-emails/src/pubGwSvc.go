package main

import (
	"errors"
	"fmt"
	"math/rand"
	"net/url"
	"strings"
	"time"

	"github.com/google/go-querystring/query"
)

type pubGwSvc struct {
	redis     *RedisConnection
	uri       string
	http      *httpUtil
	validator *Validator
	log       *Logger
	mockUsage bool
	skipAlert bool
}

const (
	ENVVAR_API_URL          = "FLO_API_URL"
	ENVVAR_API_JWT          = "FLO_API_JWT"
	ENVVAR_MOCK_WATER_USAGE = "FLO_MOCK_WATER_USAGE"
	ENVVAR_SKIP_ALERTS      = "FLO_SKIP_ALERTS"
)

func CreatePubGwSvc(redis *RedisConnection, validator *Validator, log *Logger) *pubGwSvc {
	l := log.CloneAsChild("pubGW")
	if jwt := getEnvOrDefault(ENVVAR_API_JWT, ""); len(jwt) < 16 {
		l.Fatal("CreatePubGwSvc: invalid %v", ENVVAR_API_JWT)
	} else if uri, e := url.Parse(getEnvOrDefault(ENVVAR_API_URL, "")); e != nil {
		l.IfFatalF(e, "CreatePubGwSvc: invalid %v", ENVVAR_API_URL)
	} else if !strings.Contains(uri.Scheme, "http") {
		l.IfFatalF(e, "CreatePubGwSvc: not http %v", ENVVAR_API_URL)
	} else {
		p := pubGwSvc{
			redis:     redis,
			uri:       uri.String(),
			log:       l,
			http:      CreateHttpUtil(jwt, l, 0),
			validator: validator,
			mockUsage: strings.EqualFold(getEnvOrDefault(ENVVAR_MOCK_WATER_USAGE, ""), "true"),
			skipAlert: strings.EqualFold(getEnvOrDefault(ENVVAR_SKIP_ALERTS, ""), "true"),
		}
		if p.mockUsage {
			p.log.Warn("%s=%v", ENVVAR_MOCK_WATER_USAGE, p.mockUsage)
		}
		if p.skipAlert {
			p.log.Notice("%s=%v", ENVVAR_SKIP_ALERTS, p.skipAlert)
		}
		return &p
	}
	return nil
}

// DeviceBase is the base device properties struct
type DeviceInfo struct {
	DeviceId        string                 `json:"id"`
	MacAddr         string                 `json:"macAddress"`
	NickName        string                 `json:"nickname,omitempty"`
	SerialNumber    string                 `json:"serialNumber,omitempty"`
	IsConnected     bool                   `json:"isConnected"`
	IsPaired        bool                   `json:"isPaired"`
	FwVersion       string                 `json:"fwVersion"`
	LastHeardFrom   time.Time              `json:"lastHeardFromTime"`
	FwProperties    map[string]interface{} `json:"fwProperties,omitempty"`
	Type            string                 `json:"deviceType,omitempty"`
	Model           string                 `json:"deviceModel,omitempty"`
	LocSummary      *IdResp                `json:"location,omitempty"`
	LatestFwInfo    *FirmwareInfo          `json:"latestFwInfo,omitempty"`
	ComponentHealth *ComponentHealth       `json:"componentHealth,omitempty"`
}

type FirmwareInfo struct {
	Version        string `json:"version,omitempty"`
	SourceType     string `json:"sourceType,omitempty"`
	SourceLocation string `json:"sourceLocation,omitempty"`
}

type ComponentHealth struct {
	Valve *ComponentInfo `json:"valve,omitempty"`
	Temp  *ComponentInfo `json:"temp,omitempty"`
	PSI   *ComponentInfo `json:"psi,omitempty"`
	Water *ComponentInfo `json:"water,omitempty"`
	RH    *ComponentInfo `json:"rh,omitempty"`
}

type ComponentInfo struct {
	Health  string    `json:"health"`
	Updated time.Time `json:"updated,omitempty"`
}

func (p *pubGwSvc) GetDeviceInfo(macAddr string) (*DeviceInfo, error) {
	started := time.Now()
	p.log.PushScope("Dev", macAddr)
	defer p.log.PopScope()

	if e := p.validator.Value(macAddr, "required,len=12,hexadecimal"); e != nil {
		return nil, p.log.IfWarnF(e, "macAddr validation failed %v", macAddr)
	}
	url := fmt.Sprintf("%v/api/v2/devices?macAddress=%v", p.uri, url.QueryEscape(macAddr))
	res := DeviceInfo{}
	if e := p.http.Do("GET", url, nil, nil, &res); e != nil {
		return nil, e
	} else {
		locId := ""
		if res.LocSummary != nil {
			locId = res.LocSummary.Id
		}
		p.logDebugIfSlow(started, "%vms => did=%v loc=%v", time.Since(started).Milliseconds(), res.DeviceId, locId)
		return &res, nil
	}
}

type LocResp struct {
	Id                string            `json:"id,omitempty"`
	Users             []*UserSummary    `json:"users,omitempty"`
	Devices           []*DeviceResp     `json:"devices,omitempty"`
	Subscription      *SubscriptionResp `json:"subscription,omitempty"`
	Street            string            `json:"address,omitempty"`
	City              string            `json:"city,omitempty"`
	Region            string            `json:"state,omitempty"`
	Country           string            `json:"country,omitempty"`
	PostCode          string            `json:"postalCode,omitempty"`
	TimeZone          string            `json:"timezone,omitempty"`
	GallonsPerDayGoal float32           `json:"gallonsPerDayGoal,omitempty"`
	Occupants         int32             `json:"occupants,omitempty"`
	Stories           int32             `json:"stories,omitempty"`
	ProfileCompleted  bool              `json:"isProfileComplete,omitempty"`
	NickName          string            `json:"nickname,omitempty"`
	LocationType      string            `json:"locationType,omitempty"`
	Account           *AccountInfo      `json:"account,omitempty"`
}

type AccountInfo struct {
	Id    string  `json:"id,omitempty"`
	Owner *IdResp `json:"owner,omitempty"`
	Type  string  `json:"type,omitempty"`
}

func (l *LocResp) IsMultiUnit() bool {
	if l != nil && l.Account != nil && !(l.Account.Type == "" || strings.EqualFold(l.Account.Type, "personal")) {
		return true
	}
	return false
}

func (l *LocResp) ToLocInfo() *locInfo {
	r := locInfo{
		LocId: l.Id,
		Users: make([]*userInfo, len(l.Users)),
	}
	for i, u := range l.Users {
		r.Users[i] = &userInfo{
			UserId: u.Id,
			Email:  u.Email,
			Name:   u.Name(),
		}
	}
	return &r
}

func (l *LocResp) HasUser(userId string) bool {
	if userId != "" {
		for _, u := range l.Users {
			if strings.EqualFold(u.Id, userId) {
				return true
			}
		}
	}
	return false
}

type UserSummary struct {
	Id          string      `json:"id,omitempty"`
	Email       string      `json:"email,omitempty"`
	FirstName   string      `json:"firstName,omitempty"`
	LastName    string      `json:"lastName,omitempty"`
	UnitSystem  string      `json:"unitSystem,omitempty"`
	PhoneMobile string      `json:"phoneMobile,omitempty"`
	Locale      string      `json:"locale,omitempty"`
	AccountRole AccRoleResp `json:"accountRole,omitempty"`
	Locations   []*IdResp   `json:"locations,omitempty"`
}

func (u *UserSummary) Name() string {
	return fmt.Sprintf("%v %v", u.FirstName, u.LastName)
}

type AccRoleResp struct {
	AccountId string   `json:"accountId,omitempty"`
	Roles     []string `json:"roles,omitempty"`
}
type DeviceResp struct {
	IsConnected    bool              `json:"isConnected"`
	FirmwareVer    string            `json:"fwVersion"`
	LastPing       time.Time         `json:"lastHeardFromTime"`
	Id             string            `json:"id,omitempty"`
	MacAddr        string            `json:"macAddress,omitempty"`
	NickName       string            `json:"nickname"`
	IsPaired       bool              `json:"isPaired"`
	DeviceModel    string            `json:"deviceModel"`
	DeviceType     string            `json:"deviceType"`
	InstallStatus  DeviceInstallResp `json:"installStatus"`
	IrrigationType string            `json:"irrigationType"`
	SerialNumber   string            `json:"serialNumber"`
}
type DeviceInstallResp struct {
	IsInstalled bool      `json:"isInstalled"`
	InstallDate time.Time `json:"installDate"`
}
type IdResp struct {
	Id string `json:"id,omitempty"`
}
type SubscriptionResp struct {
	Id       string                 `json:"id,omitempty"`
	Active   bool                   `json:"isActive,omitempty"`
	Status   string                 `json:"status,omitempty"`
	Provider map[string]interface{} `json:"providerInfo,omitempty"`
}

// real data
func (p *pubGwSvc) GetLoc(locId string) (*LocResp, error) {
	started := time.Now()
	p.log.PushScope("Loc", locId)
	defer p.log.PopScope()

	if e := p.validator.Value(locId, "required,min=32,max=36,uuid_rfc4122|hexadecimal"); e != nil {
		return nil, p.log.IfWarnF(e, "locId validation failed")
	} else {
		url := fmt.Sprintf("%v/api/v2/locations/%v?expand=users,devices,account", p.uri, locId)
		loc := LocResp{}
		if e := p.http.Do("GET", url, nil, nil, &loc); e != nil {
			return nil, e
		} else {
			for _, d := range loc.Devices {
				if d.LastPing.Year() > 2000 {
					d.LastPing = d.LastPing.UTC()
				}
			}
			p.log.Debug("%vms => %v %v users", time.Since(started).Milliseconds(), loc.Id, len(loc.Users))
			return &loc, nil
		}
	}
}

func (p *pubGwSvc) GetLocViaCache(locId string) (*LocResp, error) {
	started := time.Now()
	p.log.PushScope("$L")
	defer p.log.PopScope()

	if key, e := p.locCacheKey(locId); e != nil {
		return nil, e
	} else {
		if str, e := p.redis.Get(key); e == nil || e.Error() == "redis: nil" {
			if len(str) > 4 {
				res := LocResp{}
				if e = jsonUnMarshalGz([]byte(str), &res); e != nil {
					p.log.IfErrorF(e, "Unable to deserialize JSON.GZ | %v", str)
				} else {
					p.log.Debug("HIT %vms %v %v users", time.Since(started).Milliseconds(), res.Id, len(res.Users))
					return &res, nil //return from cache
				}
			}
		} else {
			p.log.IfErrorF(e, "GetLocViaCache: failed for key=%v loc=%v", key, locId)
		}
		res, e := p.GetLoc(locId)   //fetch from src
		if e == nil && res != nil { //set cache
			go p.storeLocCache(res)
		}
		return res, e //pass through response
	}
}

func (p *pubGwSvc) locCacheKey(locId string) (string, error) {
	shortId := strings.ToLower(strings.ReplaceAll(locId, "-", ""))
	if e := p.validator.Value(shortId, "required,len=32,hexadecimal"); e != nil {
		return "", p.log.IfWarnF(e, "locId validation failed: %v", shortId)
	} else {
		return fmt.Sprintf("email:pgw:loc:{%v}", shortId), nil
	}
}

func (p *pubGwSvc) storeLocCache(loc *LocResp) error {
	defer panicRecover(p.log, "storeLocCache: %v", loc.Id)
	p.log.PushScope("storeL$")
	defer p.log.PopScope()
	if loc == nil {
		return p.log.Warn("nil input")
	} else if key, e := p.locCacheKey(loc.Id); e != nil {
		return e
	} else if buf, e := jsonMarshalGz(loc); e != nil {
		return p.log.IfErrorF(e, "Can't serialize JSON.GZ | %v", loc)
	} else if _, e := p.redis.SetNX(key, buf, int((time.Hour * 2).Seconds())); e != nil { //2hr cache
		if e.Error() != "redis: nil" {
			return p.log.IfErrorF(e, "can't write: %v", key)
		}
	}
	return nil
}

// mock data
func (p *pubGwSvc) SearchUser(email string) ([]userInfo, error) {
	if email == "" {
		return nil, errors.New("email is blank")
	}

	if strings.Contains(email, "ambiguous") {
		userId, _, _ := newUuid()
		return []userInfo{
			{userId, email, userId + " name"},
			{userId, email, "ambiguous user"},
		}, nil
	}
	return []userInfo{}, nil
}

func (ur *UserSummary) ToLocInfos() []*locInfo {
	if ur == nil {
		return nil
	}
	ui := userInfo{
		UserId: ur.Id,
		Email:  ur.Email,
		Name:   ur.Name(),
	}
	arr := make([]*locInfo, len(ur.Locations))
	for i, l := range ur.Locations {
		arr[i] = &locInfo{
			LocId: l.Id,
			Users: []*userInfo{&ui},
		}
	}
	return arr
}

// real data
func (p *pubGwSvc) GetUser(userId string) (*UserSummary, error) {
	started := time.Now()
	p.log.PushScope("Usr", userId)
	defer p.log.PopScope()

	if e := p.validator.Value(userId, "required,min=32,max=36,uuid_rfc4122|hexadecimal"); e != nil {
		return nil, p.log.IfWarnF(e, "validate userId failed")
	}
	res := UserSummary{}
	url := fmt.Sprintf("%v/api/v2/users/%v", p.uri, userId)
	if e := p.http.Do("GET", url, nil, nil, &res); e != nil {
		return nil, e
	} else {
		p.log.Debug("%vms => %v %v loc_count=%v", time.Since(started).Milliseconds(), res.Name(), res.Email, len(res.Locations))
		return &res, nil
	}
}

type WaterUseReq struct {
	LocId     string `json:"locationId,omitempty" url:"locationId" validate:"required_without=macAddress,min=12,mac|hexadecimal"`
	MacAddr   string `json:"macAddress,omitempty" url:"macAddress" validate:"required_without=locationId,uuid_rfc4122"`
	StartDate string `json:"startDate,omitempty" url:"startDate" validate:"required,datetime=2016-01-02T15:04:05"`
	EndDate   string `json:"endDate,omitempty" url:"endDate" validate:"required,datetime=2016-01-02T15:04:05"`
	Interval  string `json:"interval,omitempty" url:"interval" validate:"required,oneof=1d 1hr"`
	TimeZone  string `json:"tz,omitempty" url:"tz" validate:"required,min=3"`
}

type WaterUseResp struct {
	Params WaterUseReq   `json:"params" validate:"required,dive"`
	Items  []*WaterUsage `json:"items" validate:"required,dive"`
}

type WaterUsage struct {
	Time    time.Time `json:"time" validate:"required,datetime"`
	Gallons float32   `json:"gallonsConsumed,omitempty" validate:"omitempty,min=0"`
}

func (p *pubGwSvc) MockWaterUse(w *WaterUsage) {
	rn := rand.Int31()
	if rn%3 == 0 {
		w.Gallons = float32(rand.Int31n(4000))
	}
}

// real data
func (p *pubGwSvc) GetWaterUsage(req *WaterUseReq) (*WaterUseResp, error) {
	started := time.Now()
	p.log.PushScope("H2oUse", req.MacAddr, req.StartDate, req.EndDate)
	defer p.log.PopScope()

	if ps, e := query.Values(req); e != nil {
		return nil, p.log.IfWarnF(e, "req param gen failed")
	} else {
		url := fmt.Sprintf("%v/api/v2/water/consumption?%v", p.uri, ps.Encode())
		resp := WaterUseResp{}
		if e = p.http.Do("GET", url, nil, nil, &resp); e != nil {
			return nil, e
		} else {
			if len(resp.Items) != 0 && resp.Params.TimeZone != "" {
				if tz, e := time.LoadLocation(resp.Params.TimeZone); e != nil {
					p.log.IfWarnF(e, "can't parse TZ %v", resp.Params.TimeZone)
				} else {
					for _, w := range resp.Items {
						w.Time = w.Time.In(tz)            //tz loc assignment
						if p.mockUsage && p.log.isDebug { //double ensure fake data is only local
							p.MockWaterUse(w)
						}
					}
				}
			}
			p.logDebugIfSlow(started, "%vms => %v %v items", time.Since(started).Milliseconds(), resp.Params.TimeZone, len(resp.Items))
			return &resp, nil
		}
	}
}

func (p *pubGwSvc) logDebugIfSlow(started time.Time, format string, args ...interface{}) string {
	ll := LL_TRACE
	if ms := time.Since(started).Milliseconds(); ms > 1000 {
		ll = LL_INFO
	} else if ms > 500 {
		ll = LL_DEBUG
	}
	return p.log.Log(ll, format, args...)
}

type WaterStatsReq struct {
	MacAddr   string `json:"macAddress,omitempty" url:"macAddress" validate:"required,min=12,mac|hexadecimal"`
	StartDate string `json:"startDate,omitempty" url:"startDate" validate:"required,datetime=2016-01-02T15:04:05"`
	EndDate   string `json:"endDate,omitempty" url:"endDate" validate:"required,datetime=2016-01-02T15:04:05"`
	Interval  string `json:"interval,omitempty" url:"interval" validate:"required,oneof=1d 1hr"`
	TimeZone  string `json:"tz,omitempty" url:"tz" validate:"required,min=3"`
}

type WaterStatsResp struct {
	Params WaterStatsReq `json:"params" validate:"required,dive"`
	Items  []*WaterStats `json:"items" validate:"required,dive"`
}

type WaterStats struct {
	Time    time.Time `json:"time" validate:"required,datetime"`
	GPM     *float32  `json:"averageGpm,omitempty" validate:"omitempty,min=0"`
	PSI     *float32  `json:"averagePsi,omitempty" validate:"omitempty,min=0"`
	Temp    *float32  `json:"averageTempF,omitempty" validate:"omitempty,min=0"`
	Ambient float32   `json:"averageWeatherTempF,omitempty" validate:"omitempty,min=0"`
}

func (ws WaterStats) IsEmpty() bool {
	return ws.PSI == nil && ws.Temp == nil && ws.GPM == nil
}

// real data
func (p *pubGwSvc) GetWaterStats(req *WaterStatsReq) (*WaterStatsResp, error) {
	started := time.Now()
	p.log.PushScope("H2oStats", req.MacAddr, req.StartDate, req.EndDate)
	defer p.log.PopScope()

	if ps, e := query.Values(req); e != nil {
		return nil, p.log.IfWarnF(e, "req param gen failed")
	} else {
		url := fmt.Sprintf("%v/api/v2/water/metrics?%v", p.uri, ps.Encode())
		resp := WaterStatsResp{}
		if e = p.http.Do("GET", url, nil, nil, &resp); e != nil {
			return nil, e
		} else {
			if len(resp.Items) != 0 && resp.Params.TimeZone != "" {
				if tz, e := time.LoadLocation(resp.Params.TimeZone); e != nil {
					p.log.IfWarnF(e, "can't parse TZ %v", resp.Params.TimeZone)
				} else {
					for _, w := range resp.Items {
						w.Time = w.Time.In(tz)            //tz loc assignment
						if p.mockUsage && p.log.isDebug { //double ensure fake data is only local
							p.MockWaterStats(w)
						}
					}
				}
			}
			p.logDebugIfSlow(started, "%vms => %v %v items", time.Since(started).Milliseconds(), resp.Params.TimeZone, len(resp.Items))
			return &resp, nil
		}
	}
}

func (p *pubGwSvc) MockWaterStats(w *WaterStats) {
	rn := rand.Int31()
	if coalesceFloat32(w.GPM) == 0 && rn%3 == 0 {
		w.GPM = pointToFloat32(float32(rand.Int31n(300)) / 100)
	}
	if coalesceFloat32(w.Temp) == 0 || coalesceFloat32(w.PSI) == 0 {
		w.Temp = pointToFloat32((200 + float32(rand.Int31n(1000))) / 100)
		w.PSI = pointToFloat32((400 + float32(rand.Int31n(700))) / 10)
	}
}

type AlertStatsResp struct {
	Pending *AlertsCount `json:"pending,omitempty"`
}

func (a *AlertStatsResp) PendingTotal() int32 {
	return a.Pending.Info + a.Pending.Warn + a.Pending.Critical
}

type AlertsCount struct {
	Info     int32           `json:"infoCount,omitempty"`
	Warn     int32           `json:"warningCount,omitempty"`
	Critical int32           `json:"criticalCount,omitempty"`
	Alarms   []*AlarmSummary `json:"alarmCount,omitempty"`
}

type AlarmSummary struct {
	Id       int64  `json:"id,omitempty"`
	Severity string `json:"severity,omitempty"`
	Count    int32  `json:"count,omitempty"`
}

func (p *pubGwSvc) GetAlertStats(locId string) (*AlertStatsResp, error) {
	started := time.Now()
	p.log.PushScope("AlertStats", locId)
	defer p.log.PopScope()

	url := fmt.Sprintf("%v/api/v2/alerts/statistics?locationId=%v", p.uri, url.QueryEscape(locId))
	resp := AlertStatsResp{}
	if e := p.http.Do("GET", url, nil, nil, &resp); e != nil {
		return nil, e
	} else {
		p.logDebugIfSlow(started, "%vms => %v", time.Since(started).Milliseconds(), &resp)
		return &resp, nil
	}
}

type AlertReq struct {
	LocId    string   `json:"locationId,omitempty" url:"locationId" validate:"required,min=32,max=36,uuid_rfc4122|hexadecimal"`
	Severity []string `json:"severity,omitempty" url:"severity,omitempty" validate:"omitempty,dive,oneof=info warning critical"`
	Status   []string `json:"status,omitempty" url:"status,omitempty" validate:"omitempty,dive,oneof=triggered resolved"`
	Reason   []string `json:"reason,omitempty" url:"reason,omitempty" validate:"omitempty,dive,oneof=cleared snoozed cancelled"`
	Page     int32    `json:"page,omitempty" url:"page,omitempty" validate:"omitempty,min=1"`
	Size     int32    `json:"size,omitempty" url:"size,omitempty" validate:"omitempty,min=1,max=250"`
	Language string   `json:"lang,omitempty" url:"lang,omitempty" validate:"omitempty,min=2,regex=^\\[a-z\\]+$"`
	Unit     string   `json:"unit,omitempty" url:"unit,omitempty" validate:"omitempty,oneof=imperial metric"`
}

func (a *AlertReq) Normalize() *AlertReq {
	if a.Page < 1 {
		a.Page = 1
	}
	if a.Size < 1 {
		a.Size = 50
	}
	return a
}

type AlertResp struct {
	Page  int32         `json:"page,omitempty"`
	Total int32         `json:"total,omitempty"`
	Items []*AlertEvent `json:"items,omitempty"`
}

type AlertEvent struct {
	Id      string `json:"id,omitempty" validate:"required,min=12,uuid_rfc4122|hexadecimal"`
	Title   string `json:"displayTitle,omitempty"`
	Message string `json:"displayMessage,omitempty"`
	Alarm   Alarm  `json:"alarm,omitempty"`

	DeviceId   string    `json:"deviceId,omitempty" validate:"required,min=12,uuid_rfc4122|hexadecimal"`
	Status     string    `json:"status,omitempty"`
	Reason     string    `json:"reason,omitempty"`
	SystemMode string    `json:"systemMode,omitempty"`
	SnoozeTo   string    `json:"snoozeTo,omitempty"`
	LocId      string    `json:"locationId,omitempty" validate:"required,min=32,max=36,uuid_rfc4122|hexadecimal"`
	Updated    string    `json:"updateAt,omitempty"`
	UpdatedDt  time.Time `json:"-"`
	Created    string    `json:"createdAt,omitempty"`
	CreatedDt  time.Time `json:"-"`
}

type Alarm struct {
	Id         int64  `json:"id,omitempty"`
	Severity   string `json:"severity,omitempty"`
	IsInternal bool   `json:"isInternal,omitempty"`
}

func (p *pubGwSvc) GetAlerts(req *AlertReq) (*AlertResp, error) {
	started := time.Now()
	p.log.PushScope("Alerts", req.LocId, req.Page, req.Size)
	defer p.log.PopScope()

	if p.skipAlert {
		p.log.Debug("skipping")
		return &AlertResp{Page: 1, Items: []*AlertEvent{}}, nil
	}

	req = req.Normalize()
	if e := p.validator.Struct(req); e != nil {
		return nil, p.log.IfWarnF(e, "req validation failed")
	} else if ps, e := query.Values(req); e != nil {
		return nil, p.log.IfWarnF(e, "req param gen failed")
	} else {
		url := fmt.Sprintf("%v/api/v2/alerts?%v", p.uri, ps.Encode())
		res := AlertResp{}
		if e := p.http.Do("GET", url, nil, nil, &res); e != nil {
			return nil, e
		} else {
			if res.Page == 0 {
				res.Page = 1
			}
			for _, ae := range res.Items {
				if ae.Updated != "" {
					if ae.UpdatedDt, e = time.Parse(FMT_DT_NO_TZ, ae.Updated); e != nil {
						p.log.IfWarnF(e, "can't parse updated %v using %v", ae.Updated, FMT_DT_NO_TZ)
					}
					ae.UpdatedDt = ae.UpdatedDt.UTC()
					if ae.Created == "" {
						ae.Created = ae.Updated
						ae.CreatedDt = ae.UpdatedDt
					}
				}
				if ae.Created != "" && ae.CreatedDt.Year() < 2000 {
					if ae.CreatedDt, e = time.Parse(FMT_DT_NO_TZ, ae.Created); e != nil {
						p.log.IfWarnF(e, "can't parse created %v using %v", ae.Created, FMT_DT_NO_TZ)
					}
					ae.CreatedDt = ae.CreatedDt.UTC()
				}
			}
			p.logDebugIfSlow(started, "%vms => %v %v %v | %v found, %v returned", time.Since(started).Milliseconds(), req.Severity, req.Status, req.Reason, res.Total, len(res.Items))
			return &res, nil
		}
	}
}
