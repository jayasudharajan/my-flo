package main

import (
	"encoding/json"
	"fmt"
	"math"
	"sort"
	"strconv"
	"strings"
	"time"

	un "github.com/bcicen/go-units"

	"github.com/onokonem/sillyQueueServer/timeuuid"
)

type Packer struct {
	local         *Localization
	log           *Logger
	report        *reportContext
	forceTemplate string
	alarmIdType   map[int64]AlarmFilterType
	highPSI       float64
	lowPSI        float64
}

func CreatePacker(report *reportContext, local *Localization, alarmIdType map[int64]AlarmFilterType) *Packer {
	p := Packer{
		local:       local,
		log:         report.log.CloneAsChild("Packer"),
		report:      report,
		alarmIdType: alarmIdType,
		highPSI:     80,
		lowPSI:      20,
	}
	if n, e := strconv.ParseFloat(getEnvOrDefault("FLO_HIGH_PSI", ""), 64); e == nil && n > 0 {
		p.highPSI = n
		p.log.Trace("FLO_HIGH_PSI=%v", n)
	}
	if n, e := strconv.ParseFloat(getEnvOrDefault("FLO_LOW_PSI", ""), 64); e == nil && n > 0 {
		p.lowPSI = n
		p.log.Trace("FLO_LOW_PSI=%v", n)
	}
	return &p
}

func (p *Packer) Box(u *UserSummary, template, unSubUrl string) (*EmailMessage, error) {
	tmpOverride := false
	if p.log.isDebug && p.forceTemplate != "" {
		template = p.forceTemplate
		tmpOverride = true
	}
	r := Recipient{
		Name:         u.Name(),
		EmailAddress: u.Email,
		Data: &RecipientData{
			TemplateId: template,
			EmailTemplateData: &TemplateData{
				Data: make(map[string]interface{}),
			},
		},
	}
	if fwd := p.report.job.req.Recipient; strings.Contains(fwd, "@") {
		r.EmailAddress = fwd //forward to this email instead of the original one
	}
	if data, e := p.buildEmailData(u, unSubUrl); e != nil {
		return nil, p.log.IfErrorF(e, "can't build email data")
	} else if buf, e := json.Marshal(data); e != nil {
		return nil, p.log.IfErrorF(e, "can't serialize")
	} else if e := json.Unmarshal(buf, &r.Data.EmailTemplateData.Data); e != nil {
		return nil, p.log.IfErrorF(e, "can't deserialize")
	}

	cx := p.report
	m := EmailMessage{
		ClientAppName: _log.prefix,
		Id:            timeuuid.UUIDFromTime(cx.job.created).String(),
		TimeStamp:     cx.job.created,
		Recipients:    []*Recipient{&r},
		EmailMetaData: map[string]string{
			"location_id": cx.location.Id,
			"user_id":     u.Id,
			"forced":      fmt.Sprint(cx.job.req.Force),
			"dryRun":      fmt.Sprint(cx.job.req.DryRun),
		},
	}
	if cx.job.req.Recipient != "" {
		m.EmailMetaData["override"] = cx.job.req.Recipient
	}
	if tmpOverride {
		m.EmailMetaData["template_override"] = "true"
	}
	cx.log.Trace("using template %v (override %v) for %v %v", template, tmpOverride, u.Name(), u.Email)
	return &m, nil
}

func (p *Packer) capitalizeLocName(name string) string {
	if cl := len(name); cl > 2 {
		return strings.Title(name)
	} else {
		return strings.ToUpper(name)
	}
}

func (p *Packer) locationName(l *LocResp) string {
	n := p.capitalizeLocName(l.NickName)
	locs := make([]string, 0)
	if l.City != "" {
		locs = append(locs, p.capitalizeLocName(l.City))
	}
	if l.Region != "" {
		locs = append(locs, p.capitalizeLocName(l.Region))
	}
	if len(locs) < 2 && l.Country != "" {
		locs = append(locs, p.capitalizeLocName(l.Country))
	}
	if len(locs) != 0 {
		n += " - " + strings.Join(locs, ", ")
	}
	return n
}

