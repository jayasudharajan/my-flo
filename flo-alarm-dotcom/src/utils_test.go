package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/stretchr/testify/assert"
)

func TestCleanToken(t *testing.T) {
	check := func(token, expect string) {
		assert.Equal(t, expect, CleanToken(token))
	}
	check("xx.yy.zz", "xx.yy."+FAKE_JWT_SUM)
	check("aaa.bbb.ccc", "aaa.bbb."+FAKE_JWT_SUM)
}

func TestGetFunctionName(t *testing.T) {
	check := func(f interface{}, name string) {
		n := GetFunctionName(f)
		assert.NotEmpty(t, n, "Name is empty for '%v' input", name)
		assert.Contains(t, n, name)
	}
	check(TestGetFunctionName, "TestGetFunctionName")
	check(GetFunctionName, "GetFunctionName")
	check(CreateWebServer, "CreateWebServer")
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
		return errors.New(fmt.Sprintf("current counter: %v", c))
	} else {
		atomic.AddInt32(&t.OKs, 1)
		return nil
	}
}

func TestPubGwPrint(t *testing.T) {
	dt := DateTime(time.Now())
	assert.Equal(t, dt.String(), fmt.Sprint(dt))
}

type dateTest struct {
	Date DateTime `json:"date"`
}

func (d dateTest) String() string {
	return tryToJson(d)
}

func TestTimeNoTZ(t *testing.T) {
	check := func(s string, expect time.Time) {
		var (
			buf = []byte(fmt.Sprintf(`{"date":"%s"}`, s))
			d   = dateTest{}
			e   error
		)
		assert.Nil(t, json.Unmarshal(buf, &d), "unmarshal OK")
		dt := d.Date.Time()
		assert.Equal(t, expect.Unix(), dt.Unix(), "Unix time matches")
		assert.Equal(t, expect.String(), dt.String(), "String print matches")

		buf, e = json.Marshal(d) //another round trip
		assert.Nil(t, e, "marshal OK")
		assert.NotEmpty(t, buf, "marshal buffer OK")
		assert.Nil(t, json.Unmarshal(buf, &d), "unmarshal OK")
		dt = d.Date.Time()
		assert.Equal(t, expect.Unix(), dt.Unix(), "Unix time matches")
		assert.Equal(t, expect.String(), dt.String(), "String print matches")
	}
	check("2020-10-07T17:18:49.256706", time.Date(2020, 10, 7, 17, 18, 49, 256706000, time.UTC))
	check("2020-09-19T05:56:59.000", time.Date(2020, 9, 19, 5, 56, 59, 0, time.UTC))
	check("2020-09-19T05:56:11", time.Date(2020, 9, 19, 5, 56, 11, 0, time.UTC))
	check("2020-09-19T05:56:11Z", time.Date(2020, 9, 19, 5, 56, 11, 0, time.UTC))
	check("2020-09-19T05:56:59.000Z", time.Date(2020, 9, 19, 5, 56, 59, 0, time.UTC))
	check("2020-10-07T17:18:49.256706Z", time.Date(2020, 10, 7, 17, 18, 49, 256706000, time.UTC))
	check("", time.Time{})
}

type wrapTest struct {
	TestDate dateTest
}

func (w wrapTest) String() string {
	return tryToJson(w)
}

type wrapTest2 struct {
	Date *DateTime
}

func (w wrapTest2) String() string {
	return tryToJson(w)
}

func TestAllowDenyList(t *testing.T) {
	var (
		deny  = []string{"deny-" + uuid.New().String(), "deny-" + uuid.New().String()}
		allow = []string{"allow-" + uuid.New().String(), "allow-" + uuid.New().String()}
		rand  = []string{"rand-" + uuid.New().String(), "rand-" + uuid.New().String()}
		all   = append(allow, deny...)
	)
	all = append(all, rand...)

	test := func(deny, allow, trueOnly, falseOnly []string) {
		trueMap := make(map[string]bool)
		for _, s := range trueOnly {
			trueMap[s] = true
		}
		for _, s := range falseOnly {
			trueMap[s] = false
		}

		chk := CreateAllowResource(deny, allow)
		for k, v := range trueMap {
			if v {
				assert.True(t, chk.Allow(k))
			} else {
				assert.False(t, chk.Allow(k))
			}
		}
	}

	test(nil, allow, allow, append(deny, rand...))
	test(deny, nil, append(allow, rand...), deny)
	test(deny, allow, allow, append(deny, rand...))
	test(nil, nil, all, nil)
}

func TestAlphaNumOnly(t *testing.T) {
	check := func(inStr, expect string) {
		r := AlphaNumOnly([]byte(inStr))
		assert.Equal(t, expect, string(r))
	}
	check("$a1-2.3+", "a123")
	check("a1+2.3", "a123")
}
