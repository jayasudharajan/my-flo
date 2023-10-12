package main

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"golang.org/x/text/message"

	un "github.com/bcicen/go-units"
	"github.com/google/go-querystring/query"
	_ "golang.org/x/text/message"
)

const (
	ENVVAR_LOCALIZED_EMAIL_TEMPLATE = "FLO_LOCALIZED_EMAIL_TEMPLATE"
	ENVVAR_LOCALIZED_CACHE_DUR_MIN  = "FLO_LOCALIZED_CACHE_DUR_MIN"
	ENVVAR_LOCALIZATION_SVC_URI     = "FLO_LOCALIZATION_SVC_URI"
	ENVVAR_LOCALIZATION_SVC_JWT     = "FLO_LOCALIZATION_SVC_JWT"
)

type Localization struct {
	log         *Logger
	http        *httpUtil
	uri         string
	validator   *Validator
	mux         sync.RWMutex
	state       int32 //-1= not init, 0= closed, 1= open
	refreshed   time.Time
	refreshMin  float64 //minutes to refresh cache
	emailTN     string
	templates   map[string]string //cached for local lookups
	locFallback map[string]string
	monthNames  map[string][]string
	weekDays    map[string][]string
	unitSystems map[string]UnitSystem
	dateFormats map[string]map[string]string
	printers    map[string]*message.Printer
}

func CreateLocalization(validator *Validator, log *Logger) (*Localization, error) {
	l := log.CloneAsChild("local")
	uri := getEnvOrDefault(ENVVAR_LOCALIZATION_SVC_URI, "")
	if strings.Index(uri, "http") != 0 {
		return nil, l.Fatal("CreateLocalization: missing or bad %v", ENVVAR_LOCALIZATION_SVC_URI)
	}
	loc := Localization{
		validator: validator,
		uri:       uri,
		http:      CreateHttpUtil(getEnvOrDefault(ENVVAR_LOCALIZATION_SVC_JWT, ""), l, 0), //optional auth, not needed for direct api call
		emailTN:   getEnvOrDefault(ENVVAR_LOCALIZED_EMAIL_TEMPLATE, "weekly.stats.template"),
		log:       l,
		state:     -1,
	}
	loc.presetDefaults()
	if loc.refreshMin, _ = strconv.ParseFloat(getEnvOrDefault(ENVVAR_LOCALIZED_CACHE_DUR_MIN, "30"), 64); loc.refreshMin <= 0 {
		loc.refreshMin = 30
	}
	if !loc.refreshCache() {
		return nil, l.Error("CreateLocalization: missing %v for %v", ENVVAR_LOCALIZED_EMAIL_TEMPLATE, loc.emailTN)
	}
	return &loc, nil
}

func (l *Localization) presetDefaults() { //TODO: move this into DB & load via .refreshCache()
	if !atomic.CompareAndSwapInt32(&l.state, -1, 0) {
		return //skip if it's already been done once
	}
	l.monthNames = map[string][]string{ //en is go's built in fall back. TODO: move into localizations svc
		"fr": {"Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"},
		"es": {"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"},
	}
	l.weekDays = map[string][]string{ //0 is Sunday in golang
		"fr": {"Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"},
		"es": {"Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"},
	}
	international := map[string]string{
		"January 2, 2006": "2 January 2006",
		"January 2":       "2 January",
		"01/02":           "02/01",
		"01-02-2006":      "2006-02-01",
		"01/02/2006":      "2006/02/01",
	}
	l.dateFormats = map[string]map[string]string{ //missing settings should falls back to golang default (en-us)
		"":   international,
		"fr": international,
		"es": international,
	}
	metric := UnitSystem{
		Id:   "metric",
		Name: "Metric",
		Units: map[Measurement]UnitInfo{
			Temperature: {"C", "Celsius", un.Celsius},
			//Pressure:    {"Bar", "Bar", un.Bar},
			Pressure: {"kPA", "Kilo Pascal", un.KiloPascal},
			Volume:   {"L", "Litre", un.Liter},
		},
	}
	l.unitSystems = map[string]UnitSystem{ //TODO: move into localizations svc
		"":       metric,
		"metric": metric,
		"imperial": { //Flo's default
			Id:   "imperial_us",
			Name: "Imperial",
			Units: map[Measurement]UnitInfo{
				Temperature: {"F", "Fahrenheit", un.Fahrenheit},
				Pressure:    {"psi", "Pounds per square inch", un.Psi},
				Volume:      {"gal", "Gallon", un.FluidGallon},
			},
		},
	}
	l.printers = map[string]*message.Printer{ //defaults to en-us
		//"en": message.NewPrinter(language.English), //TODO: fix the template to support proper localization, enabling this will break current template
		//"fr": message.NewPrinter(language.French),
		//"es": message.NewPrinter(language.Spanish),
	}
}

