package main

import (
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/mmcloughlin/geohash"
	"github.com/pkg/errors"
)

type Location struct {
	Name     string `json:"name"`    //the name of the location used for this request.
	Region   string `json:"region"`  //region name associated with the location used for this request.
	Country  string `json:"country"` //the country name associated with the location used for this request.
	PostCode string `json:"postCode,omitempty"`

	LatStr string `json:"lat"` // the latitude coordinate associated with the location used for this request. Use .Lat() to get float32
	LonStr string `json:"lon"` // the longitude coordinate associated with the location used for this request. use Lon() to get float32
	_lat   *float32
	_lon   *float32

	TimeZone      string `json:"timezone_id,omitempty"`     //the timezone ID associated with the location used for this request. (Example: America/New_York)
	LocalUnixTime int64  `json:"localtime_epoch,omitempty"` //Returns the local time (as UNIX timestamp) of the location used for this request. (Example: 1567844040)
	LocalTimeStr  string `json:"localtime,omitempty"`       //Returns the local time of the location used for this request. (Example: 2019-09-11 08:14)
	UtcOffset     string `json:"utc_offset,omitempty"`      //Returns the UTC offset (in hours) of the timezone associated with the location used for this request. (Example: -4.0)
	_time         time.Time
	_timeOffset   string
}

func (l Location) String() string {
	gh5 := ""
	if l.ValidLatLon() {
		gh5 = fmt.Sprintf("(%v, %v) %v ",
			l.Lon(), l.Lat(), geohash.EncodeWithPrecision(float64(l.Lat()), float64(l.Lon()), 5))
	}
	return fmt.Sprintf("Loc%v -> %v",
		gh5, strJoinIfNotEmpty(",", l.Name, l.Region, l.PostCode, l.Country))
}

func (l *Location) NormalizeLatLonCenter64() (lat, lon float64) {
	if l == nil {
		return -1000, -1000
	}
	gh5 := geohash.EncodeWithPrecision(float64(l.Lat()), float64(l.Lon()), 5)
	lat2, lon2 := geohash.DecodeCenter(gh5)
	return lat2, lon2
}

func (l *Location) NormalizeLatLonCenter() (lat, lon float32) {
	lat1, lon1 := l.NormalizeLatLonCenter64()
	return float32(lat1), float32(lon1)
}

func (l *Location) Combine(loc *Location) *Location {
	if l == nil || loc == nil {
		return l
	}
	l.Snapshot()
	if loc.Country != "" {
		l.Name = loc.Name
	}
	if loc.Region != "" {
		l.Region = loc.Region
	}
	if loc.PostCode != "" {
		l.PostCode = loc.PostCode
	}
	if loc.Country != "" {
		l.Country = loc.Country
	}

	l.LatStr = loc.LatStr
	l._lat = loc._lat
	l.LonStr = loc.LonStr
	l._lon = loc._lon

	if l.TimeZone == "" {
		l.TimeZone = loc.TimeZone
	}
	if l.LocalUnixTime == 0 {
		l.LocalUnixTime = loc.LocalUnixTime
	}
	if l.LocalTimeStr == "" {
		l.LocalTimeStr = loc.LocalTimeStr
	}
	if l.UtcOffset == "" {
		l.UtcOffset = loc.UtcOffset
	}
	return l
}

func (l *Location) ZeroLatLon() bool {
	if l == nil {
		return false
	}
	return l.Lat() == 0 && l.Lon() == 0
}

func (l *Location) ToLocResp() *LocResp {
	r := LocResp{
		Name:      l.Name,
		Region:    l.Region,
		PostCode:  l.PostCode,
		Country:   l.Country,
		TimeZone:  l.TimeZone,
		UtcOffset: l.UtcOffset,
	}
	if l.ValidLatLon() {
		r.Lat, r.Lon = l.Lat(), l.Lon()
		r.GeoHash = geohash.EncodeWithPrecision(float64(r.Lat), float64(r.Lon), 5)
	}
	return &r
}

func (l *Location) ValidLatLon() bool {
	if l == nil {
		return false
	}
	if lat := l.Lat(); lat >= -90 && lat <= 90 {
		if lon := l.Lon(); lon >= -180 && lon <= 180 {
			return true
		}
	}
	return false
}

