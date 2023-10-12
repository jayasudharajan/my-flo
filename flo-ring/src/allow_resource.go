package main

import (
	"strings"
)

type AllowResource interface {
	Allow(string) bool
}

type allowResource struct {
	okMap    map[string]bool
	allowAll bool
	disabled bool
}

func DefaultAllowResource() AllowResource {
	return CreateAllowResource(
		strings.Split(getEnvOrDefault("FLO_DENY_RESOURCES", ""), " "),
		strings.Split(getEnvOrDefault("FLO_ALLOW_RESOURCES", ""), " "))
}

// logic will only run locally & if list is not empty
func CreateAllowResource(denyList, allowList []string) AllowResource {
	var (
		allow    = make(map[string]bool)
		allowAll bool
		disabled bool
		ac, dc   int32
	)
	if len(denyList) != 0 { //white space separated values
		for _, s := range denyList {
			if len(s) < 12 {
				continue
			}
			allow[s] = false
			allow[strings.ToLower(s)] = false
			allow[strings.ToUpper(s)] = false
			dc++
		}
	}
	if len(allowList) != 0 { //white space separated values
		for _, s := range allowList {
			if len(s) < 12 {
				continue
			}
			allow[s] = true
			allow[strings.ToLower(s)] = true
			allow[strings.ToUpper(s)] = true
			ac++
		}
	}
	if ac == 0 {
		allowAll = true
	}
	if disabled = len(allow) == 0; !disabled {
		_log.Notice("AllowResource list is ENABLED. Allow=%v Deny=%v (allowAll:%v)", ac, dc, allowAll)
	} else {
		_log.Notice("AllowResource list is DISABLED")
	}
	return &allowResource{allow, allowAll, disabled}
}

// will return false only when allow list exists, while running locally
func (a *allowResource) Allow(key string) bool {
	if a != nil && !a.disabled {
		ok, found := a.okMap[key]
		if !found {
			if ok, found = a.okMap[strings.ToLower(key)]; !found {
				if ok, found = a.okMap[strings.ToUpper(key)]; !found {
					ok = a.allowAll
				}
			}
		}
		return ok
	}
	return true
}
