package utils

var _log = DefaultLogger()

func Log() *Logger {
	return _log
}

func LogFatal(format string, args ...interface{}) error {
	return _log.Fatal(format, args...)
}

func LogError(format string, args ...interface{}) error {
	return _log.Error(format, args...)
}

func LogWarn(format string, args ...interface{}) error {
	return _log.Warn(format, args...)
}

func LogInfo(format string, args ...interface{}) {
	_log.Info(format, args...)
}

func LogNotice(format string, args ...interface{}) {
	_log.Notice(format, args...)
}

func LogDebug(format string, args ...interface{}) {
	_log.Debug(format, args...)
}

func LogTrace(format string, args ...interface{}) {
	_log.Trace(format, args...)
}
