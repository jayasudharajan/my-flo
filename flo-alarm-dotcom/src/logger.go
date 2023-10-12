package main

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Log is partial Logger (log printing ops only)
type Log interface {
	GetName() string
	IsDebug() bool

	PushScope(scope string, args ...interface{})
	PopScope()

	Log(level LogLevel, format string, args ...interface{}) string
	Fatal(format string, args ...interface{}) error
	Error(format string, args ...interface{}) error
	Warn(format string, args ...interface{}) error
	Notice(format string, args ...interface{}) string
	Info(format string, args ...interface{}) string
	Debug(format string, args ...interface{}) string
	Trace(format string, args ...interface{}) string

	IfFatal(e error) error
	IfError(e error) error
	IfWarn(e error) error

	IfFatalF(e error, format string, args ...interface{}) error
	IfErrorF(e error, format string, args ...interface{}) error
	IfWarnF(e error, format string, args ...interface{}) error
}

// Logger has full interface
type Logger interface {
	Dispose()
	CloneAsChild(name string) Logger
	Clone() Logger

	SetMinLevel(min LogLevel) Logger
	SetColor(toggle bool) Logger
	GetSbPool() SbPool
	IsDebug() bool
	SetDebug(toggle bool) Logger

	GetName() string
	SetName(name string) Logger
	ResetNameLevel() Logger
	ClearName() Logger

	PushScope(scope string, args ...interface{})
	PopScope()

	Log(level LogLevel, format string, args ...interface{}) string
	Fatal(format string, args ...interface{}) error
	Error(format string, args ...interface{}) error
	Warn(format string, args ...interface{}) error
	Notice(format string, args ...interface{}) string
	Info(format string, args ...interface{}) string
	Debug(format string, args ...interface{}) string
	Trace(format string, args ...interface{}) string

	IfFatal(e error) error
	IfError(e error) error
	IfWarn(e error) error

	IfFatalF(e error, format string, args ...interface{}) error
	IfErrorF(e error, format string, args ...interface{}) error
	IfWarnF(e error, format string, args ...interface{}) error
}

type logger struct {
	MinLevel   LogLevel
	Color      bool
	prefix     string
	stdOut     *os.File
	errOut     *os.File
	scopes     []string
	scopeLock  sync.RWMutex
	nameSet    bool
	childLevel int
	isDebug    bool
	sbPool     SbPool //recycling of sb to lower heap trashing & reduce gc work
}

const (
	ENVVAR_LOCAL_DEBUG   = "FLO_LOCAL_DEBUG"
	ENVVAR_LOG_MIN_LEVEL = "FLO_LOG_MIN_LEVEL"
	LOG_PREFIX_DEFAULT   = "flo-alarm-dotcom"
)

func DefaultLogger() Logger {
	min := getEnvOrDefault(ENVVAR_LOG_MIN_LEVEL, "")
	n, _ := strconv.Atoi(min)
	if n > int(LL_FATAL) || n < 0 {
		n = 0
	}
	isDebug := strings.ToLower(getEnvOrDefault(ENVVAR_LOCAL_DEBUG, "")) == "true"
	isLocal := getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")) == "local"
	log := NewLogger(LOG_PREFIX_DEFAULT, "", LogLevel(n)).SetColor(isDebug || isLocal)
	log.SetDebug(isDebug)
	return log
}

var _loggerSbPool = CreateSbPool()

func NewLogger(prefix, name string, minLevel LogLevel) Logger {
	if prefix == "" {
		prefix = LOG_PREFIX_DEFAULT
	}
	l := logger{
		MinLevel:   minLevel,
		prefix:     prefix,
		stdOut:     os.Stdout,
		errOut:     os.Stderr,
		scopes:     []string{},
		childLevel: 0,
	}
	l.sbPool = _loggerSbPool //singleton
	return l.SetName(name)
}

func (l *logger) IsDebug() bool {
	return l.isDebug
}

func (l *logger) SetDebug(toggle bool) Logger {
	l.isDebug = toggle
	return l
}

func (l *logger) GetSbPool() SbPool {
	return l.sbPool
}

func (l *logger) Dispose() {
	if l == nil {
		return
	}
	l.prefix = ""
	l.stdOut = nil
	l.errOut = nil
	l.scopes = nil
	l.sbPool = nil
}

func (l *logger) SetMinLevel(min LogLevel) Logger {
	l.MinLevel = min
	return l
}

func (l *logger) CloneAsChild(name string) Logger {
	c := l.Clone()
	c.ResetNameLevel()
	c.SetName(name)
	return c
}