func (l *Location) Snapshot() { //store hidden values back for serialization
	if l != nil {
		if l._lat != nil {
			l.LatStr = fmt.Sprint(*l._lat)
		}
		if l._lon != nil {
			l.LonStr = fmt.Sprint(*l._lon)
		}
	}
}

func (l *Location) Lat() float32 {
	if l == nil {
		return -1000
	}
	if l._lat == nil {
		v, e := strconv.ParseFloat(l.LatStr, 32)
		if e == nil {
			c := float32(v)
			l._lat = &c
		}
	}
	if l._lat == nil {
		return -1000
	}
	return *l._lat
}
func (l *Location) Lon() float32 {
	if l == nil {
		return -1000
	}
	if l._lon == nil {
		v, e := strconv.ParseFloat(l.LonStr, 32)
		if e == nil {
			c := float32(v)
			l._lon = &c
		}
	}
	if l._lon == nil {
		return -1000
	}
	return *l._lon
}
func (l *Location) TimeOffsetCorrected() string {
	if l._timeOffset == "" {
		hrsOffset, _ := strconv.ParseFloat(l.UtcOffset, 32)
		sign := "-"
		if hrsOffset > 0 {
			sign = "+"
		}
		hrsOffset = math.Abs(hrsOffset)
		hr := math.Floor(hrsOffset)
		m := math.Floor((hrsOffset - hr) * 60)
		l._timeOffset = fmt.Sprintf("%v%02d:%02d", sign, int(hr), int(m))
	}
	return l._timeOffset
}

func (l *Location) TimeZoneLocation() *time.Location {
	if l.TimeZone != "" {
		if tz, e := time.LoadLocation(l.TimeZone); e == nil && tz != nil {
			return tz
		}
	}
	return nil
}

func (l *Location) TimeWithOffset() time.Time {
	if l._time.Year() < 2000 {
		const dtOffset = "2006-01-02 15:04-07:00"
		var (
			dts = l.LocalTimeStr + l.TimeOffsetCorrected()
			tz  = l.TimeZoneLocation()
		)
		if tz != nil {
			l._time, _ = time.ParseInLocation(dtOffset, dts, tz)
		}
		if l._time.Year() < 2000 {
			l._time, _ = time.Parse(dtOffset, dts) //parse as UTC
		}
	}
	return l._time
}

type Current struct {
	TimeStr     string  `json:"observation_time"`
	Temperature float32 `json:"temperature"` //temperature in the selected unit.

	// SEE: https://weatherstack.com/site_resources/weatherstack-weather-condition-codes.zip
	Code         int      `json:"weather_code"`                   //Returns the universal weather condition code associated with the current weather condition.
	Icons        []string `json:"weather_icons,omitempty"`        //one or more PNG weather icons associated with the current weather condition.
	Descriptions []string `json:"weather_descriptions,omitempty"` //one or more weather description texts associated with the current weather condition.

	WindSpeed     float32 `json:"wind_speed"`         //wind speed in the selected unit. (Default: kilometers/hour)
	WindDegree    float32 `json:"wind_degree"`        //the wind degree.
	WindDirection string  `json:"wind_dir,omitempty"` //the wind direction. IE: NW

	Pressure      float32 `json:"pressure"`   //the air pressure in the selected unit. (Default: MB - millibar)
	Precipitation float32 `json:"precip"`     //precipitation level in the selected unit. (Default: MM - millimeters)
	Humidity      float32 `json:"humidity"`   //the air humidity level in percentage.
	CloudCover    float32 `json:"cloudcover"` //the cloud cover level in percentage.

	FeelsLike  float32 `json:"feelslike"`  //the "Feels Like" temperature in the selected unit.
	UvIndex    float32 `json:"uv_index"`   //the UV index associated with the current weather condition.
	Visibility float32 `json:"visibility"` //the visibility level in the selected unit. (Default: kilometers)
}

func (c *Current) Time() time.Duration {
	if c != nil {
		dt, e := time.Parse("03:04 PM", c.TimeStr)
		if e == nil {
			return dt.Sub(dt.Truncate(time.Hour * 24))
		}
	}
	return 0
}

func (c *Current) Temp() float32 {
	if c != nil {
		return c.Temperature
	}
	return 0
}

