package main

import (
	"bufio"
	"compress/gzip"
	"io"
	"math"
	"os"
	"strings"
	"time"
)

// use to read v8 .csv.gz files into []TelemetryData
type TelemetryV8 struct {
}

func (t *TelemetryV8) ReadAllFromFile(file *os.File) ([]TelemetryData, func(), error) {
	if file == nil {
		return nil, void, logWarn("TelemetryV7.ReadAllFromFile: input is nil")
	}
	if _, e := file.Seek(0, 0); e == nil { //skip to head of file
		if res, closer, e := t.ReadAllFromIO(file); e != nil {
			return nil, void, logError("TelemetryV8.ReadAllFromIO: %v => %v", file.Name(), e.Error())
		} else {
			return res, closer, nil
		}
	} else {
		logWarn("TelemetryV8.ReadAllFromFile: can't seek %v => %v", file.Name(), e.Error())
		return nil, void, e
	}
}

func void() {}

func (t *TelemetryV8) ReadAllFromIO(r io.Reader) ([]TelemetryData, func(), error) {
	logTrace("TelemetryV8.ReadAllFromIO: ENTER %v", r)
	if gzr, e := gzip.NewReader(r); e != nil { //unzip
		return nil, void, logWarn("TelemetryV8.ReadAllFromIO: can't unzip %v => %v", r, e.Error())
	} else {
		scanner := bufio.NewScanner(gzr) //new line scanner
		res := make([]TelemetryData, 0)
		for scanner.Scan() {
			line := scanner.Text()
			if csv, ok := t.unmarshalCsvRowLowRes(line); ok {
				if r, ok := t.lowResV8toLegacyV3(csv); ok {
					res = append(res, r)
				}
			}
		}
		logTrace("TelemetryV8.ReadAllFromIO: EXIT OK %v => %v rows", r, len(res))
		return res, func() { gzr.Close() }, nil
	}
}

func (_ *TelemetryV8) lowResV8toLegacyV3(o csvRowLowRes) (TelemetryData, bool) {
	ts := time.Unix(0, o.TimeStamp*int64(time.Millisecond)).UTC() // in nano sec
	ts = ts.Truncate(time.Second)

	r := TelemetryData{}
	if ts.Unix() <= 0 {
		return r, false
	}

	r.MacAddress = o.DeviceId
	r.Timestamp = ts.UnixNano() / int64(time.Millisecond)
	r.TempF = o.Temperature
	r.SystemMode = int(o.SystemMode)
	r.ValveState = int(o.ValveState)
	//r.WiFiStrength = 0 // should already be 0. We are no longer sending this in v8 anyway
	r.PSI = o.Pressure // should already be in PSI
	r.GPM = o.FlowRate // should already by in GPM
	r.UseGallons = r.GPM / 60

	return r, true
}

// Schema v8 LowRes format per csv row/line
type csvRowLowRes struct {
	DeviceId    string
	TimeStamp   int64 //epoch timestamp in ms
	SystemMode  int32
	ValveState  int32
	Temperature float32 // in F, no decimal per spec & 10x the actual value
	Pressure    float32
	FlowRate    float32
}

//take a single csv line & convert data back to a single CsvRowLowRes entry
// SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-2599
func (_ *TelemetryV8) unmarshalCsvRowLowRes(line string) (csvRowLowRes, bool) {
	c := strings.SplitN(line, ",", 7) // format: did,ts,sm,v,t,p,fr
	r := csvRowLowRes{}
	rowsOK := 0
	var ok bool
	if c != nil && len(c) >= 7 && isValidMacAddress(c[0]) { // not useful if first 2 items are missing
		r.DeviceId = c[0]
		r.TimeStamp, ok = tryParseInt64(c[1])
		if ok {
			rowsOK++
		}
		r.SystemMode, ok = tryParseInt32(c[2])
		if ok {
			rowsOK++
		}
		r.ValveState, ok = tryParseInt32(c[3])
		if ok {
			rowsOK++
		}
		r.Temperature, ok = tryParseFloat32(c[4]) //spec said no decimal but v3 is decimal so passing as is
		if ok {
			rowsOK++
		}
		psi, ok := tryParseFloat32(c[5]) //spec said value is 10x PSI so we have to divide by 10
		if ok {
			r.Pressure = float32(math.Floor(float64(psi)) / 10)
			rowsOK++
		}
		r.FlowRate, ok = tryParseFloat32(c[6])
		if ok {
			rowsOK++
		}
		if rowsOK >= 6 {
			return r, true //only return ok true if all cells are good
		}
	}
	return r, false //falls through as invalid
}