func (p *Packer) buildEmailData(u *UserSummary, unSubUrl string) (*ReportEmailData, error) {
	_, wk := p.report.job.from.ISOWeek()
	d := ReportEmailData{
		Dates: &Dates{
			StartDate: p.local.DateFormat(p.report.job.from, "January 2", u.Locale),
			EndDate:   p.local.DateFormat(p.report.job.to, "January 2", u.Locale),
			DateYear:  p.report.job.to.Format("2006"),
		},
		User: &UserRecipient{
			LocationName:    p.locationName(p.report.location),
			FirstName:       u.FirstName,
			LastName:        u.LastName,
			UnsubscribeLink: unSubUrl,
		},
		FunFacts:   fmt.Sprint(wk),
		UnitSystem: p.local.UnitSystem(u.UnitSystem),
		//Connectivity: &Connectivity{"-1", "-1"}, //default dummy data
	}
	if p.report.location.Subscription != nil {
		if p.report.location.Subscription.Active {
			d.User.UserSubscription = "active"
		} else {
			d.User.UserSubscription = "inactive"
		}
	} else {
		d.User.UserSubscription = "n/a"
	}
	d.WaterUsage = p.computeWaterUsage(u.Locale, &d.UnitSystem)
	d.AveragePressure = p.computeWaterPressure(u.Locale, &d.UnitSystem)
	d.Alerts = p.computeAlerts(u.Locale)

	//NOTE: hacks because this is the only place we can add new properties
	d.User.HighPressure = d.AveragePressure.HighAvg
	d.User.LowPressure = d.AveragePressure.LowAvg
	return &d, nil
}

func (p *Packer) computeWaterPressure(locale string, usrUnit *UnitSystem) *WaterPressureReport {
	var (
		ogUnit                 = p.local.DefaultUnitSystem()
		highPressure, _        = ogUnit.Convert(usrUnit, Pressure, p.highPSI)
		lowPressure, _         = ogUnit.Convert(usrUnit, Pressure, p.lowPSI)
		thisWk, thisCount      = p.report.SumPressure(p.report.job.from, p.report.job.to, usrUnit)
		lastWk, lastCount      = p.report.SumPressure(p.report.job.from.Add(-DUR_WEEK), p.report.job.from.Add(-time.Second), usrUnit)
		thisAvg, lastAvg, diff float64
	)
	if thisCount != 0 {
		thisAvg = math.Round(thisWk.Float() / float64(thisCount))
	}
	if lastCount != 0 {
		lastAvg = math.Round(lastWk.Float() / float64(lastCount))
	}
	diff = math.Round(thisAvg - lastAvg)
	wp := WaterPressureReport{
		ThisWeekAvg:       p.local.Sprint(locale, thisAvg),
		LastWeekAvg:       p.local.Sprint(locale, lastAvg),
		ThisVsLastWeekAvg: p.local.Sprint(locale, diff),
		ThisVsLastWeekPct: p.local.Sprint(locale, math.Round(diff*1_000/lastAvg)/10),
		HighAvg:           p.local.Sprint(locale, math.Round(highPressure.Float())),
		LowAvg:            p.local.Sprint(locale, math.Round(lowPressure.Float())),
	}
	if lastWk.Float() != 0 {
		pct := math.Round(diff*1_000/lastAvg) / 10
		wp.ThisVsLastWeekPct = p.local.Sprint(locale, pct)
	} else if thisWk.Float() == 0 {
		wp.ThisVsLastWeekPct = "0"
	} else { //last week was 0, we'll assume that it has 1 unit to compute PCT better as email always render PCT
		wp.ThisVsLastWeekPct = p.local.Sprint(locale, diff)
	}
	return &wp
}

//goal is stored in default unit system?
func (p *Packer) computeWaterUsage(locale string, usrUnit *UnitSystem) *WaterUseReport {
	var (
		ogUnit    = p.local.DefaultUnitSystem()
		thisWk, _ = p.report.SumUsage(p.report.job.from, p.report.job.to, usrUnit)
		lastWk, _ = p.report.SumUsage(p.report.job.from.Add(-DUR_WEEK), p.report.job.from.Add(-time.Second), usrUnit)
		diff      = math.Round(thisWk.Float() - lastWk.Float())
		diffG, _  = usrUnit.Convert(&ogUnit, Volume, diff) //convert BACK to US gallon
	)
	wc := WaterUseReport{
		ThisWeekTotal:     p.local.Sprint(locale, thisWk.Float()),
		LastWeekTotal:     p.local.Sprint(locale, lastWk.Float()),
		ThisVsLastWeek:    p.local.Sprint(locale, diff),
		ThisVsLastWeekGal: p.local.Sprint(locale, math.Round(diffG.Float()*100)/100), //NOTE: not sure if this is being used but field name has "gallon" in it
	}
	if lastWk.Float() != 0 {
		pct := math.Round(diff*1_000/lastWk.Float()) / 10
		wc.ThisVsLastWeekPct = p.local.Sprint(locale, pct)
	} else if thisWk.Float() == 0 {
		wc.ThisVsLastWeekPct = "0"
	} else { //last week was 0, we'll assume that it has 1 unit to compute PCT better as email always render PCT
		wc.ThisVsLastWeekPct = p.local.Sprint(locale, diff)
	}

	if daily, e := p.compileDailyUsage(locale, usrUnit); e != nil {
		wc.ThisWeekDaily = []*DailyWaterUsage{} //probably ok?
	} else {
		wc.ThisWeekDaily = daily
	}
	return &wc
}

