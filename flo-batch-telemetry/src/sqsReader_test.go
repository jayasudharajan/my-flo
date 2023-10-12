package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_ParseS3ObjectKey_V8_Non_Sharded_Path_OK(t *testing.T) {
	_, version, device := parseS3ObjectKey("telemetry-v8.lf.csv.gz/year%3D2020/month%3D02/day%3D06/hhmm%3D0055/deviceid%3D0c1c57af5d19/0c1c57af5d19.f860bd47fcaabd692034f9c3168d9a59080673162e90b6ca9bd91f104d5c2a64.8.lf.csv.gz.telemetry")
	assert.Equal(t, "v8.lf.csv.gz", version)
	assert.Equal(t, "0c1c57af5d19", device)
}

func Test_ParseS3ObjectKey_V7_Non_Sharded_Path_OK(t *testing.T) {
	_, version, device := parseS3ObjectKey("telemetry-v7/year%3D2020/month%3D02/day%3D06/hhmm%3D0055/deviceid%3D0c1c57af5d19/0c1c57af5d19.f860bd47fcaabd692034f9c3168d9a59080673162e90b6ca9bd91f104d5c2a64.7.telemetry")
	assert.Equal(t, "v7", version)
	assert.Equal(t, "0c1c57af5d19", device)
}

func Test_ParseS3ObjectKey_V6_Non_Sharded_Path_OK(t *testing.T) {
	_, version, device := parseS3ObjectKey("telemetry-v6/year%3D2020/month%3D01/day%3D15/hhmm%3D0325/deviceid%3D2c6b7d06c1cc/2c6b7d06c1cc.b6a26123864631f29b7f8bbcd8c0865238b67875afcb94c5900152b6bef4c4a7.snappy.parquet")
	assert.Equal(t, "v6", version)
	assert.Equal(t, "2c6b7d06c1cc", device)
}

func Test_ParseS3ObjectKey_Sharded_Path_OK(t *testing.T) {
	_, version, device := parseS3ObjectKey("tlm-19/v8.lf.csv.gz/year%3D2020/month%3D02/day%3D06/hhmm%3D0055/deviceid%3D0c1c57af5d19/0c1c57af5d19.f860bd47fcaabd692034f9c3168d9a59080673162e90b6ca9bd91f104d5c2a64.8.lf.csv.gz.telemetry")
	assert.Equal(t, "v8.lf.csv.gz", version)
	assert.Equal(t, "0c1c57af5d19", device)
}
