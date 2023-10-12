package main

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net"
	"os"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/go-errors/errors"
	"github.com/google/uuid"
)

var dateFormats []string
var macAddressRegEx *regexp.Regexp
var _nilUUID = uuid.Nil.String()

func init() {
	dateFormats = []string{
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
		macAddressRegEx = macRegEx
	}
}

func isValidMacAddress(deviceID string) bool {
	if len(deviceID) != 12 {
		return false
	}

	if macAddressRegEx == nil {
		return true
	}

	return macAddressRegEx.MatchString(deviceID)
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

	for _, f := range dateFormats {
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

func unixToTime(value int64) time.Time {
	if value < math.MaxInt32 {
		return time.Unix(value, 0)
	} else {
		return time.Unix(0, value*int64(time.Millisecond))
	}
}

func unixFloatToTime(value float64) time.Time {
	if value < math.MaxInt32 {
		return time.Unix(int64(value), 0)
	} else {
		return time.Unix(0, int64(value)*int64(time.Millisecond))
	}
}

// parseLangList parses a csv or array of locales and outputs a sorted, de-duplicated, normalized list
func parseLangList(value ...string) []string {
	if len(value) == 0 {
		return []string{}
	}

	delta := make(map[string]bool)

	for _, v := range value {
		csv := strings.Split(v, ",")
		for _, c := range csv {
			// 2 parts:  {language}-{country}
			p := strings.Split(c, "-")

			if len(p) == 1 {
				lp := strings.TrimSpace(strings.ToLower(p[0]))
				if len(lp) == 2 {
					delta[lp] = true
				}
			}

			if len(p) == 2 {
				lp := strings.TrimSpace(strings.ToLower(p[0]))
				cp := strings.TrimSpace(strings.ToLower(p[1]))
				if len(lp) == 2 && len(cp) == 2 {
					delta[lp+"-"+cp] = true
				}
			}
		}
	}
	rv := make([]string, 0)
	for k := range delta {
		rv = append(rv, k)
	}

	sort.Strings(rv)

	return rv
}

func wrapErrors(es []error) error {
	if len(es) == 0 {
		return nil
	}
	sb := strings.Builder{}
	sb.WriteString("WrappedErrors: ")
	ec := 0
	for _, e := range es {
		if e == nil {
			continue
		}
		msg := strings.TrimSpace(e.Error())
		if msg == "" || msg == "redis: nil" {
			continue
		}
		sb.WriteString(msg)
		sb.WriteString(" || ")
		ec++
	}
	if ec > 0 {
		return errors.New(sb.String())
	} else {
		return nil
	}
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
		if err != nil {
			msg = fmt.Sprintf("panicRecover: "+msg+" | ", data...)
			logFatal(msg + err.Error())
		}
	}
}