type Daily struct {
	DateStr      string                 `json:"date"`
	DateUnix     int64                  `json:"date_epoch"` //Returns the requested historical date as UNIX timestamp.
	Astrological map[string]interface{} `json:"astro"`      //NOTE: map this later, SEE: https://weatherstack.com/documentation#historical_weather
	MinTemp      float32                `json:"minTemp"`    //the minimum temperature of the day in the selected unit. (Default: Celsius)
	MaxTemp      float32                `json:"maxTemp"`    //the maximum temperature of the day in the selected unit. (Default: Celsius)
	AvgTemp      float32                `json:"avgTemp"`    //the average temperature of the day in the selected unit. (Default: Celsius)
	TotalSnow    float32                `json:"totalSnow"`  //the snow fall amount in the selected unit. (Default: Centimeters - cm)
	SunHour      float32                `json:"sunHour"`    //the number of sun hours.
	UvIndex      float32                `json:"uv_index"`   //the UV index associated with the current weather condition.
	Hourly       []Hourly               `json:"hourly"`     //a series of sub response objects containing hourly weather data, listed and explained in detail below.
}

type Hourly struct {
	TimeValue interface{} `json:"time"` //Returns the time as a number in 24h military time: 1:45pm == 1345, in some cases, this is returned as an INT!
	_timeStr  string

	Temperature   float32 `json:"temperature"`        //the temperature in the selected unit. (Default: Celsius)
	WindSpeed     float32 `json:"wind_speed"`         //wind speed in the selected unit. (Default: kilometers/hour)
	WindDegree    float32 `json:"wind_degree"`        //the wind degree.
	WindDirection string  `json:"wind_dir,omitempty"` //the wind direction. IE: NW

	// SEE: https://weatherstack.com/site_resources/weatherstack-weather-condition-codes.zip
	Code         int      `json:"weather_code"`                   //Returns the universal weather condition code associated with the current weather condition.
	Icons        []string `json:"weather_icons,omitempty"`        //one or more PNG weather icons associated with the current weather condition.
	Descriptions []string `json:"weather_descriptions,omitempty"` //one or more weather description texts associated with the current weather condition.

	Precipitation float32 `json:"precip"`     //precipitation level in the selected unit. (Default: MM - millimeters)
	Humidity      float32 `json:"humidity"`   //the air humidity level in percentage.
	Visibility    float32 `json:"visibility"` //the visibility level in the selected unit. (Default: kilometers)
	Pressure      float32 `json:"pressure"`   //the air pressure in the selected unit. (Default: MB - millibar)
	CloudCover    float32 `json:"cloudcover"` //the cloud cover level in percentage.
	HeatIndex     float32 `json:"heatindex"`  //the heat index temperature in the selected unit. (Default: Celsius)
	DewPoint      float32 `json:"dewpoint"`   //the dew point temperature in the selected unit. (Default: Celsius)
	WindChill     float32 `json:"windchill"`  //the wind chill temperature in the selected unit. (Default: Celsius)
	WindGus       float32 `json:"windgust"`   //wind gust speed in the selected unit. (Default: kilometers/hour)

	FeelsLike        float32 `json:"feelslike"`        //the "Feels Like" temperature in the selected unit.
	ChanceOfRain     float32 `json:"chanceofrain"`     //the chance of rain (precipitation) in percentage.
	ChanceOfWindy    float32 `json:"chanceofwindy"`    //the chance of being windy in percentage.
	ChanceOfOvercast float32 `json:"chanceofovercast"` //the chance of being overcast in percentage.
	ChanceOfSunshine float32 `json:"chanceofsunshine"` //the chance of sunshine in percentage.
	ChanceOfFrost    float32 `json:"chanceoffrost"`    // the chance of frost in percentage.
	ChanceOfHighTemp float32 `json:"chanceofhightemp"` //the chance of high temperatures in percentage.
	ChanceOfFog      float32 `json:"chanceoffog"`      //the chance of fog in percentage.
	ChanceOfSnow     float32 `json:"chanceofsnow"`     //the chance of snow in percentage.
	ChanceOfThunder  float32 `json:"chanceofthunder"`  //the chance of thunder in percentage.

	UvIndex float32 `json:"uv_index"` //the UV index associated with the current weather condition.
}

