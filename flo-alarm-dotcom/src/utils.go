package main

import (
	"bytes"
	"compress/gzip"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
	"os"
	"reflect"
	"regexp"
	"runtime"
	"strings"
	"time"

	"github.com/go-errors/errors"
	"github.com/spaolacci/murmur3"
)

const (
	DUR_1_DAY = time.Hour * 24
	DUR_4_HRS = time.Hour * 4
	DUR_1_HR  = time.Hour * 1
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
		_log.Error("macAddressRegEx error. %v", err)
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
		_log.Fatal("Missing environment variable: %v", envVarName)
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
			mh.Reset()
			arr := make([]byte, 16)
			binary.LittleEndian.PutUint64(arr[0:8], a)
			binary.LittleEndian.PutUint64(arr[8:16], b)
			s := fmt.Sprintf("%x", arr)
			arr = nil
			return s, nil
		}
	}
	return "", err
}

func tryClose(c OpenCloser, log Log, ctx int) {
	if c == nil {
		return
	}
	defer panicRecover(log, "tryClose %v", c)
	log.Debug("tryClosing #%v %p %s", ctx, c, TypeName(c))
	c.Close()
}

func panicRecover(log Log, msg string, data ...interface{}) {
	r := recover()
	if r != nil {
		var err error
		switch t := r.(type) {
		case string:
			err = errors.New(t)
		case error:
			err = t
			e := errors.Wrap(err, 2)
			defer log.Fatal(e.ErrorStack())
		default:
			err = errors.New("Unknown error")
		}
		log.IfFatalF(err, "panicRecover: "+msg, data...)
	}
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

func jsonMap(input, output interface{}) error {
	if input == nil {
		return errors.New("input is nil")
	} else if output == nil {
		return errors.New("output is nil")
	} else if buf, e := json.Marshal(input); e != nil {
		return e
	} else {
		return json.Unmarshal(buf, &output)
	}
}

func EpochToTime(ts int64) time.Time {
	return time.Unix(0, (time.Duration(ts) * time.Millisecond).Nanoseconds())
}

func GetFunctionName(i interface{}) string {
	if i == nil {
		return "<nil>"
	} else if p := reflect.ValueOf(i).Pointer(); p == 0 {
		return "<nil>"
	} else if f := runtime.FuncForPC(p); f == nil {
		return "<nil>"
	} else {
		return f.Name()
	}
}

func TypeName(i interface{}) string {
	if t := reflect.TypeOf(i); t.Kind() == reflect.Ptr {
		return "*" + t.Elem().Name()
	} else {
		return t.Name()
	}
}

func RetryIfError(logic func() error, interval time.Duration, logger Log) error {
	if logger == nil {
		logger = _log
	}
	if logic == nil {
		return logger.Error("RetryIfError: no logic provided")
	}
	if e := logic(); e != nil {
		logger.IfErrorF(e, "RetryIfError: will retry %s in %v", GetFunctionName(logic), interval)
		const minInterval = time.Millisecond * 100
		if interval < minInterval {
			interval = minInterval //min duration
		}
		time.Sleep(interval)
		return RetryIfError(logic, interval, logger)
	} else {
		logger.Debug("RetriesIfError: %s OK!", GetFunctionName(logic))
		return nil
	}
}

func RetriesIfError(logic func() error, interval time.Duration, maxTries int32, logger Log) error {
	if logger == nil {
		logger = _log
	}
	if logic == nil {
		return logger.Error("RetriesIfError: no logic provided")
	}
	if maxTries < 0 {
		return logger.Error("RetriesIfError: maxTries exceeded")
	}
	if e := logic(); e != nil {
		logger.IfErrorF(e, "RetriesIfError: will retry %s in %v %v more time", GetFunctionName(logic), interval, maxTries)
		const minInterval = time.Millisecond * 100
		if interval < minInterval {
			interval = minInterval //min duration
		}
		time.Sleep(interval)
		return RetriesIfError(logic, interval, maxTries-1, logger)
	} else {
		logger.Debug("RetriesIfError: %s OK! %v retries left", GetFunctionName(logic), maxTries)
		return nil
	}
}

func IfTrue(tf bool, t, f interface{}) interface{} {
	if tf {
		return t
	} else {
		return f
	}
}

const FAKE_JWT_SUM = "**********"

func CleanToken(jwt string) string {
	if arr := strings.Split(jwt, "."); len(arr) == 3 {
		arr[2] = FAKE_JWT_SUM
		return strings.Join(arr, ".")
	}
	return jwt
}

func Str(s *string) string {
	if s == nil {
		return ""
	} else {
		return *s
	}
}

func Bool(b *bool) bool {
	if b == nil {
		return false
	}
	return *b
}

func AlphaNumOnly(s []byte) []byte {
	n := 0
	for _, b := range s {
		if ('a' <= b && b <= 'z') ||
			('A' <= b && b <= 'Z') ||
			('0' <= b && b <= '9') ||
			b == ' ' {
			s[n] = b
			n++
		}
	}
	return s[:n]
}

func AppendKeyBranch(key, commit string, isDebug bool) string {
	branch := strings.ToLower(commit)
	switch branch {
	case "master", "dev":
		break
	default:
		key = fmt.Sprintf("%s:%s", key, AlphaNumOnly([]byte(branch)))
		break
	}
	if isDebug {
		key += "_"
	}
	return key
}

func httpCodeToRing(code int) string {
	switch code {
	case 400:
		return "INVALID_DIRECTIVE"
	case 401:
		return "INVALID_AUTHORIZATION_CREDENTIAL"
	case 403:
		return "INVALID_SCOPE"
	case 404:
		return "NO_SUCH_ENDPOINT"
	case 409:
		return "ALREADY_IN_OPERATION"
	case 410:
		return "NO_SUCH_ENDPOINT"
	case 419:
		return "EXPIRED_AUTHORIZATION_CREDENTIAL"
	case 502:
		return "BRIDGE_UNREACHABLE"
	case 524, 598:
		return "ENDPOINT_BUSY"
	case 510:
		return "CLOUD_CONTROL_DISABLED"
	case 504, 521, 523:
		return "ENDPOINT_UNREACHABLE"
	default: //500
		return "INTERNAL_ERROR"
	}
}

func ensureJwtBearer(jwt string) string {
	if jwt == "" {
		return ""
	} else if bc := strings.Count(jwt, "Bearer "); bc == 1 {
		return jwt
	} else if bc == 0 {
		return "Bearer " + jwt
	} else { //more than once!
		return strings.Replace(jwt, "Bearer ", "", bc-1)
	}
}

func ClampInt64(n, min, max int64) int64 {
	if max < min {
		min, max = max, min
	}
	if n < min {
		return min
	} else if n > max {
		return max
	} else {
		return n
	}
}