func (p *Packer) compileDailyUsage(locale string, usrUnit *UnitSystem) ([]*DailyWaterUsage, error) {
	var (
		frmUx  = p.report.job.from.Unix()
		toUx   = p.report.job.to.Unix()
		ogGoal = float64(p.report.location.GallonsPerDayGoal)
		goal   un.Value
		ogUnit = p.local.DefaultUnitSystem()
		e      error
		res    = make([]*DailyWaterUsage, 0, 7)
	)
	if goal, e = ogUnit.Convert(usrUnit, Volume, ogGoal); e != nil {
		p.log.IfWarnF(e, "can't convert %v %v %v to %v", ogGoal, Volume, ogUnit, usrUnit)
	}
	dayUse := make(map[string]float64) //k=date, v=water usage. aggregate by day using default unit system
	for _, wc := range p.report.locWater {
		k := wc.Time.Format(FMT_DT_DAYTZ)
		if _, ok := dayUse[k]; ok {
			dayUse[k] += float64(wc.Gallons)
		} else {
			dayUse[k] = float64(wc.Gallons)
		}
	}
	tz, _ := time.LoadLocation(p.report.location.TimeZone)
	for k, v := range dayUse { //build daily consumption w/ correct unit
		if dt, e := time.ParseInLocation(FMT_DT_DAYTZ, k, tz); e != nil {
			return nil, p.log.IfWarnF(e, "can't parse %v using %v", k, FMT_DT_DAYTZ)
		} else if ux := dt.Unix(); !(ux >= frmUx && ux <= toUx) {
			continue //not current week
		} else {
			lastWkDt := dt.Add(-DUR_WEEK)
			if thisUse, e := ogUnit.Convert(usrUnit, Volume, v); e != nil {
				return nil, p.log.IfWarnF(e, "can't convert %v %v %v to %v", v, Volume, ogUnit, usrUnit)
			} else {
				lastUse, _ := usrUnit.Convert(usrUnit, Volume, 0)
				if lastUseVal, ok := dayUse[lastWkDt.Format(FMT_DT_DAYTZ)]; ok {
					if lastUse, e = ogUnit.Convert(usrUnit, Volume, lastUseVal); e != nil {
						p.log.IfWarnF(e, "can't convert %v %v %v to %v", lastUseVal, Volume, ogUnit, usrUnit)
					}
				} else {
					p.log.Info("can't compute last week usage for %v", k)
				}
				dc := p.CreateDailyConsumption(locale, dt, lastWkDt, thisUse, lastUse, goal)
				res = append(res, dc)
			}
		}
	}
	sort.Slice(res, func(i, j int) bool {
		return res[i].dt < res[j].dt
	})
	return res, nil
}

const FMT_DT_DAYTZ = "2006-0102MST"

//exclusive start, inclusive end
func (rp *reportContext) SumUsage(start, end time.Time, usrUnit *UnitSystem) (sum un.Value, count int) {
	rp.log.PushScope("SumUsage", start.Format(FMT_DT_DAYTZ), end.Format(FMT_DT_DAYTZ), usrUnit.Id)
	defer rp.log.PopScope()
	var (
		startU = start.Unix()
		endU   = end.Unix()
		note   strings.Builder
		total  float64
		cop    = un.FmtOptions{true, true, 0}
	)
	for _, wc := range rp.locWater {
		if ux := wc.Time.Unix(); ux >= startU && ux <= endU {
			if converted, e := rp.defaultUnit.Convert(usrUnit, Volume, float64(wc.Gallons)); e != nil {
				rp.log.IfWarnF(e, "conversion failed for %v", wc)
			} else {
				count++
				total += math.Round(converted.Float())
				note.WriteString(wc.Time.Format(FMT_DT_DAYTZ))
				note.WriteString(fmt.Sprintf(":%v, ", converted.Fmt(cop)))
			}
		}
	}
	sum, _ = usrUnit.Convert(usrUnit, Volume, total)
	rp.log.Trace("SUM: %v | len=%v %v", sum.Fmt(cop), count, note.String())
	return sum, count
}

