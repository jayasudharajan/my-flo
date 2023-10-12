package main

var _log = DefaultLogger()

func logFatal(format string, args ...interface{}) error {
	return _log.Fatal(format, args...)
}

func logError(format string, args ...interface{}) error {
	return _log.Error(format, args...)
}

func logWarn(format string, args ...interface{}) error {
	return _log.Warn(format, args...)
}

func logInfo(format string, args ...interface{}) string {
	return _log.Info(format, args...)
}

func logNotice(format string, args ...interface{}) string {
	return _log.Notice(format, args...)
}

func logDebug(format string, args ...interface{}) string {
	return _log.Debug(format, args...)
}

func logTrace(format string, args ...interface{}) string {
	return _log.Trace(format, args...)
}
