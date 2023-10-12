package loggy

import (
	"log"
	"os"
)

type Loggy struct {
	Log *log.Logger
}

func Init() (l Loggy) {

	l.Log = log.New(os.Stdout, "", log.Ldate|log.Ltime|log.Lmicroseconds|log.Lshortfile|log.LUTC)
	return l
}

func (Loggy) Info(m string) string {

	return "INFO: " + m
}
func (Loggy) Warning(m string) string {

	return "WARN: " + m
}
func (Loggy) Error(err error, m string) string {

	return "ERROR: " + m + err.Error()
}