func (l *logger) Clone() Logger {
	if l == nil {
		return nil
	}
	c := logger{
		MinLevel:   l.MinLevel,
		prefix:     l.prefix,
		stdOut:     os.Stdout, //don't clone, SEE: https://github.com/golang/go/issues/22610
		errOut:     os.Stderr,
		childLevel: l.childLevel,
		isDebug:    l.isDebug,
		nameSet:    l.nameSet,
		Color:      l.Color,
		sbPool:     l.sbPool,
	}
	l.scopeLock.RLock()
	defer l.scopeLock.RUnlock()

	c.scopes = make([]string, len(l.scopes))
	copy(c.scopes, l.scopes)
	return &c
}

func (l *logger) SetColor(toggle bool) Logger {
	l.Color = toggle
	return l
}

type LogLevel int

const (
	LL_TRACE  LogLevel = 0
	LL_DEBUG  LogLevel = 1
	LL_INFO   LogLevel = 2
	LL_NOTICE LogLevel = 3
	LL_WARN   LogLevel = 4
	LL_ERROR  LogLevel = 5
	LL_FATAL  LogLevel = 6
)

const (
	LL_TraceColor   = "\033[0;37m"
	LL_DebugColor   = "\033[0;36m"
	LL_InfoColor    = "\033[1;36m"
	LL_NoticeColor  = "\033[1;34m"
	LL_WarningColor = "\033[1;33m"
	LL_ErrorColor   = "\033[1;31m"
	LL_FatalColor   = "\033[103m\033[1;31m"

	LL_ResetColor = "\033[0m"
	LL_BgGray     = "\033[100m"
	LL_Yellow     = "\033[0;33m"
	LL_Red        = "\033[0;31m"
)

func (l *logger) colorLevel(level LogLevel) string {
	switch level {
	case LL_DEBUG:
		return LL_DebugColor
	case LL_INFO:
		return LL_InfoColor
	case LL_NOTICE:
		return LL_NoticeColor
	case LL_WARN:
		return LL_WarningColor
	case LL_ERROR:
		return LL_ErrorColor
	case LL_FATAL:
		return LL_FatalColor
	default:
		return LL_TraceColor
	}
}

func (l *logger) levelName(level LogLevel) string {
	switch level {
	case LL_DEBUG:
		return "DEBUG"
	case LL_INFO:
		return "INFO"
	case LL_NOTICE:
		return "NOTICE"
	case LL_WARN:
		return "WARN"
	case LL_ERROR:
		return "ERROR"
	case LL_FATAL:
		return "FATAL"
	default:
		return "TRACE"
	}
}

func (l *logger) GetName() string {
	if ls := len(l.scopes); ls != 0 {
		return l.scopes[len(l.scopes)-1]
	}
	return ""
}

func (l *logger) ResetNameLevel() Logger {
	l.nameSet = false
	return l
}

func (l *logger) SetName(name string) Logger {
	if name == "" {
		return l
	}
	if l.nameSet {
		l.scopes[l.childLevel] = name
	} else {
		l.nameSet = true
		l.PushScope(name)
	}
	return l
}

func (l *logger) ClearName() Logger {
	if !l.nameSet {
		return l
	}
	l.nameSet = false
	l.PopScope()
	return l
}

func (l *logger) PushScope(scope string, args ...interface{}) {
	l.scopeLock.Lock()
	defer l.scopeLock.Unlock()

	if len(args) == 0 {
		l.scopes = append(l.scopes, scope)
	} else {
		var a interface{} = args
		l.scopes = append(l.scopes, scope+fmt.Sprint(a))
	}
}

func (l *logger) PopScope() {
	l.scopeLock.Lock()
	defer l.scopeLock.Unlock()

	if sl := len(l.scopes); sl > 0 {
		l.scopes = l.scopes[:sl-1]
	}
}

func (l *logger) currentScope() string {
	l.scopeLock.RLock()
	defer l.scopeLock.RUnlock()

	var nameScopes string
	if len(l.scopes) > 0 { //slight risk of an extra space, but it's faster this way
		nameScopes = strings.Join(l.scopes, ".")
	}
	return nameScopes
}

// Log will optimize late to only use file handle & append only writing w/o replace
func (l *logger) Log(level LogLevel, format string, args ...interface{}) string {
	if level < l.MinLevel {
		return ""
	}
	now := time.Now() //freeze time & msg ASAP
	var msg string
	if len(format) == 0 {
		msg = fmt.Sprint(args...)
	} else {
		msg = fmt.Sprintf(format, args...)
	}

	var sb *strings.Builder
	if l.Color {
		sb = l.colorSprintF(level, now, &msg)
	} else {
		sb = l.monoSprintF(level, now, &msg)
	}
	if level >= LL_WARN {
		_, _ = l.errOut.WriteString(sb.String())
	} else {
		_, _ = l.stdOut.WriteString(sb.String())
	}
	l.stashStringBuilder(sb) //return to pool
	return msg
}

func (l *logger) getStringBuilder() *strings.Builder {
	if l.sbPool != nil {
		return l.sbPool.Get()
	}
	return &strings.Builder{} //just make 1 as this func can't fail
}

