package main

import (
	"math/rand"
	_ "regexp"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

var _dummyWriter *waterWriter

func init() {
	rand.Seed(time.Now().Unix())
	_dummyWriter = &waterWriter{log: _log}
}

func TestBuildWriteQuery_III(t *testing.T) {
	fullBatch := []*AggregateTelemetry{
		createFakeTelemetry(300),
		createFakeTelemetry(300),
		createFakeTelemetry(300),
	}

	sql := _dummyWriter.buildWriteQuery(fullBatch...)
	dataCheck(t, sql, fullBatch...)
	stringCounter(t, sql, map[string]int{
		"INSERT INTO ":  1,
		"),(":           2,
		"DO NOTHING;":   1,
		"DO UPDATE SET": 0,
		";":             1,
	})
}

func TestBuildWriteQuery_IIU(t *testing.T) {
	fullBatch := []*AggregateTelemetry{
		createFakeTelemetry(300),
		createFakeTelemetry(300),
		createFakeTelemetry(25),
	}

	sql := _dummyWriter.buildWriteQuery(fullBatch...)
	dataCheck(t, sql, fullBatch...)
	stringCounter(t, sql, map[string]int{
		"INSERT INTO ":  2,
		"),(":           1,
		"DO NOTHING;":   1,
		"DO UPDATE SET": 1,
		";":             2,
	})
}

func TestBuildWriteQuery_IUI(t *testing.T) {
	fullBatch := []*AggregateTelemetry{
		createFakeTelemetry(300),
		createFakeTelemetry(25),
		createFakeTelemetry(300),
	}

	sql := _dummyWriter.buildWriteQuery(fullBatch...)
	dataCheck(t, sql, fullBatch...)
	stringCounter(t, sql, map[string]int{
		"INSERT INTO ":  3,
		"),(":           0,
		"DO NOTHING;":   2,
		"DO UPDATE SET": 1,
		";":             3,
	})
}

func TestBuildWriteQuery_UII(t *testing.T) {
	fullBatch := []*AggregateTelemetry{
		createFakeTelemetry(25),
		createFakeTelemetry(300),
		createFakeTelemetry(300),
	}

	sql := _dummyWriter.buildWriteQuery(fullBatch...)
	dataCheck(t, sql, fullBatch...)
	stringCounter(t, sql, map[string]int{
		"INSERT INTO ":  2,
		"),(":           1,
		"DO NOTHING;":   1,
		"DO UPDATE SET": 1,
		";":             2,
	})
}

func TestBuildWriteQuery_IUU(t *testing.T) {
	fullBatch := []*AggregateTelemetry{
		createFakeTelemetry(300),
		createFakeTelemetry(11),
		createFakeTelemetry(25),
	}

	sql := _dummyWriter.buildWriteQuery(fullBatch...)
	dataCheck(t, sql, fullBatch...)
	stringCounter(t, sql, map[string]int{
		"INSERT INTO ":  3,
		"),(":           0,
		"DO NOTHING;":   1,
		"DO UPDATE SET": 2,
		";":             3,
	})
}

func TestBuildWriteQuery_UIU(t *testing.T) {
	fullBatch := []*AggregateTelemetry{
		createFakeTelemetry(1),
		createFakeTelemetry(300),
		createFakeTelemetry(19),
	}

	sql := _dummyWriter.buildWriteQuery(fullBatch...)
	dataCheck(t, sql, fullBatch...)
	stringCounter(t, sql, map[string]int{
		"INSERT INTO ":  3,
		"),(":           0,
		"DO NOTHING;":   1,
		"DO UPDATE SET": 2,
		";":             3,
	})
}

func TestBuildWriteQuery_UUI(t *testing.T) {
	fullBatch := []*AggregateTelemetry{
		createFakeTelemetry(23),
		createFakeTelemetry(2),
		createFakeTelemetry(300),
	}

	sql := _dummyWriter.buildWriteQuery(fullBatch...)
	dataCheck(t, sql, fullBatch...)
	stringCounter(t, sql, map[string]int{
		"INSERT INTO ":  3,
		"),(":           0,
		"DO NOTHING;":   1,
		"DO UPDATE SET": 2,
		";":             3,
	})
}

func TestBuildWriteQuery_UUU(t *testing.T) {
	fullBatch := []*AggregateTelemetry{
		createFakeTelemetry(299),
		createFakeTelemetry(10),
		createFakeTelemetry(1),
	}

	sql := _dummyWriter.buildWriteQuery(fullBatch...)
	dataCheck(t, sql, fullBatch...)
	stringCounter(t, sql, map[string]int{
		"INSERT INTO ":  3,
		"),(":           0,
		"DO NOTHING;":   0,
		"DO UPDATE SET": 3,
		";":             3,
	})
}

func dataCheck(t *testing.T, sql string, batch ...*AggregateTelemetry) {
	for _, a := range batch {
		assert.Contains(t, sql, a.DeviceId)
		assert.Contains(t, sql, pgConvByteArrToBitStr(a.SecondsFill))
	}
}

func stringCounter(t *testing.T, sql string, sc map[string]int) {
	for k, v := range sc {
		//assert.Equal(t, v, countMatch(sql, k), k)
		assert.Equal(t, v, strings.Count(sql, k), k)
	}
}

var _counter int64 = 0

const MIN_TIME_BUCKET_MS int64 = 5 * 60 * 60 * 1000 // 5 minute in ms

func createFakeTelemetry(seconds int32) *AggregateTelemetry {
	nowMS := time.Now().Unix() * 1000

	a := AggregateTelemetry{}
	a.DeviceId = strings.Replace(uuid.New().String(), "-", "", -1)

	a.TimeBucket = nowMS + (atomic.AddInt64(&_counter, 1) * MIN_TIME_BUCKET_MS) - (nowMS % MIN_TIME_BUCKET_MS) //slice into bucket
	a.Seconds = seconds
	a.SecondsFill = make([]byte, FILL_BYTES)
	var i int32
	for i = 0; i < FILL_BYTES; i++ {
		if rand.Int()%7 == 0 { //randomize usage, everything else will be 0
			v := byte(rand.Int31() % 255)
			if i == 0 && v > 16 {
				v = 16
			}
			a.SecondsFill[i] = v
			a.SecondsFlo++

			gpm := float32(rand.Int31n(10)*10) / 10
			a.UseGallons += gpm / 60

			a.GpmSum += gpm
			a.GpmMinFlo = minFloat32(a.GpmMinFlo, gpm)
			a.GpmMax = maxFloat32(a.GpmMinFlo, gpm)

			psi := float32(rand.Int31n(50) + 20)
			a.PsiSum += psi
			a.PsiMin = minFloat32(a.PsiMin, psi)
			a.PsiMax = maxFloat32(a.PsiMax, psi)

			temp := float32(rand.Int31n(100))
			a.TempSum += temp
			a.TempMin = minFloat32(a.TempMin, temp)
			a.TempMax = maxFloat32(a.TempMax, temp)
		}
	}
	return &a
}

func minFloat32(a float32, b float32) float32 {
	if a >= b {
		return b
	} else {
		return a
	}
}
func maxFloat32(a float32, b float32) float32 {
	if a >= b {
		return a
	} else {
		return b
	}
}