func (l *Localization) DefaultUnitSystem() UnitSystem {
	return l.unitSystems["imperial"] //metric is probably the correct default but... Murica
}

type Measurement string

const (
	Temperature Measurement = "temperature"
	Pressure    Measurement = "pressure"
	Volume      Measurement = "volume"
)

func (m *Measurement) String() string {
	return string(*m)
}

type UnitSystem struct {
	Id    string                   `json:"id"`
	Name  string                   `json:"name"`
	Units map[Measurement]UnitInfo `json:"units"` //formerly "ConversionUnits"
}

type UnitInfo struct {
	Abbrev string  `json:"abbrev"`
	Name   string  `json:"name"`
	unit   un.Unit `json:"-"`
}

var (
	UNIT_EMPTY       = un.Unit{}
	UNIT_VALUE_EMPTY = un.NewValue(0, UNIT_EMPTY)
)

func (frm *UnitInfo) Convert(to *UnitInfo, v float64) (un.Value, error) {
	if strings.EqualFold(frm.Name, to.Name) || frm.unit.Name == to.unit.Name {
		return un.NewValue(v, frm.unit), nil //same unit to itself, return original
	} else if x, e := un.ConvertFloat(v, frm.unit, to.unit); e != nil {
		return UNIT_VALUE_EMPTY, e
	} else {
		return x, nil
	}
}

func (frm *UnitSystem) Convert(to *UnitSystem, measurement Measurement, v float64) (un.Value, error) {
	if uf, ok := frm.Units[measurement]; !ok {
		return UNIT_VALUE_EMPTY, errors.New("can't locate measurement " + measurement.String() + " in " + frm.Id)
	} else if ut, ok := to.Units[measurement]; !ok {
		return UNIT_VALUE_EMPTY, errors.New("can't locate measurement " + measurement.String() + " in " + to.Id)
	} else if strings.EqualFold(uf.Name, ut.Name) || uf.unit.Name == ut.unit.Name {
		return un.NewValue(v, uf.unit), nil //same unit conversion, just return original value
	} else if x, e := un.ConvertFloat(v, uf.unit, ut.unit); e != nil {
		return UNIT_VALUE_EMPTY, e
	} else {
		return x, nil
	}
}

func (l *Localization) UnitSystem(unit string) UnitSystem {
	unit = strings.ToLower(unit)
	if u, ok := l.unitSystems[unit]; ok {
		return u
	} else {
		if arr := strings.Split(unit, "_"); len(arr) != 0 {
			if u, ok := l.unitSystems[arr[0]]; ok {
				return u
			}
		}
		return l.DefaultUnitSystem()
	}
}

func (l *Localization) ResolveLocale(locale string) string {
	locale = strings.ToLower(locale)
	if _, ok := l.templates[locale]; ok {
		return locale
	} else if loc, ok := l.locFallback[locale]; ok {
		return loc
	} else if loc2, ok := l.locFallback[l.LangFrmLocale(locale)]; ok {
		return loc2
	} else {
		return ""
	}
}

func (l *Localization) LangFrmLocale(locale string) string {
	arr := strings.Split(locale, "-")
	if len(arr) != 0 {
		return arr[0]
	} else {
		return locale
	}
}

func (l *Localization) Sprint(locale string, arg interface{}) string {
	lang := l.LangFrmLocale(l.ResolveLocale(locale))
	if p, ok := l.printers[lang]; ok {
		return p.Sprint(arg)
	}
	return fmt.Sprint(arg) //fall back to golang default (en-us with minimal formatting capability)
}

func (l *Localization) SprintF(locale, format string, args ...interface{}) string {
	lang := l.LangFrmLocale(l.ResolveLocale(locale))
	if p, ok := l.printers[lang]; ok {
		return p.Sprintf(format, args)
	}
	return fmt.Sprintf(format, args...) //fall back to golang default (en-us with minimal formatting capability)
}