//exclusive start, inclusive end
func (rp *reportContext) SumPressure(start, end time.Time, usrUnit *UnitSystem) (sum un.Value, count int) {
	rp.log.PushScope("SumPressure", start.Format(FMT_DT_DAYTZ), end.Format(FMT_DT_DAYTZ), usrUnit.Id)
	defer rp.log.PopScope()
	var (
		startU = start.Unix()
		endU   = end.Unix()
		note   strings.Builder
		total  float64
		cop    = un.FmtOptions{Label: true, Short: true, Precision: 0}
	)
	for _, u := range rp.macWater {
		for _, wc := range u.Items {
			if ux := wc.Time.Unix(); ux >= startU && ux <= endU && !wc.IsEmpty() {
				if converted, e := rp.defaultUnit.Convert(usrUnit, Pressure, coalesceFloat64(wc.PSI)); e != nil {
					rp.log.IfWarnF(e, "conversion failed for %v", wc)
				} else {
					count++
					total += math.Round(converted.Float()*10) / 10
					note.WriteString(wc.Time.Format(FMT_DT_DAYTZ))
					note.WriteString(fmt.Sprintf(":%v, ", converted.Fmt(cop)))
				}
			}
		}
	}
	sum, _ = usrUnit.Convert(usrUnit, Pressure, total)
	rp.log.Trace("SUM: %v | len=%v %v", sum.Fmt(cop), count, note.String())
	return sum, count
}

type ReportEmailData struct {
	Alerts          *AlertReport         `json:"alerts"`
	AveragePressure *WaterPressureReport `json:"average_pressure"`
	Connectivity    *Connectivity        `json:"connectivity"`
	Dates           *Dates               `json:"dates"`
	FunFacts        string               `json:"fun_facts"`
	UnitSystem      UnitSystem           `json:"measurement_unit_system"`
	User            *UserRecipient       `json:"user"`
	WaterUsage      *WaterUseReport      `json:"water_consumption"`
}

type Dates struct {
	StartDate string `json:"start_date"`
	EndDate   string `json:"end_date"`
	DateYear  string `json:"date_year"`
}

type UserRecipient struct {
	HighPressure     string `json:"high_pressure"`
	LowPressure      string `json:"low_pressure"`
	LocationName     string `json:"location_name"`
	FirstName        string `json:"firstname"`
	LastName         string `json:"lastname"`
	UnsubscribeLink  string `json:"unsubscribe_link"`
	UserSubscription string `json:"user_subscription_status"`
}

type WaterUseReport struct {
	ThisWeekTotal     string             `json:"this_week_total_consumption"`
	LastWeekTotal     string             `json:"last_week_total_consumption"`
	ThisVsLastWeekGal string             `json:"this_vs_last_week_consumption_gallons"` //always in us gallon
	ThisVsLastWeek    string             `json:"this_vs_last_week_consumption"`         //user's measurement system unit
	ThisVsLastWeekPct string             `json:"this_vs_last_week_consumption_percent"`
	ThisWeekDaily     []*DailyWaterUsage `json:"this_week_daily_consumption"`
}

type DailyWaterUsage struct {
	Day          string `json:"day"`
	ThisWeek     string `json:"this_week"`
	LastWeek     string `json:"last_week"`
	Percentage   string `json:"percentage"`
	DailyGoal    string `json:"daily_goal"`
	LastWeekDate string `json:"last_week_date"`
	ThisWeekDate string `json:"this_week_date"`
	dt           int64  `json:"-"`
}

// assumes unit value is already correct, no conversion here
func (p *Packer) CreateDailyConsumption(locale string, thisDt, lastDt time.Time, thisUse, lastUse, goal un.Value) *DailyWaterUsage {
	dc := DailyWaterUsage{
		dt:           thisDt.Unix(),
		Day:          fmt.Sprint(int(thisDt.Weekday())),
		ThisWeekDate: p.local.DateFormat(thisDt, "01/02", locale),
		LastWeekDate: p.local.DateFormat(lastDt, "01/02", locale),
		ThisWeek:     p.local.Sprint(locale, math.Round(thisUse.Float())),
		LastWeek:     p.local.Sprint(locale, math.Round(lastUse.Float())),
		DailyGoal:    p.local.Sprint(locale, math.Round(goal.Float())),
	}
	if lastUse.Float() != 0 {
		diff := math.Round(thisUse.Float() - lastUse.Float())
		dc.Percentage = p.local.Sprint(locale, math.Round(diff*1_000/lastUse.Float())/10)
	} else if thisUse.Float() == 0 {
		dc.Percentage = "0"
	} else {
		dc.Percentage = "∞"
	}
	return &dc
}

