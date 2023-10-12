package utils

import (
	"errors"
	"fmt"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestGetFunctionName(t *testing.T) {
	check := func(f interface{}, name string) {
		n := GetFunctionName(f)
		assert.NotEmpty(t, n, "Name is empty for '%v' input", name)
		assert.Contains(t, n, name)
	}
	check(TestGetFunctionName, "TestGetFunctionName")
	check(GetFunctionName, "GetFunctionName")
	check(_log.Dispose, "Dispose")
	check(nil, "<nil>")
}

func TestRetryIfError(t *testing.T) {
	retryCheck(t, 0, time.Second)
	retryCheck(t, 1, time.Millisecond*100)
	retryCheck(t, 2, time.Second*2)
	retryCheck(t, 5, time.Millisecond*666)
}

func retryCheck(t *testing.T, errors int32, wait time.Duration) {
	var (
		te         = TestErrors{Throws: errors}
		expectTime = time.Duration(errors)*wait + (time.Millisecond * 100)
		start      = time.Now()
	)
	RetryIfError(te.Run, wait, _log)

	dur := time.Since(start)
	assert.True(t, dur <= expectTime, "Duration %v is longer than expected %v", dur, expectTime)
	assert.Equal(t, errors+1, te.Runs, "Runs %v is not %v", te.Runs, errors+1)
	assert.Equal(t, errors, te.Errors, "Errors %v is not %v", te.Errors, errors)
	assert.Equal(t, int32(1), te.OKs, "OK %v is not 1", te.OKs)
}

type TestErrors struct {
	Throws int32
	Runs   int32
	Errors int32
	OKs    int32
}

func (t *TestErrors) Run() error {
	atomic.AddInt32(&t.Runs, 1)
	if c := atomic.AddInt32(&t.Throws, -1); c >= 0 {
		atomic.AddInt32(&t.Errors, 1)
		return errors.New(fmt.Sprintf("current counter value: %v", c))
	} else {
		atomic.AddInt32(&t.OKs, 1)
		return nil
	}
}