//relies on regular golang date formats
func (l *Localization) DateFormat(d time.Time, fmt string, locale string) string {
	lang := l.LangFrmLocale(l.ResolveLocale(locale))
	if fmtMap, ok := l.dateFormats[lang]; ok {
		if newFmt, ok := fmtMap[fmt]; ok {
			fmt = newFmt //rearrange formats first before local replace
		}
	} // else, fall back to en & use golang built in default
	if months, ok := l.monthNames[lang]; ok { //pre-render local month name in template
		if strings.Contains(fmt, "January") {
			mn := months[d.Month()-1]
			fmt = strings.ReplaceAll(fmt, "January", mn)
		}
		if strings.Contains(fmt, "Jan") {
			mn := months[d.Month()-1]
			fmt = strings.ReplaceAll(fmt, "Jan", mn[:3])
		}
	} // else, fall back to en & use golang built in default
	if dayName, ok := l.weekDays[lang]; ok { //pre-render local day of week in template
		if strings.Contains(fmt, "Monday") {
			dn := dayName[d.Weekday()]
			fmt = strings.ReplaceAll(fmt, "January", dn)
		}
		if strings.Contains(fmt, "Mon") {
			dn := dayName[d.Weekday()]
			fmt = strings.ReplaceAll(fmt, "Jan", dn[:3])
		}
	} // else, fall back to en & use golang built in default
	return d.Format(fmt)
}

func (l *Localization) Open() {
	if atomic.CompareAndSwapInt32(&l.state, 0, 1) {
		l.log.Info("Open: Enter")
		defer l.log.Info("Open: Exit")

		for l != nil && atomic.LoadInt32(&l.state) == 1 { //will refresh local cache on interval
			l.refreshCache()
			time.Sleep(time.Second * 2)
		}
	}
}

func (l *Localization) Close() {
	if l == nil {
		return
	}
	if atomic.CompareAndSwapInt32(&l.state, 1, 0) {
		l.log.Info("Closing")
	}
}

func (l *Localization) EmailTemplate(loc string) (string, error) {
	l.mux.RLock()
	defer l.mux.RUnlock()

	loc = strings.ToLower(loc)
	if id, ok := l.templates[loc]; ok {
		return id, nil
	} else if fallback, ok := l.locFallback[loc]; ok {
		if id, ok := l.templates[fallback]; ok {
			return id, nil
		}
	}
	return "", l.log.Warn("EmailTemplate: missing for %v", loc)
}

func (l *Localization) refreshCache() bool {
	started := time.Now()
	l.mux.Lock()
	defer l.mux.Unlock()
	if time.Since(l.refreshed).Minutes() < l.refreshMin {
		return false
	}
	l.refreshed = time.Now()

	ok := true
	tmp := l.fetchLocalTemplateMap(l.emailTN)
	if len(tmp) != 0 {
		l.templates = tmp
	} else {
		ok = false
	}
	fb := l.fetchLocaleFallbackMap()
	if len(fb) != 0 {
		l.locFallback = fb
	} else {
		ok = false
	}
	l.log.Info("refreshCache: %v | %vms %v fallBacks | %v", ok, time.Since(started).Milliseconds(), len(fb), tmp)
	return ok
}

func (s *Localization) fetchLocalTemplateMap(name string) map[string]string {
	arg := LocalAssetReq{Name: name, Type: "email", Released: true}
	if locRes, e := s.GetLocalAssets(&arg); e != nil {
		return nil
	} else {
		ltMap := make(map[string]string)
		for _, la := range locRes.Items {
			if la.Value != "" {
				k := strings.ToLower(la.Locale)
				ltMap[k] = la.Value
			}
		}
		return ltMap
	}
}

func (s *Localization) fetchLocaleFallbackMap() map[string]string {
	arg := LocaleReq{Released: true, Limit: 250}
	if locRes, e := s.GetLocales(&arg); e != nil {
		return nil
	} else {
		lMap := make(map[string]string)
		for _, l := range locRes.Items {
			lMap[strings.ToLower(l.Id)] = strings.ToLower(l.FallBack)
		}
		if _, ok := lMap[""]; !ok {
			lMap[""] = "en"
		}
		if _, ok := lMap["en"]; !ok {
			lMap["en"] = "en-us"
		}
		return lMap
	}
}

type LocalAssetReq struct {
	Name     string `json:"name,omitempty" url:"name,omitempty" validate:"omitempty,min=1,max=256"`
	Search   string `json:"search,omitempty" url:"search,omitempty" validate:"omitempty,min=1,max=256"`
	Type     string `json:"type,omitempty" url:"type,omitempty" validate:"omitempty,oneof=voice display push sms email"`
	Locale   string `json:"locale,omitempty" url:"locale,omitempty" validate:"omitempty,min=2,max=5"`
	Released bool   `json:"released,omitempty" url:"released,omitempty" validate:"omitempty"`
	Offset   int32  `json:"offset,omitempty" url:"offset,omitempty" validate:"omitempty,min=0"`
	Limit    int32  `json:"limit,omitempty" url:"imit,omitempty" validate:"omitempty,min=1"`
}

