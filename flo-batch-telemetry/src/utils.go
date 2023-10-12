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
	"math"
	"net"
	"net/url"
	"os"
	"reflect"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/go-errors/errors"
	"github.com/spaolacci/murmur3"
)

var macAddressRegEx *regexp.Regexp

func init() {
	macRegEx, err := regexp.Compile("^([a-fA-F0-9]{12})$")
	if err != nil {
		logError("macAddressRegEx error. %v", err.Error())
		return
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
	if addr := conn.LocalAddr(); addr == nil {
		return rv + "/0.0.0.0"
	} else {
		return rv + "/" + addr.(*net.UDPAddr).IP.String()
	}
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

func unEscapeUrlPath(path string) string {
	if len(path) == 0 {
		return ""
	}

	if strings.Contains(path, "%") {
		k, e := url.PathUnescape(path)
		if e != nil {
			logWarn("unEscapeUrlPath: %v %v", path, e.Error())
		}
		return k
	} else {
		return path
	}
}

// attempt to parse a string to int32, will not throw
func tryParseInt32(s string) (n int32, ok bool) {
	v, e := strconv.ParseInt(s, 0, 32)
	if e != nil {
		return 0, false
	} else {
		return int32(v), true
	}
}

// attempt to parse a string down to int64, will not throw
func tryParseInt64(s string) (n int64, ok bool) {
	v, e := strconv.ParseInt(s, 0, 64)
	if e != nil {
		return 0, false
	} else {
		return v, true
	}
}

// attempt to parse a string down to float32, will not throw
func tryParseFloat32(s string) (n float32, ok bool) {
	v, e := strconv.ParseFloat(s, 32)
	if e != nil {
		return 0, false
	} else {
		return float32(v), true
	}
}

// return the larger float32 and the first one if equal
func maxFloat32(a float32, b float32) float32 {
	if a >= b {
		return a
	} else {
		return b
	}
}

// return the smaller float32 and the first one if equal
func minFloat32(a float32, b float32) float32 {
	if a <= b {
		return a
	} else {
		return b
	}
}

// return the smaller float32 except for when it's less than 0
func minPositiveFloat32(a float32, b float32) float32 {
	if a <= 0 || b <= 0 {
		if a <= 0 {
			return b
		} else {
			return a
		}
	} else {
		return minFloat32(a, b)
	}
}

// round the float 32 to the nearest provided decimal
func roundNearFloat32(num float32, dec int32) float32 {
	if num == 0 {
		return 0
	}
	if dec < 1 {
		return num
	}
	mul := math.Pow(10, float64(dec))
	v := math.Round(float64(num)*mul) / mul
	return float32(v)
}

func ensureDirPermissionOK(path string) error {
	if pl := len(path); pl > 1 && path[pl-1:pl] == "/" {
		path = string([]byte(path[0 : pl-1])) //leak prevention, SEE: https://go101.org/article/memory-leaking.html
	}
	if _, err := os.Stat(path); os.IsNotExist(err) {
		err = os.MkdirAll(path, os.ModePerm)
		if err != nil {
			return logError("ensureDirPermissionOK: can not create workDir @ %v => %v", path, err.Error())
		}
	}
	uuid, _, _ := newUuid()
	fn := fmt.Sprintf("%v/%v.txt", path, uuid)
	if file, e := os.Create(fn); e != nil {
		return logError("ensureDirPermissionOK: can not create file @ %v => %v", fn, e.Error())
	} else {
		defer func(f *os.File, path string) {
			if f != nil {
				f.Close()
				f = nil
			}
			if fn != "" {
				os.Remove(fn)
			}
		}(file, fn)

		if _, e := file.WriteString("testing"); e != nil {
			return logError("ensureDirPermissionOK: can not write file @ %v => %v", fn, e.Error())
		} else if e := file.Sync(); e != nil {
			return logError("ensureDirPermissionOK: can not sync file @ %v => %v", fn, e.Error())
		} else if _, e := file.Seek(0, 0); e != nil {
			return logError("ensureDirPermissionOK: can not seek file @ %v => %v", fn, e.Error())
		} else {
			arr := make([]byte, 1)
			if _, e := file.Read(arr); e != nil {
				return logError("ensureDirPermissionOK: can not read file @ %v => %v", fn, e.Error())
			} else if e := file.Close(); e != nil {
				return logError("ensureDirPermissionOK: can not close file @ %v => %v", fn, e.Error())
			} else if e := os.Remove(fn); e != nil {
				return logError("ensureDirPermissionOK: can not remove file @ %v => %v", fn, e.Error())
			}
		}
	}
	return nil
}

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

//murmur v3 128bit
func mh3(v interface{}) (s string, err error) {
	var buf []byte
	if v == nil {
		buf = []byte("{}")
	} else {
		buf, err = json.Marshal(v)
	}
	return mh3Bytes(buf)
}

func mh3Bytes(buf []byte) (s string, err error) {
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
			defer log.Fatal("panicRecover: %v", e.ErrorStack())
		default:
			err = errors.New("Unknown error")
		}
		log.IfFatalF(err, "panicRecover: "+msg, data...)
	}
}

func FunctionName(i interface{}) string {
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
	jBuf, e := fromGzip(buf)
	if e == nil {
		e = json.Unmarshal(jBuf, &v)
	}
	return e
}

func RetryIfError(logic func() error, interval time.Duration, logger *Logger) {
	if logic == nil {
		return
	} else if e := logic(); e != nil {
		if logger == nil {
			logger = _log
		}
		logger.IfErrorF(e, "RetryIfError: will retry %s in %v", FunctionName(logic), interval)
		if interval <= 0 {
			interval = time.Second //min 1s
		}
		time.Sleep(interval)
		RetryIfError(logic, interval, logger)
	} else {
		logger.Debug("RetryIfError: %s OK!", FunctionName(logic))
	}
}

func int64Ptr(p *int64) int64 {
	if p == nil {
		return 0
	}
	return *p
}

func strPtr(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func boolPtr(b *bool) bool {
	if b == nil {
		return false
	}
	return *b
}
