package main

import (
	"crypto/rand"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net"
	"net/url"
	"os"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/spaolacci/murmur3"

	"github.com/go-errors/errors"
)

var dateFormats []string = []string{
	time.RFC3339,
	time.RFC3339Nano,
	"2006-01-02T15:04Z07:00",
	"2006-01-02T15:04:05Z",
	"2006-01-02T15:04:05",
	"2006-01-02T15:04",
	"2006-01-02",
}

var macAddressRegEx *regexp.Regexp = regexp.MustCompile("^([a-fA-F0-9]{12})$")

func isValidMacAddress(deviceID string) bool {
	if len(deviceID) != 12 {
		return false
	}
	if macAddressRegEx == nil {
		return true
	}
	return macAddressRegEx.MatchString(deviceID)
}

// getEnvOrExit: Retrieve env var - if empty/missing the process will exit
func getEnvOrExit(envVarName string) string {
	val := os.Getenv(envVarName)
	if len(val) == 0 {
		logError("Missing environment variable: %v", envVarName)
		os.Exit(-10)
		return ""
	}
	return val
}

func macAddressSimpleFormat(macAddress string) string {
	return strings.ReplaceAll(macAddress, ":", "")
}

// getEnvOrDefault: Retrieve env var - if empty/missing, will return defaultValue
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

func tryParseDurationEnv(env string, defv string) (time.Duration, bool) {
	durEnv := getEnvOrDefault(env, defv)
	rd, e := time.ParseDuration(durEnv)
	if e != nil {
		logWarn("tryParseDurationEnv: bad env durration %v=%v", env, durEnv)
		return 0, false
	}
	return rd, true
}

func cleanFloat(v float64) float64 {
	return round64(v, 3)
}

func round64(n, d float64) float64 {
	m := math.Pow(10, d)
	return math.Round(n*m) / m
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

//generic recovery method good for any situation
func recoverPanic(log *Logger, msg string, data ...interface{}) {
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

func tryClose(c ICloser, log *Logger, ctx int) {
	if c == nil {
		return
	}
	n := TypeName(c)
	defer recoverPanic(log, "tryClose %v", n)
	log.Debug("tryClosing #%v %v", ctx, n)
	c.Close()
}

func TypeName(i interface{}) string {
	if t := reflect.TypeOf(i); t.Kind() == reflect.Ptr {
		return "*" + t.Elem().Name()
	} else {
		return t.Name()
	}
}