func (l *LocalAssetReq) Normalize() *LocalAssetReq {
	if l == nil {
		return nil
	}
	l.Name = strings.TrimSpace(l.Name)
	l.Search = strings.TrimSpace(l.Search)
	l.Type = strings.ToLower(l.Type)
	l.Locale = strings.ToLower(l.Locale)
	if l.Limit < 1 {
		l.Limit = 50
	} else if l.Limit > 250 {
		l.Limit = 250
	}
	return l
}

type LocalAssetResp struct {
	Meta  LocalizationMeta `json:"meta,omitempty" validate:"required,dive"`
	Items []*LocalAsset    `json:"items,omitempty" validate:"omitempty,dive"`
}
type LocalizationMeta struct {
	Total  int32 `json:"total,omitempty" validate:"required,min=0"`
	Offset int32 `json:"offset,omitempty" validate:"omitempty,min=0"`
	Limit  int32 `json:"limit,omitempty" validate:"omitempty,min=0"`
}
type LocalAsset struct {
	Id       string `json:"id,omitempty" validate:"required,min=12,uuid_rfc4122|hexadecimal"`
	Name     string `json:"name,omitempty" validate:"required,min=1"`
	Type     string `json:"type,omitempty" validate:"required,min=1"`
	Locale   string `json:"locale,omitempty" validate:"required,min=2"`
	Value    string `json:"value,omitempty" validate:"required,min=1"`
	Released bool   `json:"released,omitempty" validate:"omitempty"`
}

func (p *Localization) GetLocalAssets(arg *LocalAssetReq) (*LocalAssetResp, error) {
	started := time.Now()
	p.log.PushScope("LocalAssets")
	defer p.log.PopScope()

	if e := p.validator.Struct(arg.Normalize()); e != nil {
		return nil, p.log.IfWarnF(e, "arg validation failed")
	} else if ps, e := query.Values(arg); e != nil {
		return nil, p.log.IfWarnF(e, "arg param gen failed")
	} else {
		url := fmt.Sprintf("%v/assets?%v", p.uri, ps.Encode())
		res := LocalAssetResp{}
		if e := p.http.Do("GET", url, nil, nil, &res); e != nil {
			return nil, e
		} else {
			p.log.Debug("%vms => %v found, %v returned | %v", time.Since(started).Milliseconds(), res.Meta.Total, len(res.Items), arg)
			return &res, nil
		}
	}
}

type LocaleReq struct {
	FallBack string `json:"fallback,omitempty" url:"fallback,omitempty" validate:"omitempty,min=2,max=5"`
	Released bool   `json:"released,omitempty" url:"released,omitempty" validate:"omitempty"`
	Offset   int32  `json:"offset,omitempty" url:"offset,omitempty" validate:"omitempty,min=0"`
	Limit    int32  `json:"limit,omitempty" url:"limit,omitempty" validate:"omitempty,min=1,max=250"`
}

func (l *LocaleReq) Normalize() *LocaleReq {
	if l == nil {
		return nil
	}
	l.FallBack = strings.ToLower(l.FallBack)
	if l.Limit < 1 {
		l.Limit = 100
	} else if l.Limit > 250 {
		l.Limit = 250
	}
	return l
}

type LocaleResp struct {
	Meta  LocalizationMeta `json:"meta,omitempty"`
	Items []*Locale        `json:"items,omitempty"`
}
type Locale struct {
	Id       string `json:"id,omitempty"`
	FallBack string `json:"fallback,omitempty"`
	Released bool   `json:"released,omitempty"`
}

func (p *Localization) GetLocales(arg *LocaleReq) (*LocaleResp, error) {
	started := time.Now()
	p.log.PushScope("Locale")
	defer p.log.PopScope()

	if e := p.validator.Struct(arg.Normalize()); e != nil {
		return nil, p.log.IfWarnF(e, "arg validation failed")
	} else if ps, e := query.Values(arg); e != nil {
		return nil, p.log.IfWarnF(e, "arg param gen failed")
	} else {
		url := fmt.Sprintf("%v/locales?%v", p.uri, ps.Encode())
		res := LocaleResp{}
		if e := p.http.Do("GET", url, nil, nil, &res); e != nil {
			return nil, e
		} else {
			p.log.Debug("%vms => %v found, %v returned | %v", time.Since(started).Milliseconds(), res.Meta.Total, len(res.Items), arg)
			return &res, nil
		}
	}
}

func (p *Localization) Ping() error {
	e := p.http.Do("GET", p.uri+"/types?limit=1", nil, nil, nil)
	return p.log.IfWarnF(e, "Ping")
}
