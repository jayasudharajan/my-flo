package main

import (
	"bytes"
	"compress/gzip"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"math"
	"net"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/spaolacci/murmur3"

	"github.com/go-errors/errors"

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
		logFatal("Missing environment variable: %v", envVarName)
		signalExit()
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

func timeMethod(funcName string, args ...interface{}) func() {
	start := time.Now()
	funcSpan := ot.StartSpan(funcName)

	return func() {
		logTrace("TIMING %s %.2f ms %v", funcName, time.Since(start).Seconds()*1000, args)
		funcSpan.Finish()
	}
}

func strJoinIfNotEmpty(sep string, args ...string) string {
	if l := len(args); l > 0 {
		arr := make([]string, 0, l)
		for i := 0; i < l; i++ {
			if s := args[i]; len(s) != 0 {
				arr = append(arr, s)
			}
		}
		if len(arr) != 0 {
			return strings.Join(arr, sep)
		}
	}
	return ""
}

var _extractIntRe *regexp.Regexp

func init() {
	_extractIntRe = regexp.MustCompile(`[1-9][0-9]*`)
}
func extractInt(s string) (int, error) {
	if len(s) == 0 {
		return 0, errors.New("Empty input")
	}
	b := _extractIntRe.Find([]byte(s))
	bs := string(b)
	return strconv.Atoi(bs)
}

//murmur v3 128bit
func mh3(v interface{}) (s string, err error) {
	var buf []byte
	if v == nil {
		buf = []byte("{}")
	} else {
		buf, err = json.Marshal(v)
	}
	if err == nil {
		mh := murmur3.New128()
		if _, err = mh.Write(buf); err == nil {
			a, b := mh.Sum128()
			return fmt.Sprintf("%x:%x", a, b), nil
		}
	}
	return "", err
}

//serialize json.gz
func jsonMarshalGz(v interface{}) (buf []byte, err error) {
	if buf, err = json.Marshal(v); err == nil {
		var res []byte
		res, err = toGzip(buf)
		if err == nil {
			return res, nil
		} else if strings.Contains(err.Error(), "Close") {
			return res, nil
		} else {
			return nil, err
		}
	}
	return buf, err
}

func toGzip(buf []byte) (res []byte, err error) {
	zBuf := &bytes.Buffer{}
	zw := gzip.NewWriter(zBuf)
	_, e := zw.Write(buf)
	if e != nil { //fall back to regular json
		return nil, _log.Error("toGzip Write | %v", e.Error())
	}
	e = zw.Close()
	if e != nil {
		return nil, _log.Warn("toGzip Close | %v", e.Error())
	}
	return zBuf.Bytes(), nil
}

func fromGzip(zbuf []byte) (res []byte, err error) {
	rb := bytes.NewBuffer(zbuf)
	zr, e := gzip.NewReader(rb)
	defer zr.Close()
	if e != nil {
		return nil, _log.Error("fromGzip Open | %v", e.Error())
	}
	arr, e := ioutil.ReadAll(zr)
	if e != nil {
		return nil, _log.Error("fromGzip Read | %v", e.Error())
	}
	return arr, nil
}

func jsonUnMarshalGz(buf []byte, v interface{}) (err error) {
	jbuf, e := fromGzip(buf)
	if e == nil {
		e = json.Unmarshal(jbuf, &v)
	}
	return e
}

func timeSecBucket(sec int64, bucketSec int64) int64 {
	if bucketSec < 2 {
		return sec
	}
	return sec - (sec % bucketSec)
}

var BOUND_REF_NIL = errors.New("bounded reference is nil")

func fmtDuration(d time.Duration) string {
	d = d.Round(time.Second)
	h := d / time.Hour
	d -= h * time.Hour
	m := d / time.Minute
	d -= m * time.Minute
	s := d / time.Second
	if m < 0 {
		m *= -1
	}
	if s < 0 {
		s *= -1
	}

	return fmt.Sprintf("%02d:%02d:%02d", h, m, s)
}

func uniqueStr(arr []string) []string {
	m := make(map[string]bool)
	for _, s := range arr {
		m[s] = true
	}
	res := make([]string, len(m))
	i := 0
	for k, _ := range m {
		res[i] = k
		i++
	}
	return res
}

func tempFtoC(f float32) (c float32) {
	return float32(math.Round((float64(f)-32)*100/1.8) / 100)
}

func panicRecover(log *Logger, msg string, data ...interface{}) {
	r := recover()
	if r != nil {
		var err error
		switch t := r.(type) {
		case string:
			err = errors.New(t)
		case error:
			err = t
			if dump := errors.Wrap(err, 2).ErrorStack(); dump != "" {
				defer log.Fatal("panicRecover: STACK_DUMP => %v", dump)
			}
		default:
			err = errors.New("Unknown error")
		}
		log.IfFatalF(err, "panicRecover: "+msg, data...)
	}
}
