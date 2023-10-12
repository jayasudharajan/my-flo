package main

import (
	"errors"
	"fmt"
	"os"
	"time"
)

const logPrefix string = "flo-detect-v2: "

func logFatal(format string, args ...interface{}) error {
	msg := time.Now().UTC().Format(time.RFC3339) + " FATAL " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stderr.WriteString(msg)
	return errors.New(msg)
}

func logError(format string, args ...interface{}) error {
	msg := time.Now().UTC().Format(time.RFC3339) + " ERROR " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stderr.WriteString(msg)
	return errors.New(msg)
}

func logWarn(format string, args ...interface{}) error {
	msg := time.Now().UTC().Format(time.RFC3339) + " WARN " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stderr.WriteString(msg)
	return errors.New(msg)
}

func logInfo(format string, args ...interface{}) {
	msg := time.Now().UTC().Format(time.RFC3339) + " INFO " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stderr.WriteString(msg)
}

func logNotice(format string, args ...interface{}) {
	msg := time.Now().UTC().Format(time.RFC3339) + " NOTICE " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stderr.WriteString(msg)
}

func logDebug(format string, args ...interface{}) {
	msg := time.Now().UTC().Format(time.RFC3339) + " DEBUG " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stdout.WriteString(msg)
}

func logTrace(format string, args ...interface{}) {
	msg := time.Now().UTC().Format(time.RFC3339) + " TRACE " + logPrefix + fmt.Sprintf(format, args...) + "\n"
	_, _ = os.Stdout.WriteString(msg)
}
