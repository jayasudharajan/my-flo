package main

import (
	"fmt"
	"math/rand"
	_ "regexp"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func init() {
	rand.Seed(time.Now().Unix())
}

func TestTelemetryAggregatorBatch(t *testing.T) {
	f := FakeTelemetryData{macAddress: RandomMac()}
	dt := timeBucketUnix(time.Now().UTC().Unix(), 5)

	b1 := f.createBatch(dt, 14)
	b2 := f.createBatch(dt+16, 4)
	b3 := f.createBatch(dt+28, 1)

	a := CreateTelemetryAggregator(5)

	a.Append(b1)
	assert.Equal(t, 3, len(a.batchMap))
	assert.Equal(t, len(b1), a.InputRows)
	arr, ok := a.batchMap[dt]
	assert.Equal(t, true, ok)
	assert.Equal(t, 5, len(arr))
	arr, ok = a.batchMap[dt+5]
	assert.Equal(t, true, ok)
	assert.Equal(t, 5, len(arr))
	arr, ok = a.batchMap[dt+10]
	assert.Equal(t, true, ok)
	assert.Equal(t, 4, len(arr))

	a.Append(b2)
	assert.Equal(t, 4, len(a.batchMap))
	assert.Equal(t, len(b1)+len(b2), a.InputRows)
	arr, ok = a.batchMap[dt+15]
	assert.Equal(t, true, ok)
	assert.Equal(t, 4, len(arr))

	a.Append(b3)
	assert.Equal(t, 5, len(a.batchMap))
	assert.Equal(t, len(b1)+len(b2)+len(b3), a.InputRows)
	arr, ok = a.batchMap[dt+25]
	assert.Equal(t, true, ok)
	assert.Equal(t, 1, len(arr))

	res := a.Results()
	assert.Equal(t, 5, len(res))
	assert.True(t, a.InputRows > len(res))
	assert.Equal(t, len(b1)+len(b2)+len(b3), a.InputRows)
	assert.Equal(t, dt, res[0].Timestamp/1000)
	assert.Equal(t, dt+5, res[1].Timestamp/1000)
	assert.Equal(t, dt+10, res[2].Timestamp/1000)
	assert.Equal(t, dt+15, res[3].Timestamp/1000)
	assert.Equal(t, dt+25, res[4].Timestamp/1000)
}

type FakeTelemetryData struct {
	macAddress string
}

func RandomMac() string {
	bytes, _ := RandomBytes(6)
	return fmt.Sprintf("%x", string(bytes))
}

func RandomBytes(size int) (blk []byte, err error) {
	blk = make([]byte, size)
	_, err = rand.Read(blk)
	return
}

func (f *FakeTelemetryData) createBatch(startUUS int64, seconds int64) []TelemetryData {
	res := make([]TelemetryData, seconds)
	var i int64
	for i = 0; i < seconds; i++ {
		t := TelemetryData{}
		t.MacAddress = f.macAddress
		t.Timestamp = (startUUS + i) * 1000

		t.GPM = float32(rand.Int31n(10)*10) / 10
		t.UseGallons = t.GPM / 60
		t.TempF = float32(rand.Int31n(100))
		t.PSI = float32(rand.Int31n(50) + 20)
		t.SystemMode = int(rand.Int31n(3))
		t.ValveState = int(rand.Int31n(2))
		res[i] = t
	}
	return res[0:i]
}
