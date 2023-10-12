package main

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/go-errors/errors"
	ot "github.com/opentracing/opentracing-go"
)

var _dateFormats []string
var _macAddressRegEx *regexp.Regexp

func init() {
	_dateFormats = []string{
		time.RFC3339,
		time.RFC3339Nano,
		"2006-01-02T15:04Z07:00",
		"2006-01-02T15:04:05Z",
		"2006-01-02T15:04:05",
		"2006-01-02T15:04",
		"2006-01-02",
	}

	macRegEx, err := regexp.Compile("^([a-fA-F0-9]{12})$")
	if err != nil {
		logError("macAddressRegEx error. %v", err.Error())
	} else {
		_macAddressRegEx = macRegEx
	}
}

func isValidMacAddress(deviceID string) bool {
	if len(deviceID) != 12 {
		return false
	}

	if _macAddressRegEx == nil {
		return true
	}

	return _macAddressRegEx.MatchString(deviceID)
}

// getEnvOrExit Retrieve env var - if empty/missing the process will exit
func getEnvOrExit(envVarName string) string {
	val := os.Getenv(envVarName)
	if len(val) == 0 {
		logError("Missing environment variable: %v", envVarName)
		os.Exit(-10)
		return ""
	}
	return val
}

// getEnvOrDefault Retrieve env var - if empty/missing, will return defaultValue
func getEnvOrDefault(envVarName string, defaultValue string) string {
	val := os.Getenv(envVarName)
	if len(val) == 0 {
		return defaultValue
	}
	return val
}

func newUuid() (asString string, asBytes []byte, err error) {
	uuid := make([]byte, 16)
	n, err := io.ReadFull(rand.Reader, uuid)
	if n != len(uuid) || err != nil {
		return "", nil, err
	}

	// variant bits; see section 4.1.1
	uuid[8] = uuid[8]&^0xc0 | 0x80
	// version 4 (pseudo-random); see section 4.1.3
	uuid[6] = uuid[6]&^0xf0 | 0x40

	return fmt.Sprintf("%x", uuid), uuid, nil
}

// getHostname generates hostname based on machine hostname and default external routing ip
func getHostname() string {
	rv, _ := os.Hostname()

	if len(rv) == 0 {
		rv = "unknown"
	}

	// The destination does not need to exist because it is UDP, this is a 'dummy' to create a packet
	conn, err := net.Dial("udp", "8.8.8.8:53")

	if err != nil {
		return rv + "/0.0.0.0"
	}
	defer conn.Close()

	// Retrieve the local IP that was used for sending data
	addr := conn.LocalAddr()

	if addr == nil {
		return rv + "/0.0.0.0"
	} else {
		return rv + "/" + addr.(*net.UDPAddr).IP.String()
	}
}

// tryParseDate parses date using multiple formats
func tryParseDate(dateString string) time.Time {
	if len(dateString) < 10 {
		return time.Time{}
	}

	for _, f := range _dateFormats {
		rv, err := time.Parse(f, dateString)
		if err == nil {
			return rv
		}
	}

	return time.Time{}
}

// tryToJson serialize into JSON, on error, return empty string - never error out
func tryToJson(item interface{}) string {
	if item == nil {
		return ""
	}

	j, e := json.Marshal(item)
	if e != nil {
		return ""
	}

	if len(j) < 2 {
		return ""
	}

	return string(j)
}

// parseListAndCsv parses arrays of strings and splits on comma, returns as a combined array of strings
func parseListAndCsv(arrayOfCsv []string) []string {
	cleanList := make([]string, 0)

	if len(arrayOfCsv) == 0 {
		return cleanList
	}

	for _, d := range arrayOfCsv {
		split := strings.Split(d, ",")
		for _, s := range split {
			cleanList = append(cleanList, strings.TrimSpace(s))
		}
	}

	return cleanList
}

// timeMethod used to log and trace method timing. Use it on any network/disk bound method or anything slower.
// how to use: at the beginning of method, add 'defer timeMethod("myMethodName", optional, variables, here)()'
// func createUserInDB(username string) {
//   defer timeMethod("createUserInDB")()
//   db.executeSql("insert into...")
// }
func timeMethod(funcName string, args ...interface{}) func() {
	start := time.Now()
	funcSpan := ot.StartSpan(funcName)

	return func() {
		logTrace("TIMING %s %.2f ms %v", funcName, time.Since(start).Seconds()*1000, args)
		funcSpan.Finish()
	}
}

func parseTimeMinuteMilitary(minute int) string {
	if minute <= 0 || minute >= 1440 {
		return "00:00"
	}
	delta, _ := time.Parse("2006-01-02", "1970-01-01")
	delta = delta.Add(time.Duration(minute) * time.Minute)
	return delta.Format("15:04")
}

func parseTimeString(item string) int {
	if len(item) == 0 {
		return -1
	}

	item = strings.TrimSpace(strings.ToUpper(item))

	x, e := time.Parse("15:04", item)
	if e == nil {
		return (x.Hour() * 60) + x.Minute()
	}

	x, e = time.Parse("15:04 PM", item)
	if e == nil {
		return (x.Hour() * 60) + x.Minute()
	}

	x, e = time.Parse("3:04 pm", item)
	if e == nil {
		return (x.Hour() * 60) + x.Minute()
	}

	x, e = time.Parse("15:04PM", item)
	if e == nil {
		return (x.Hour() * 60) + x.Minute()
	}

	x, e = time.Parse("15:04pm", item)
	if e == nil {
		return (x.Hour() * 60) + x.Minute()
	}

	x, e = time.Parse("15PM", item)
	if e == nil {
		return (x.Hour() * 60) + x.Minute()
	}

	x, e = time.Parse("15", item)
	if e == nil {
		return (x.Hour() * 60) + x.Minute()
	}

	return -1

}

func panicRecover(msg string, data ...interface{}) {
	r := recover()
	if r != nil {
		var err error
		switch t := r.(type) {
		case string:
			err = errors.New(t)
		case error:
			err = t
			e := errors.Wrap(err, 2)
			defer logFatal(e.ErrorStack())
		default:
			err = errors.New("Unknown error")
		}
		data = append(data, err.Error())
		logFatal("panicRecover: "+msg+" | %v", data...)
	}
}