type Connectivity struct {
	AverageWifiStrength             string `json:"average_wifi_strength"`
	PercentageOfTimeDeviceConnected string `json:"percentage_of_time_device_connected"`
}

type AlertReport struct {
	CriticalAlerts      []AlertInfo `json:"critical_alerts"`
	WarningAlerts       []AlertInfo `json:"warning_alerts"`
	CriticalAlertsCount string      `json:"critical_alerts_count"`
	WarningAlertsCount  string      `json:"warning_alerts_count"`
	PendingAlerts       string      `json:"pending_alerts"`
	ShutOffWaterCount   string      `json:"shut_off_water_count"`
	DaysSinceLeak       string      `json:"days_since_leak"`
	DeviceOfflineCount  string      `json:"device_offline_count"`
}

type AlertInfo struct {
	IncidentDate string `json:"incident_date"`
	FriendlyName string `json:"friendly_name"`
}

type WaterPressureReport struct {
	HighAvg           string `json:"high_average_pressure"`
	LowAvg            string `json:"low_average_pressure"`
	ThisWeekAvg       string `json:"this_week_average_pressure"`
	LastWeekAvg       string `json:"last_week_average_pressure"`
	ThisVsLastWeekAvg string `json:"this_vs_last_week_average_pressure"`
	ThisVsLastWeekPct string `json:"this_vs_last_week_average_pressure_percent"`
	//DailyAvg          []DailyAvgPressure `json:"this_week_daily_average_pressure"`
}

//type DailyAvgPressure struct {
//	Day          string `json:"day"`
//	ThisWeek     string `json:"this_week"`
//	LastWeek     string `json:"last_week"`
//	Percentage   string `json:"percentage"`
//	LastWeekDate string `json:"last_week_date"`
//	ThisWeekDate string `json:"this_week_date"`
//	dt           int64  `json:"-"`
//}

func (p *Packer) computeAlerts(locale string) *AlertReport {
	pendingCount := p.report.alertStats.PendingTotal()
	ar := AlertReport{
		CriticalAlerts:      make([]AlertInfo, 0),
		WarningAlerts:       make([]AlertInfo, 0),
		CriticalAlertsCount: p.local.Sprint(locale, p.report.alertStats.Pending.Critical),
		WarningAlertsCount:  p.local.Sprint(locale, p.report.alertStats.Pending.Warn),
		PendingAlerts:       p.local.Sprint(locale, pendingCount),
		ShutOffWaterCount:   p.local.Sprint(locale, len(p.report.shutOffs)),
	}
	ar.DaysSinceLeak = p.local.Sprint(locale, p.daysSinceLeak())
	ar.DeviceOfflineCount = p.local.Sprint(locale, p.offLineDevices())
	//TODO: fill this with real data
	//for _, a := range p.report.alertStats.Pending.Alarms { //semi-mocked data to fix a bug in SendWithUs Templates
	//	n := AlertInfo{
	//		//IncidentDate: "",
	//		FriendlyName: p.local.SprintF(locale, "%v #%v", a.Severity, a.Id),
	//	}
	//	if strings.EqualFold(a.Severity, "warning") {
	//		ar.WarningAlerts = append(ar.WarningAlerts, n)
	//	} else if strings.EqualFold(a.Severity, "critical") {
	//		ar.CriticalAlerts = append(ar.CriticalAlerts, n)
	//	}
	//}
	return &ar
}

func (p *Packer) daysSinceLeak() int {
	last := time.Unix(0, 0)
	for _, a := range p.report.leaks {
		if at, ok := p.alarmIdType[a.Alarm.Id]; ok && at == ALARM_LEAK && a.CreatedDt.After(last) {
			last = a.CreatedDt
		}
	}
	days := -1
	if last.Year() > 2000 {
		days = int(math.Floor(p.report.job.created.Sub(last).Hours() / 24))
	}
	return days
}

func (p *Packer) offLineDevices() int {
	offLine := 0
	for _, d := range p.report.location.Devices {
		if !d.IsPaired || !d.IsConnected || d.LastPing.Before(p.report.job.from) {
			offLine++
		}
	}
	return offLine
}