func (l *logger) stashStringBuilder(sb *strings.Builder) {
	if sb != nil && l.sbPool != nil {
		l.sbPool.Put(sb)
	}
}

func (l *logger) monoSprintF(level LogLevel, now time.Time, msg *string) *strings.Builder {
	sb := l.getStringBuilder() //pull 1 from the pool
	sb.WriteString(now.Format(time.RFC3339))
	sb.WriteString(" ")
	sb.WriteString(l.levelName(level))
	sb.WriteString(" ")
	if l.prefix != "" {
		sb.WriteString(l.prefix)
		sb.WriteString(": ")
	}
	if s := l.currentScope(); s != "" {
		sb.WriteString(s)
		sb.WriteString(" ")
	}
	sb.WriteString(*msg)
	sb.WriteString("\n")
	return sb
}

func (l *logger) colorSprintF(level LogLevel, now time.Time, msg *string) *strings.Builder {
	sb := l.getStringBuilder() //pull 1 from the pool
	sb.WriteString(LL_TraceColor)
	if l.isDebug {
		sb.WriteString(now.Format("15:04:05"))
	} else {
		sb.WriteString(now.Format(time.RFC3339))
	}
	sb.WriteString(LL_ResetColor)

	sb.WriteString(l.colorLevel(level))
	sb.WriteString(" ")
	sb.WriteString(l.levelName(level))
	sb.WriteString(" ")
	sb.WriteString(LL_ResetColor)

	sb.WriteString(LL_BgGray)
	if !l.isDebug && l.prefix != "" {
		sb.WriteString(" ")
		sb.WriteString(l.prefix)
		sb.WriteString(":")
	}
	if s := l.currentScope(); s != "" {
		sb.WriteString(" ")
		sb.WriteString(s)
		sb.WriteString(" ")
	}
	sb.WriteString(LL_ResetColor)

	if level == LL_TRACE {
		sb.WriteString(LL_TraceColor)
	} else if level >= LL_NOTICE {
		sb.WriteString(LL_Yellow)
	} else if level >= LL_ERROR {
		sb.WriteString(LL_Red)
	}
	sb.WriteString(" ")
	sb.WriteString(*msg)
	if level == LL_TRACE || level >= LL_NOTICE {
		sb.WriteString(LL_ResetColor)
	}
	sb.WriteString("\n")
	return sb
}

func (l *logger) Fatal(format string, args ...interface{}) error {
	return errors.New(l.Log(LL_FATAL, format, args...))
}

func (l *logger) Error(format string, args ...interface{}) error {
	return errors.New(l.Log(LL_ERROR, format, args...))
}

func (l *logger) Warn(format string, args ...interface{}) error {
	return errors.New(l.Log(LL_WARN, format, args...))
}

func (l *logger) Notice(format string, args ...interface{}) string {
	return l.Log(LL_NOTICE, format, args...)
}

func (l *logger) Info(format string, args ...interface{}) string {
	return l.Log(LL_INFO, format, args...)
}

func (l *logger) Debug(format string, args ...interface{}) string {
	return l.Log(LL_DEBUG, format, args...)
}

func (l *logger) Trace(format string, args ...interface{}) string {
	return l.Log(LL_TRACE, format, args...)
}

func (l *logger) IfFatal(e error) error {
	if e != nil {
		return l.Fatal(e.Error())
	}
	return e
}

func (l *logger) IfError(e error) error {
	if e != nil {
		return l.Error(e.Error())
	}
	return e
}

func (l *logger) IfWarn(e error) error {
	if e != nil {
		return l.Warn(e.Error())
	}
	return e
}

const LOG_WRAP_TEMPLATE = " | %v"

func (l *logger) IfFatalF(e error, format string, args ...interface{}) error {
	if e != nil {
		return l.Fatal(format+LOG_WRAP_TEMPLATE, append(args, e.Error())...)
	}
	return e
}

func (l *logger) IfErrorF(e error, format string, args ...interface{}) error {
	if e != nil {
		return l.Error(format+LOG_WRAP_TEMPLATE, append(args, e.Error())...)
	}
	return e
}

func (l *logger) IfWarnF(e error, format string, args ...interface{}) error {
	if e != nil {
		return l.Warn(format+LOG_WRAP_TEMPLATE, append(args, e.Error())...)
	}
	return e
}

func wrapErrors(es []error) error {
	if len(es) == 0 {
		return nil
	}

	sb := _loggerSbPool.Get()
	defer _loggerSbPool.Put(sb)
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
	msg := sb.String()
	if ec > 0 {
		return errors.New(msg)
	} else {
		return nil
	}
}

func IfLogLevel(tf bool, t, f LogLevel) LogLevel {
	if tf {
		return t
	} else {
		return f
	}
}
