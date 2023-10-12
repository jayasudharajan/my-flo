package main

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-errors/errors"
	"github.com/google/uuid"
	"github.com/spaolacci/murmur3"
)

var macAddressRegEx *regexp.Regexp

func init() {

	macRegEx, err := regexp.Compile("^([a-fA-F0-9]{12})$")
	if err != nil {
		logError("macAddressRegEx error. %v", err.Error())
	} else {
		macAddressRegEx = macRegEx
	}
}

// FindRequestBodyEmptyFields finds request body empty fields among the enforced ones
func FindRequestBodyEmptyFields(d interface{}, enforcedJSONFields map[string]interface{}) []string {
	v := reflect.ValueOf(d)
	var emptyJSONFields []string
	for i := 0; i < v.Type().NumField(); i++ {
		fieldName := v.Type().Field(i).Name
		tag := v.Type().Field(i).Tag.Get("json")
		if _, ok := enforcedJSONFields[tag]; ok {
			val := reflect.Indirect(v).FieldByName(fieldName)
			// what if it's not string?
			if val.String() == EmptyString {
				emptyJSONFields = append(emptyJSONFields, tag)
			}
		}
	}
	return emptyJSONFields
}

// GenerateUuid generates UUID string
func GenerateUuid() (string, error) {
	return uuid.New().String(), nil
}

func ContainsInt(elements []int, element int) bool {
	for _, e := range elements {
		if e == element {
			return true
		}
	}
	return false
}

// getEnvOrDefault Retrieve env var - if empty/missing, will return defaultValue
func getEnvOrDefault(envVarName string, defaultValue string) string {
	val := os.Getenv(envVarName)
	if len(val) == 0 {
		return defaultValue
	}
	return val
}

func mergeMap(source map[string]interface{}, target map[string]interface{}) map[string]interface{} {
	if len(source) == 0 {
		return target
	}

	if target == nil {
		target = make(map[string]interface{})
	}

	for k, v := range source {
		target[k] = v
	}

	return target
}

func toJson(item interface{}) string {
	if item == nil {
		return "{ \"_error\" : \"nil\" }"
	}

	b, e := json.Marshal(item)

	if e != nil {
		return "{ \"_error\" : \"" + e.Error() + "\" }"
	}

	return string(b)
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

// This is slow and only works on first level properties - improve it if you wish - AlexZ
func getFilteredProperties(item interface{}, fieldCsv string) interface{} {
	defer func(start time.Time) {
		logTrace("getFilteredProperties: %v %v", time.Now().Sub(start).Seconds()*1000, fieldCsv)
	}(time.Now())

	// Bail early if possible
	if item == nil || len(fieldCsv) == 0 || strings.Contains(fieldCsv, "*") || strings.Contains(fieldCsv, "_all") {
		return item
	}

	// Check for bad data, bunch of commas
	fieldList := strings.Split(fieldCsv, ",")
	if len(fieldList) == 0 {
		return item
	}

	any := false
	for _, f := range fieldList {
		propName := strings.TrimSpace(f)
		if len(propName) > 0 {
			any = true
		}
	}
	if !any {
		return item
	}

	// Object -> JSON -> MAP
	src := make(map[string]interface{})
	j, e := json.Marshal(item)
	if e != nil {
		return item
	}
	e = json.Unmarshal(j, &src)
	if e != nil {
		return item
	}

	rv := make(map[string]interface{})
	for _, f := range fieldList {
		propName := strings.TrimSpace(f)

		v := src[propName]
		if v != nil {
			rv[propName] = v
		}
	}

	// If you selected field(s) that all don't exist, return full object
	if len(rv) == 0 {
		return item
	}

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

func Str(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func boolPtr(b string) (*bool, error) {
	if b == EmptyString {
		return nil, nil
	}
	p, err := strconv.ParseBool(b)
	return &p, err
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

func isValidMacAddress(deviceID string) bool {
	if len(deviceID) != 12 {
		return false
	}

	if macAddressRegEx == nil {
		return true
	}

	return macAddressRegEx.MatchString(deviceID)
}
