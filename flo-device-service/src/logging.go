package main

import "github.com/labstack/gommon/log"

// ConfigureLogs is the function to configure logs
func ConfigureLogs(logsLevel int) {
	// 1 -> DEBUG
	// 2 -> INFO
	// 3 -> WARN
	// 4 -> ERROR
	// 5 -> OFF
	log.SetLevel(log.Lvl(logsLevel))
	log.SetHeader("${time_rfc3339} ${level} ${short_file} ${line}")
}