func (h *Hourly) TimeStr() string {
	if h == nil {
		return ""
	}
	if len(h._timeStr) == 0 {
		h._timeStr = fmt.Sprintf("%v", h.TimeValue)
	}
	return h._timeStr
}

func (h *Hourly) Time() (time.Duration, error) {
	var fm string
	if tl := len(h.TimeStr()); tl > 2 && tl <= 4 {
		fm = "1504"
		if tl == 3 {
			h._timeStr = "0" + h.TimeStr()
		}
	} else if tl == 2 {
		fm = "04"
	} else if tl == 1 {
		fm = "4"
	} else {
		return 0, errors.Errorf("Hourly.Time: invalid TimeStr %v", h.TimeStr())
	}
	dt, e := time.Parse(fm, h.TimeStr())
	if e == nil {
		dr := dt.Sub(dt.Truncate(time.Hour * 24))
		return dr, nil
	}
	return 0, errors.Wrapf(e, "Hourly.Time: can't decode %v using %v", h.TimeStr(), fm)
}

//weather response
type WeatherRes struct {
	Error      *WeatherErr            `json:"error,omitempty"`      //will only be presence if there is a problem, all other properties will be empty
	Request    map[string]interface{} `json:"request,omitempty"`    //what was sent in (presumably normalized)
	Location   Location               `json:"location,omitempty"`   //normalized and geo-coded location
	Current    Current                `json:"current,omitempty"`    //current weather info
	Forecast   map[string]*Daily      `json:"forecast,omitempty"`   //future weather info (only if forecast is requested)
	Historical map[string]*Daily      `json:"historical,omitempty"` //future weather info (only if forecast is requested)
}

type WeatherErr struct { //SEE: https://weatherstack.com/documentation#api_error_codes
	Code int    `json:"code,omitempty"`
	Type string `json:"type,omitempty"`
	Info string `json:"info,omitempty"`
}

//weather request
type WeatherReq struct {
	Key   string `url:"access_key"`      //api key registered with vendor, historical data requires paying plans
	Query string `url:"query"`           //used to send in City, LatLon, Zipcode (we don't use IP)
	Unit  string `url:"units,omitempty"` //m=metric, f=Fahrenheit, s=scientific. defaults to metric because vendor is UK, we always request with imperial units

	HistoricalDates []string `url:"-"`                               //Example: 2018-01-21 for a single date or 2018-01-21;2018-01-22 for multiple dates
	StartDate       string   `url:"historical_date_start,omitempty"` //Use this parameter to pass a start date for the current historical time-series request. IE: 2018-01-21
	EndDate         string   `url:"historical_date_end,omitempty"`   //Use this parameter to pass an end date for the current historical time-series request. IE: 2018-01-25
	ForecastDays    int      `url:"forecast_days,omitempty"`         //Use this parameter to specify the number of days for which the API returns forecast data. (Default: 7 or 14 days, depending on your subscription)

	Hourly   int             `url:"hourly,omitempty"`   //Set this parameter to 1 (on) or 0 (off) depending on whether or not you want the API to return weather data split hourly. (Default: 0 - off)
	Interval WeatherInterval `url:"interval,omitempty"` //SEE: WeatherInterval const

	NoCache bool `url:"-" json:"-"` //not forwarded to WSK, will ignore local redis cache if true
}

type WeatherInterval int32

const (
	WI_1HOUR     WeatherInterval = 1
	WI_DEFAULT   WeatherInterval = 3
	WI_6HOUR     WeatherInterval = 6
	WI_DAYNIGHT  WeatherInterval = 12
	WI_DAILY_AVG WeatherInterval = 24
)

func (wr *WeatherReq) setCoordinates(req *GeoCodeReq) error {
	if req.Lat >= -90 && req.Lat <= 90 && req.Lon >= -180 && req.Lon <= 180 {
		gh5 := geohash.EncodeWithPrecision(float64(req.Lat), float64(req.Lon), 5)
		lat, lon := geohash.DecodeCenter(gh5)
		wr.Query = fmt.Sprintf("%v,%v", float32(lat), float32(lon))
	} else {
		return errors.Errorf("Invalid coordinates: lat=%v, lon=%v", req.Lat, req.Lon)
	}
	return nil
}
