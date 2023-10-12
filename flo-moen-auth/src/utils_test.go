package main

import (
	"encoding/json"
	"fmt"
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
	check(CreateWebServer, "CreateWebServer")
	check(_log.Dispose, "Dispose")
	check(nil, "<nil>")
}

func TestPubGwPrint(t *testing.T) {
	dt := PubGwTime(time.Now())
	assert.Equal(t, dt.String(), fmt.Sprint(dt))
}

type dateTest struct {
	Date PubGwTime `json:"date"`
}

func (d dateTest) String() string {
	return tryToJson(d)
}

func TestTimeParse(t *testing.T) {
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

	check("2020-10-07T17:18:49-00:00", time.Date(2020, 10, 7, 17, 18, 49, 0, time.UTC))
	loc := time.FixedZone("-08:00", -8*3600)
	check("2020-10-07T17:18:49-08:00", time.Date(2020, 10, 7, 17, 18, 49, 0, loc))
	loc = time.FixedZone("+08:00", +8*3600)
	check("2020-10-07T17:18:49+08:00", time.Date(2020, 10, 7, 17, 18, 49, 0, loc))
}

type wrapTest struct {
	TestDate dateTest
}

func (w wrapTest) String() string {
	return tryToJson(w)
}

type wrapTest2 struct {
	Date *PubGwTime
}

func (w wrapTest2) String() string {
	return tryToJson(w)
}

func TestStrutMap(t *testing.T) {
	check := func(input interface{}, expect interface{}) {
		buf, e := json.Marshal(input)
		assert.Nil(t, e)
		assert.NotEmpty(t, buf)

		m := make(map[string]interface{})
		e = json.Unmarshal(buf, &m)
		assert.Nil(t, e)
		assert.Greater(t, len(m), 0)

		//e = mapstructure.Decode(&m, &expect) //old code that will fail
		e = jsonMap(&m, &expect)
		assert.Nil(t, e)
		var (
			inStr = fmt.Sprint(input)
			exStr = fmt.Sprint(expect)
		)
		assert.Equal(t, inStr, exStr)
	}
	var (
		a = dateTest{PubGwTime(time.Now())}
		b = a //struct copy
		x = wrapTest{dateTest{PubGwTime(a.Date.Time().Truncate(time.Hour * 24))}}
		y = wrapTest{b}

		d = PubGwTime(time.Now())
		j = wrapTest2{Date: &d}
		k = wrapTest2{}
	)
	check(&a, &b)
	check(&x, &y)
	check(&j, &k)
}
