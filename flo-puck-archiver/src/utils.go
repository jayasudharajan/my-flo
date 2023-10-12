package main

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	ot "github.com/opentracing/opentracing-go"
)

var dateFormats []string
var macAddressRegEx *regexp.Regexp

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
		_log.Error("macAddressRegEx error. %v", err.Error())
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
		_log.Error("Missing environment variable: %v", envVarName)
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
		_log.Trace("TIMING %s %.2f ms %v", funcName, time.Since(start).Seconds()*1000, args)
		funcSpan.Finish()
	}
}

const (
	TB = 1000000000000
	GB = 1000000000
	MB = 1000000
	KB = 1000
)

func lenReadable(length int, decimals int) (out string) {
	var unit string
	var i int
	var remainder int

	// Get whole number, and the remainder for decimals
	if length > TB {
		unit = "TB"
		i = length / TB
		remainder = length - (i * TB)
	} else if length > GB {
		unit = "GB"
		i = length / GB
		remainder = length - (i * GB)
	} else if length > MB {
		unit = "MB"
		i = length / MB
		remainder = length - (i * MB)
	} else if length > KB {
		unit = "KB"
		i = length / KB
		remainder = length - (i * KB)
	} else {
		return strconv.Itoa(length) + " B"
	}

	if decimals == 0 {
		return strconv.Itoa(i) + " " + unit
	}

	// This is to calculate missing leading zeroes
	width := 0
	if remainder > GB {
		width = 12
	} else if remainder > MB {
		width = 9
	} else if remainder > KB {
		width = 6
	} else {
		width = 3
	}

	// Insert missing leading zeroes
	remainderString := strconv.Itoa(remainder)
	for iter := len(remainderString); iter < width; iter++ {
		remainderString = "0" + remainderString
	}
	if decimals > len(remainderString) {
		decimals = len(remainderString)
	}

	return fmt.Sprintf("%d.%s %s", i, remainderString[:decimals], unit)
}

func chunks(xs []string, chunkSize int) [][]string {
	if len(xs) == 0 {
		return nil
	}
	divided := make([][]string, (len(xs)+chunkSize-1)/chunkSize)
	prev := 0
	i := 0
	till := len(xs) - chunkSize
	for prev < till {
		next := prev + chunkSize
		divided[i] = xs[prev:next]
		prev = next
		i++
	}
	divided[i] = xs[prev:]
	return divided
}
