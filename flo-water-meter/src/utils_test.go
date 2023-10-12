package main

import (
	"math/rand"
	_ "regexp"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func init() {
	rand.Seed(time.Now().Unix())
}

func TestDurationFmt(t *testing.T) {
	d, e := time.ParseDuration("5h3m1s")
	assert.Equal(t, nil, e)

	s := fmtDuration(d)
	assert.Equal(t, "05:03:01", s)

	d, _ = time.ParseDuration("3m2s")
	s = fmtDuration(d)
	assert.Equal(t, "00:03:02", s)
}
