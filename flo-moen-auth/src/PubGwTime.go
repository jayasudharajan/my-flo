package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var (
	_defaultDate = time.Time{}
	_offsetTzRe  = regexp.MustCompile("[+-][0-9]{2}:[0-9]{2}$")
)

func tryParseTime(date string) time.Time {
	if date == "" {
		return _defaultDate
	}
	for _, x := range _dateFormats {
		dt, err := time.Parse(x, date)
		if err == nil {
			return dt
		}
	}
	return _defaultDate
}

var _dateFormats = []string{
	"2006-01-02T15:04:05.9999999Z0700",
	"2006-01-02T15:04:05.9999999",
	"2006-01-02T15:04:05.9Z0700",
	"2006-01-02T15:04:05Z0700",
	"2006-01-02T15:04Z0700",
	"2006-01-02T15Z0700",
	"2006-01-02 15:04:05.9999999Z0700",
	"2006-01-02 15:04:05.9999999",
	"2006-01-02 15:04:05.9Z0700",
	"2006-01-02 15:04:05Z0700",
	"2006-01-02 15:04Z0700",
	"2006-01-02 15Z0700",
	"2006-01-02Z0700",
	"2006-01-02T15:04:05.9",
	"2006-01-02T15:04:05",
	"2006-01-02T15:04",
	"2006-01-02T15",
	"2006-01-02 15:04:05.9",
	"2006-01-02 15:04:05",
	"2006-01-02 15:04",
	"2006-01-02 15",
	"2006-01-02",
	"2006-01-02T15:04:05.9PM",
	"2006-01-02T15:04:05.9pm",
	"2006-01-02T15:04:05PM",
	"2006-01-02T15:04:05pm",
	"2006-01-02T15:04PM",
	"2006-01-02T15:04pm",
	"2006-01-02T15PM",
	"2006-01-02T15pm",
	"2006-01-02 15:04:05.9PM",
	"2006-01-02 15:04:05.9pm",
	"2006-01-02 15:04:05PM",
	"2006-01-02 15:04:05pm",
	"2006-01-02 15:04PM",
	"2006-01-02 15:04pm",
	"2006-01-02 15PM",
	"2006-01-02 15pm",
	"01/02/2006 15:04:05.9PM",
	"01/02/2006 15:04:05.9",
	"01/02/2006 15:04:05PM",
	"01/02/2006 15:04:05",
	"01/02/2006 15:04PM",
	"01/02/2006 15:04",
	"01/02/2006 15PM",
	"01/02/2006 15",
	"01/02/2006T15:04:05.9PM",
	"01/02/2006T15:04:05.9",
	"01/02/2006T15:04:05PM",
	"01/02/2006T15:04:05",
	"01/02/2006T15:04PM",
	"01/02/2006T15:04",
	"01/02/2006T15PM",
	"01/02/2006T15",
	"01/02/2006Z",
	"01/02/2006"}

type PubGwTime time.Time

const (
	TIME_FMT_NO_TZ     = "2006-01-02T15:04:05"
	TIME_FMT_TZ_OFFSET = "2006-01-02T15:04:05-07:00"
)

// UnmarshalJSON Parses the json string in the custom format
func (ct *PubGwTime) UnmarshalJSON(b []byte) (err error) {
	defer panicRecover(_log, "PubGwTime.UnmarshalJSON: %s", b)

	s := strings.Trim(string(b), `"`)
	if s == "" {
		*ct = PubGwTime{}
		return
	}

	var nt time.Time
	if offset := string(_offsetTzRe.Find([]byte(s))); offset != "" {
		var (
			hh, _ = strconv.ParseInt(offset[0:3], 10, 64)
			mm, _ = strconv.ParseInt(offset[4:5], 10, 64)
			sec   = (hh * 60 * 60) + (mm * 60)
			loc   = time.UTC
		)
		if sec != 0 {
			loc = time.FixedZone(offset, int(sec))
		}
		if nt, err = time.ParseInLocation(TIME_FMT_TZ_OFFSET, s, loc); err != nil {
			nt = tryParseTime(s)
		}
	} else {
		s = strings.Trim(s, `Z.`)
		if nt, err = time.Parse(TIME_FMT_NO_TZ, s); err != nil {
			nt = tryParseTime(s)
		}
	}
	if nt != _defaultDate && err != nil {
		err = nil
	}
	*ct = PubGwTime(nt)
	return
}

// MarshalJSON writes a quoted string in the custom format
func (ct PubGwTime) MarshalJSON() ([]byte, error) {
	if dt := ct.Time(); dt.IsZero() {
		return []byte(`""`), nil
	} else {
		var str string
		if ln := dt.Location().String(); ln != time.UTC.String() {
			str = fmt.Sprintf("%q", ct.Format(TIME_FMT_TZ_OFFSET))
		} else {
			str = fmt.Sprintf("%q", ct.String())
		}
		return []byte(str), nil
	}
}

// String returns the time in the custom format
func (ct PubGwTime) String() string {
	return ct.Format(TIME_FMT_NO_TZ + ".000000")
}

func (ct *PubGwTime) Format(fmtStr string) string {
	if ct == nil {
		return time.Time{}.Format(fmtStr)
	}
	t := time.Time(*ct)
	return t.Format(fmtStr)
}

func (ct *PubGwTime) Time() time.Time {
	if ct == nil {
		return time.Time{}
	}
	return time.Time(*ct)
}

func (ct *PubGwTime) UTC() time.Time {
	return ct.Time().UTC()
}
