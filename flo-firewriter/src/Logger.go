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

type Logger struct {
	MinLevel LogLevel
	Color    bool

	prefix     string
	stdOut     *os.File
	errOut     *os.File
	scopes     []string
	scopeLock  sync.RWMutex
	nameSet    bool
	childLevel int
	isDebug    bool
	sbPool     *sbPool //recycling of sb to lower heap trashing & reduce gc work
}

const (
	ENVVAR_LOCAL_DEBUG   = "FLO_LOCAL_DEBUG"
	ENVVAR_LOG_MIN_LEVEL = "FLO_LOG_MIN_LEVEL"
	LOG_PREFIX_DEFAULT   = "fire-writer"
)

func DefaultLogger() *Logger {
	min := getEnvOrDefault(ENVVAR_LOG_MIN_LEVEL, getEnvOrDefault("LOGS_LEVEL", ""))
	n, _ := strconv.Atoi(min)
	if n > int(LL_ERROR) || n < 0 {
		n = 0
	}
	isDebug := strings.ToLower(getEnvOrDefault(ENVVAR_LOCAL_DEBUG, "")) == "true"
	isLocal := getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")) == "local"
	log := NewLogger(LOG_PREFIX_DEFAULT, "", LogLevel(n)).SetColor(isDebug || isLocal)
	log.isDebug = isDebug
	return log
}

var _loggerSbPool = new(sbPool).Init()

type sbPool struct {
	pool *sync.Pool
	mx   sync.Mutex
}

func (p *sbPool) Init() *sbPool {
	if p != nil {
		if p.pool == nil { //lazy double check locking
			p.mx.Lock()
			defer p.mx.Unlock()
			if p.pool == nil {
				p.pool = &sync.Pool{
					New: func() interface{} {
						return new(strings.Builder)
					},
				}
			}
		}
	}
	return p
}

func (p *sbPool) Get() *strings.Builder {
	if p == nil || p.pool == nil {
		return &strings.Builder{} //why not
	}
	var sb *strings.Builder
	if o := p.pool.Get(); o != nil { //pull 1 from the pool
		sb = o.(*strings.Builder)
		sb.Reset()
	} else { //just make one
		sb = &strings.Builder{}
	}
	return sb
}

func (p *sbPool) Put(s *strings.Builder) {
	if s != nil && p != nil && p.pool != nil {
		p.pool.Put(s)
	}
}

func NewLogger(prefix, name string, minLevel LogLevel) *Logger {
	if prefix == "" {
		prefix = LOG_PREFIX_DEFAULT
	}
	if minLevel > LL_WARN { //max allowed
		minLevel = LL_WARN
	}
	l := Logger{
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

func (l *Logger) Dispose() {
	if l == nil {
		return
	}
	l.prefix = ""
	l.stdOut = nil
	l.errOut = nil
	l.scopes = nil
	l.sbPool = nil
	l = nil
}

func (l *Logger) SetMinLevel(min LogLevel) *Logger {
	l.MinLevel = min
	return l
}

func (l *Logger) CloneAsChild(name string) *Logger {
	c := l.Clone()
	c.nameSet = false
	c.SetName(name)
	return c
}

func (l *Logger) Clone() *Logger {
	c := Logger{
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

func (l *Logger) SetColor(toggle bool) *Logger {
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

func (l *Logger) colorLevel(level LogLevel) string {
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

func (l *Logger) levelName(level LogLevel) string {
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

func (l *Logger) GetName() string {
	if ls := len(l.scopes); ls != 0 {
		return l.scopes[len(l.scopes)-1]
	}
	return ""
}

func (l *Logger) SetName(name string) *Logger {
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

func (l *Logger) ClearName() *Logger {
	if !l.nameSet {
		return l
	}
	l.nameSet = false
	l.PopScope()
	return l
}

func (l *Logger) PushScope(scope string, args ...interface{}) *Logger {
	l.scopeLock.Lock()
	defer l.scopeLock.Unlock()

	if len(args) == 0 {
		l.scopes = append(l.scopes, scope)
	} else {
		var a interface{} = args
		l.scopes = append(l.scopes, scope+fmt.Sprint(a))
	}
	return l
}

func (l *Logger) PopScope() *Logger {
	l.scopeLock.Lock()
	defer l.scopeLock.Unlock()

	if sl := len(l.scopes); sl > 0 {
		l.scopes = l.scopes[:sl-1]
	}
	return l
}

func (l *Logger) currentScope() string {
	l.scopeLock.RLock()
	defer l.scopeLock.RUnlock()

	var nameScopes string
	if len(l.scopes) > 0 { //slight risk of an extra space but it's faster this way
		nameScopes = strings.Join(l.scopes, ".")
	}
	return nameScopes
}

// will optimize late to only use file handle & append only writing w/o replace
func (l *Logger) Log(level LogLevel, format string, args ...interface{}) string {
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

func (l *Logger) getStringBuilder() *strings.Builder {
	if l.sbPool != nil {
		return l.sbPool.Get()
	}
	return &strings.Builder{} //just make 1 as this func can't fail
}

func (l *Logger) stashStringBuilder(sb *strings.Builder) {
	if sb != nil && l.sbPool != nil {
		l.sbPool.Put(sb)
	}
}

func (l *Logger) monoSprintF(level LogLevel, now time.Time, msg *string) *strings.Builder {
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

func (l *Logger) colorSprintF(level LogLevel, now time.Time, msg *string) *strings.Builder {
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

func (l *Logger) Fatal(format string, args ...interface{}) error {
	return errors.New(l.Log(LL_FATAL, format, args...))
}

func (l *Logger) Error(format string, args ...interface{}) error {
	return errors.New(l.Log(LL_ERROR, format, args...))
}

func (l *Logger) Warn(format string, args ...interface{}) error {
	return errors.New(l.Log(LL_WARN, format, args...))
}

func (l *Logger) Notice(format string, args ...interface{}) string {
	return l.Log(LL_NOTICE, format, args...)
}

func (l *Logger) Info(format string, args ...interface{}) string {
	return l.Log(LL_INFO, format, args...)
}

func (l *Logger) Debug(format string, args ...interface{}) string {
	return l.Log(LL_DEBUG, format, args...)
}

func (l *Logger) Trace(format string, args ...interface{}) string {
	return l.Log(LL_TRACE, format, args...)
}

func (l *Logger) IfFatal(e error) error {
	if e != nil {
		return l.Fatal(e.Error())
	}
	return e
}

func (l *Logger) IfError(e error) error {
	if e != nil {
		return l.Error(e.Error())
	}
	return e
}

func (l *Logger) IfWarn(e error) error {
	if e != nil {
		return l.Warn(e.Error())
	}
	return e
}

const LOG_WRAP_TEMPLATE = " | %v"

func (l *Logger) IfFatalF(e error, format string, args ...interface{}) error {
	if e != nil {
		return l.Fatal(format+LOG_WRAP_TEMPLATE, append(args, e.Error())...)
	}
	return e
}

func (l *Logger) IfErrorF(e error, format string, args ...interface{}) error {
	if e != nil {
		return l.Error(format+LOG_WRAP_TEMPLATE, append(args, e.Error())...)
	}
	return e
}

func (l *Logger) IfWarnF(e error, format string, args ...interface{}) error {
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
