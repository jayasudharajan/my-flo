package main

import "strings"

// BrokenValves simulate broken valve state
type BrokenValves interface {
	Is(key string) bool        //if true the provided key should simulate broken state
	IsAny(keys ...string) bool //if true 1 of the provided value has been marked to simulate as a broken valve
}

func CreateBrokenValves(log *Logger) BrokenValves {
	var (
		arr    = strings.Split(getEnvOrDefault("FLO_FAKE_BROKEN_VALVES", ""), " ")
		broken = make(map[string]bool)
	)
	log = log.CloneAsChild("BrokenValves")
	for _, v := range arr {
		if v = strings.TrimSpace(v); len(v) >= 6 {
			broken[strings.ToLower(v)] = true
		}
	}
	log.Notice("FLO_FAKE_BROKEN_VALVES contains %v items", len(broken))
	return &brokenValves{log, broken}
}

type brokenValves struct {
	log  *Logger
	vmap map[string]bool
}

func (b *brokenValves) Is(key string) bool {
	_, broken := b.vmap[strings.ToLower(key)]
	if broken {
		b.log.Debug("simulate %s", key)
	}
	return broken
}

func (b *brokenValves) IsAny(keys ...string) bool {
	var broken = false //simulate a broken valve
	for _, k := range keys {
		if _, broken = b.vmap[strings.ToLower(k)]; broken {
			if broken {
				b.log.Debug("simulate %s", k)
			}
			break
		}
	}
	return broken
}
