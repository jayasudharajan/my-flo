package main

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestKeyPerDuration_Check(t *testing.T) {
	var (
		fsh = time.Duration(2) * time.Second
		kd  = CreateKeyPerDuration(fsh)
		key = "1s"
		dur = time.Second
		arr = []bool{
			kd.Check(key, dur),
			kd.Check(key, dur),
			kd.Check(key, dur),
			kd.Check(key, dur),
			kd.Check(key, dur),
		}
	)
	for i, v := range arr {
		if i == 0 {
			assert.True(t, v, "First is not true")
		} else {
			assert.False(t, v, "Call %v is not false", i)
		}
	}
	time.Sleep(dur + time.Millisecond)
	assert.True(t, kd.Check(key, dur), "Call after sleep is not true!")
	assert.False(t, kd.Check(key, dur), "Call 2 after sleep is not false!")
	src := kd.(*keyPerDuration)
	assert.NotNil(t, src, "src is nil")
	mc := len(src.lastMap)
	assert.Equal(t, 1, mc, ".lastMap has count of %v instead of 1", mc)
	time.Sleep(fsh + time.Second)
	mc = len(src.lastMap)
	assert.Equal(t, 0, mc, ".lastMap has count of %v instead of 0 AFTER auto flush dur %v", mc, fsh)
}
