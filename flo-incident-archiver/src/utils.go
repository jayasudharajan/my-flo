package main

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"errors"
	"os"
	"reflect"
	"runtime"
	"strings"
	"time"
)

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
		return nil, logError("toGzip: Write | %v", e)
	}
	e = zw.Close()
	if e != nil {
		return nil, logWarn("toGzip: Close | %v", e)
	}
	return zBuf.Bytes(), nil
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

func RetryIfError(f func() error, interval time.Duration, attemptsLeft int) error {
	if f == nil {
		return errors.New("RetryIfError: empty function")
	}

	if interval <= 0 {
		interval = time.Second //min 1s
	}

	err := f()
	if err == nil {
		logTrace("RetryIfError: %s OK!", GetFunctionName(f))
		return nil
	}

	updatedAttemptsLeft := attemptsLeft - 1
	if updatedAttemptsLeft < 0 {
		logError("RetryIfError: no retries left for %v - %v", GetFunctionName(f), err)
		return err
	}

	logWarn("RetryIfError: will retry %s in %v due to error: %v", GetFunctionName(f), interval, err)

	time.Sleep(interval)
	return RetryIfError(f, interval, updatedAttemptsLeft)
}
