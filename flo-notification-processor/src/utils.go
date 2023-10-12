package main

import (
	"bytes"
	"compress/gzip"
	"crypto/rand"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
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

	macAddressRegEx = regexp.MustCompile("^([a-fA-F0-9]{12})$")
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

func panicRecover(log *Logger, msg string, data ...interface{}) {
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

func RetryIfError(logic func() error, interval time.Duration, logger *Logger) {
	if logic == nil {
		return
	} else if e := logic(); e != nil {
		if logger == nil {
			logger = _log
		}
		logger.IfErrorF(e, "RetryIfError: will retry %s in %v", GetFunctionName(logic), interval)
		if interval <= 0 {
			interval = time.Second //min 1s
		}
		time.Sleep(interval)
		RetryIfError(logic, interval, logger)
	} else {
		logger.Debug("RetryIfError: %s OK!", GetFunctionName(logic))
	}
}

//convert standard error to (JSON) *HttpErr with code
func httpErrWrap(e error, httpCode int) error {
	switch et := e.(type) {
	case *HttpErr:
		if et.IsJSON {
			mv := make(map[string]interface{})
			if e := json.Unmarshal([]byte(et.Message), &mv); e == nil && len(mv) > 0 {
				unwrapJSON := func(k string, er *HttpErr) bool {
					if v, ok := mv[k]; ok && v != nil {
						if ms := fmt.Sprint(v); ms != "" {
							er.Message = ms
							er.IsJSON = false
							return true
						}
					}
					return false
				}
				if !unwrapJSON("message", et) {
					unwrapJSON("error_description", et)
				}
			}
		}
		if et.Code < 100 || et.Code >= 600 {
			et.Code = httpCode
		}
		return et //return as is
	default:
		var (
			msg    = e.Error()
			isJson = msg[0] == '{' && msg[len(msg)-1] == '}'
		)
		return &HttpErr{httpCode, msg, isJson, e}
	}
}
