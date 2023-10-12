package main

import (
	"encoding/json"
	"net"
	"os"
	"reflect"
	"runtime"
	"time"

	goErrors "github.com/go-errors/errors"
	"github.com/pkg/errors"
)

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
	}
	return rv + "/" + addr.(*net.UDPAddr).IP.String()
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
			e := goErrors.Wrap(err, 2)
			defer log.Fatal(e.ErrorStack())
		default:
			err = errors.New("Unknown error")
		}
		log.IfFatalF(err, "panicRecover: "+msg, data...)
	}
}

func typeName(i interface{}) string {
	t := reflect.TypeOf(i)
	if t.Kind() == reflect.Ptr {
		return "*" + t.Elem().Name()
	}
	return t.Name()
}

func getFunctionName(i interface{}) string {
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

func retryIfError(f func() error, interval time.Duration, attemptsLeft int, log *Logger) error {
	if f == nil {
		return nil
	}

	if log == nil {
		log = _log
	}

	err := f()

	if err == nil {
		log.Trace("retryIfError: %s OK!", getFunctionName(f))
		return nil
	}

	updatedAttemptsLeft := attemptsLeft - 1
	if updatedAttemptsLeft < 0 {
		log.Error("retryIfError: no attempts left for %v - %v", getFunctionName(f), err)
		return err
	}

	if interval <= 0 {
		interval = time.Second
	}

	log.Warn("retryIfError: will retry %s in %v due to error: %v", getFunctionName(f), interval, err)

	time.Sleep(interval)
	return retryIfError(f, interval, updatedAttemptsLeft, log)
}

func decode(input, output interface{}) error {
	if input == nil {
		return errors.New("input is nil")
	}
	if output == nil {
		return errors.New("output is nil")
	}
	buf, err := json.Marshal(input)
	if err != nil {
		return err
	}
	return json.Unmarshal(buf, &output)
}
