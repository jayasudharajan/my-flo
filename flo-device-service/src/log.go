package main

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"time"
)

const logPrefix string = "device-svc: "

var _logMinLevel = 0

func init() {
	_logMinLevel, _ = strconv.Atoi(getEnvOrDefault("DS_LOG_MIN_LEVEL", "0"))
}

func logFatal(format string, args ...interface{}) error {
	e := errors.New(logPrefix + fmt.Sprintf(format, args...))
	if _logMinLevel > 6 {
		return e
	}
	_, _ = os.Stderr.WriteString(time.Now().UTC().Format(time.RFC3339) + " FATAL " + e.Error() + "\n")
	return e
}

func logError(format string, args ...interface{}) error {
	e := errors.New(logPrefix + fmt.Sprintf(format, args...))
	if _logMinLevel > 5 {
		return e
	}
	_, _ = os.Stderr.WriteString(time.Now().UTC().Format(time.RFC3339) + " ERROR " + e.Error() + "\n")
	return e
}

func logWarn(format string, args ...interface{}) error {
	e := errors.New(logPrefix + fmt.Sprintf(format, args...))
	if _logMinLevel > 4 {
		return e
	}
	_, _ = os.Stderr.WriteString(time.Now().UTC().Format(time.RFC3339) + " WARN " + e.Error() + "\n")
	return e
}

func logNotice(format string, args ...interface{}) {
	if _logMinLevel > 3 {
		return
	}
	msg := time.Now().UTC().Format(time.RFC3339) + " NOTICE " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stderr.WriteString(msg)
}

func logInfo(format string, args ...interface{}) {
	if _logMinLevel > 2 {
		return
	}
	msg := time.Now().UTC().Format(time.RFC3339) + " INFO " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stderr.WriteString(msg)
}

func logDebug(format string, args ...interface{}) {
	if _logMinLevel > 1 {
		return
	}
	msg := time.Now().UTC().Format(time.RFC3339) + " DEBUG " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stdout.WriteString(msg)
}

func logTrace(format string, args ...interface{}) {
	if _logMinLevel > 0 {
		return
	}
	msg := time.Now().UTC().Format(time.RFC3339) + " TRACE " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stdout.WriteString(msg)
}
