package main

import (
	"bytes"
	"compress/gzip"
	"io/ioutil"
	"math/rand"
	_ "regexp"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func init() {
	rand.Seed(time.Now().Unix())
}

var (
	_longStr string
	_wc      *waterCacheReader
)

func init() {
	sb := strings.Builder{}
	sb.WriteString("testing 1 23.... super long string here: ")
	for i := 0; i < 1000; i++ {
		sb.WriteString(uuid.New().String())
		sb.WriteString(" ")
		sb.WriteString(uuid.New().String())
		sb.WriteString(" ")
		sb.WriteString(uuid.New().String())
		sb.WriteString(" ")
	}
	_longStr = sb.String()
	_wc = &waterCacheReader{}
}

func compressGz(t *testing.T, s string) string {
	wb := &bytes.Buffer{}
	zw := gzip.NewWriter(wb)
	n, e := zw.Write([]byte(s))
	assert.Nil(t, e)
	assert.NotEqual(t, 0, n)
	e = zw.Close()
	assert.Nil(t, e)
	gs := wb.String()
	assert.NotEmpty(t, gs)
	assert.NotEqual(t, 1, len(gs))
	return gs
}

func unCompressGz(t *testing.T, gs string) string {
	rb := bytes.NewBufferString(gs)
	zr, e := gzip.NewReader(rb)
	defer zr.Close()
	if e != nil {
		assert.Nil(t, zr)
	}
	assert.Nil(t, e)
	arr, e := ioutil.ReadAll(zr)
	assert.Nil(t, e)
	assert.NotEmpty(t, arr)
	csv := string(arr)
	assert.NotEmpty(t, csv)
	assert.NotEqual(t, gs, csv)
	assert.NotEqual(t, 1, csv)
	return csv
}

func TestGz(t *testing.T) {
	gs := compressGz(t, _longStr)
	sr := unCompressGz(t, gs)
	assert.Equal(t, _longStr, sr)
}

func benchGz(zw *gzip.Writer, zr *gzip.Reader, s string) {
	wb := &bytes.Buffer{}
	zw.Reset(wb)
	zw.Write([]byte(s))
	zw.Close()
	gs := wb.String()

	rb := bytes.NewBufferString(gs)
	_ = zr.Reset(rb)
	arr, _ := ioutil.ReadAll(rb)
	rs := string(arr)
	if rs != s {
		println("expect", s, "but got", rs)
	}
}

func BenchmarkTestGz(b *testing.B) {
	// run the Fib function b.N times
	var zw *gzip.Writer = gzip.NewWriter(nil)
	var zr *gzip.Reader
	zr, _ = gzip.NewReader(nil)
	for n := 0; n < b.N; n++ {
		benchGz(zw, zr, "testing 1 2 3")
	}
	_ = zw.Close()
	_ = zr.Close()
}

func fakeCompressedData(t *testing.T, dt time.Time) gzRedisTest {
	data := make([]DeviceData, 24)
	for i := 0; i < len(data); i++ {
		f := float64(i)
		data[i] = DeviceData{float64(dt.Day()) + f + 0.1, f + 0.2, f + 0.3, f + 0.4}
	}
	ogMap := buildRedisMap(dt, "unit-test", data)
	assert.Equal(t, 3, len(ogMap))
	k := dt.Format("2006-01-02")
	v, ok := ogMap[k]
	assert.True(t, ok)
	assert.NotNil(t, v)
	gs := v.(string) //gzip string
	assert.NotEmpty(t, gs)
	varr := strings.Split(gs, ",")
	assert.NotEqual(t, 96, len(varr)) //should not equal 96 because it should not be an csv

	ogs := unCompressGz(t, gs)
	cm := strItfMap2strStrMap(ogMap)
	//return ogs, data, gs, cm
	return gzRedisTest{ogs, data, gs, cm, dt}
}

type gzRedisTest struct {
	ogs  string
	data []DeviceData
	gs   string
	cm   map[string]string
	dt   time.Time
}

func TestCacheGz(t *testing.T) {
	dt := time.Now().UTC().Truncate(time.Hour * 24)
	r := fakeCompressedData(t, dt)

	var zr *gzip.Reader
	combined := make(map[string]string)

	ensureFakeCompressData(t, zr, r, combined)

	res := _wc.parseDataFromRedis(dt, dt.Add(time.Hour*24), combined)

	assert.Equal(t, len(r.data), len(res))

	ensureGzTestOK(t, r, 0, res)
}

func ensureGzTestOK(t *testing.T, r gzRedisTest, j int, res []*WaterUsage) {
	for i := 0; i < len(r.data); i++ {
		og := r.data[i]
		rd := res[j]
		assert.Equal(t, og.Consumption, rd.Used)
		assert.Equal(t, og.FlowRate, rd.Rate)
		assert.Equal(t, og.Pressure, rd.PSI)
		assert.Equal(t, og.Temp, rd.Temp)
		hr := r.dt.Add(time.Duration(i) * time.Hour)
		assert.Equal(t, hr, rd.Date)
		j++
	}
}

func strItfMap2strStrMap(om map[string]interface{}) map[string]string {
	rr := make(map[string]string)
	for k, v := range om {
		bs := v.(string)
		rr[k] = bs
	}
	return rr
}

func ensureFakeCompressData(t *testing.T, zr *gzip.Reader, r gzRedisTest, combined map[string]string) map[string]string {
	n, zr, e := _wc.processRedisMap(zr, r.cm, combined)
	assert.Nil(t, e)
	assert.Equal(t, 1, n)
	assert.True(t, len(combined) >= 3)
	k := r.dt.Format("2006-01-02")
	vs, ok := combined[k]
	assert.True(t, ok)
	assert.NotEqual(t, r.gs, vs)
	varr := strings.Split(vs, ",")
	assert.Equal(t, 4*24, len(varr))
	assert.Equal(t, r.ogs, vs)
	return combined
}

func TestCacheGzBatch(t *testing.T) {
	tests := make([]gzRedisTest, 2)
	sumRows := 0
	sdt := time.Now().UTC().Truncate(time.Hour * 24)
	for x := 0; x < len(tests); x++ {
		dur := time.Duration(x) * time.Hour * 24
		dt := sdt.Add(dur)
		r := fakeCompressedData(t, dt)
		sumRows += len(r.data)
		tests[x] = r
	}

	var zr *gzip.Reader
	combined := make(map[string]string)

	for x := 0; x < len(tests); x++ {
		r := tests[x]
		ensureFakeCompressData(t, zr, r, combined)
	}
	assert.Equal(t, 2+len(tests), len(combined))

	res := _wc.parseDataFromRedis(tests[0].dt, tests[len(tests)-1].dt.Add(time.Hour), combined)
	assert.NotEmpty(t, res)
	assert.Equal(t, sumRows, len(res))

	for x := 0; x < len(tests); x++ {
		r := tests[x]
		j := x * len(r.data)
		ensureGzTestOK(t, r, j, res)
	}
}
