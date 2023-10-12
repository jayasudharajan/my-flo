package main

import (
	"fmt"
	"time"
)

type logChronicle struct {
	name         string
	events       map[string]int64
	meta         map[string]interface{}
	currentTime  int64
	currentEvent string
}

func newChronicle(name string) *logChronicle {

	return &logChronicle{
		name:         name,
		currentTime:  0,
		currentEvent: "",
		events:       make(map[string]int64),
		meta:         make(map[string]interface{}),
	}
}

func (lc *logChronicle) addMeta(name string, val interface{}) {
	lc.meta[name] = val
}
func (lc *logChronicle) startStep(evt string) {
	lc.endCurrentStep()
	lc.currentTime = time.Now().UnixNano()
	lc.currentEvent = evt
}

func (lc *logChronicle) endCurrentStep() {
	if lc.currentTime > 0 {
		add := time.Now().UnixNano() - lc.currentTime

		if sum, ok := lc.events[lc.currentEvent]; ok {
			add = add + sum
		}
		lc.events[lc.currentEvent] = add

		lc.currentEvent = ""
		lc.currentTime = 0
	}
}

func (lc *logChronicle) flush(hurdle int64) {
	lc.endCurrentStep()
	sb := SbPoolInstance().GetStringBuilder()
	var total int64 = 0
	count := len(lc.events)
	for k, v := range lc.events {
		step := v / int64(time.Millisecond)
		total = total + step
		sb.WriteString(fmt.Sprintf("%v=%v", k, step))
		if count > 1 {
			sb.WriteString(", ")
			count = count - 1
		}
	}
	count = len(lc.meta)
	if count > 0 {
		sb.WriteString(" | ")
		for k, v := range lc.meta {
			sb.WriteString(fmt.Sprintf("%v=%v", k, v))
			if count > 1 {
				sb.WriteString(", ")
				count = count - 1
			}
		}
	}
	if total > hurdle {
		logTrace("%v %v", lc.name, sb.String())
	}
	SbPoolInstance().StashStringBuilder(sb)
}
