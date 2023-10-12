package main

import "strings"

type allowList struct {
	log     *Logger
	hasKeys bool
	names   map[string]bool
}

func CreateAllowList(envVar string, log *Logger) *allowList {
	var (
		a = allowList{
			log:   log.CloneAsChild("AllowList").PushScope(envVar),
			names: make(map[string]bool),
		}
		arr = strings.Split(getEnvOrDefault(envVar, ""), " ")
	)
	if a.log.isDebug {
		for _, k := range arr {
			if len(k) < 12 {
				continue
			}
			a.names[strings.ToLower(k)] = true
		}
	}

	a.log.PushScope("CreateAllowList")
	defer a.log.PopScope()
	if keys := len(a.names); keys > 0 {
		a.hasKeys = true
		a.log.Warn("is set for ONLY %v items: %v", keys, arr)
	} else {
		a.log.Notice("is disabled. Will allow ALL items")
	}
	return &a
}

func (a *allowList) Found(key string) bool {
	if a != nil && a.hasKeys && key != "" {
		access, _ := a.names[strings.ToLower(key)]
		return access
	}
	return true //by default allow all
}
