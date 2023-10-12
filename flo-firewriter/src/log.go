package main

import (
	"os"
)

var _log = DefaultLogger()

func logFatal(format string, args ...interface{}) error {
	defer func() {
		go func() { os.Exit(-1) }()
	}() //ensure err out print, func return & quit soon after
	return _log.Fatal(format, args...)
}

func logError(format string, args ...interface{}) error {
	return _log.Error(format, args...)
}

func logWarn(format string, args ...interface{}) error {
	return _log.Warn(format, args...)
}

func logNotice(format string, args ...interface{}) {
	_log.Notice(format, args...)
}

func logInfo(format string, args ...interface{}) {
	_log.Info(format, args...)
}

func logDebug(format string, args ...interface{}) {
	_log.Debug(format, args...)
}

func logTrace(format string, args ...interface{}) {
	_log.Trace(format, args...)
}
