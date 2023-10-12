package main

import (
	"fmt"
	"sort"
	"time"
)

// TelemetryData v3-8 compatible general format
type TelemetryData struct {
	MacAddress   string  `json:"did"`
	WiFiStrength int     `json:"rssi"`
	ValveState   int     `json:"v"`
	SystemMode   int     `json:"sm"`
	Timestamp    int64   `json:"ts"`
	PSI          float32 `json:"p"`
	TempF        float32 `json:"t"`
	GPM          float32 `json:"wf"`
	UseGallons   float32 `json:"f"`
}

func (t TelemetryData) String() string {
	return fmt.Sprintf("%v %v", t.MacAddress, time.Unix(t.Timestamp/1000, 0).Format("T0601021504"))
}

type TelemetryAggregator struct {
	BucketSec     int64 //bucket size in seconds
	InputRows     int
	batchMap      map[int64][]TelemetryData
	BatchMapCount int
}

func CreateTelemetryAggregator(bucketSec int64) *TelemetryAggregator {
	return &TelemetryAggregator{
		BucketSec: bucketSec,
		batchMap:  make(map[int64][]TelemetryData),
	}
}

func (a *TelemetryAggregator) aggregate(ts int64, arr []TelemetryData) *TelemetryData {
	if a == nil {
		return nil
	}
	r := new(TelemetryData)
	j, floS := 0, 0
	for _, c := range arr {
		if !isValidMacAddress(c.MacAddress) {
			continue
		}
		if j == 0 {
			r.MacAddress = c.MacAddress
			r.Timestamp = ts * 1000
		}
		if c.UseGallons > 0 || c.GPM > 0 {
			floS++
		}
		r.UseGallons += c.UseGallons
		//r.WiFiStrength += c.WiFiStrength
		r.ValveState += c.ValveState
		r.SystemMode += c.SystemMode
		r.PSI += c.PSI
		r.TempF += c.TempF
		r.GPM += c.GPM
		j++
	}
	if j == 0 {
		return nil
	}
	//r.WiFiStrength /= j
	r.ValveState /= j
	r.SystemMode /= j
	fCount := float32(j)
	r.PSI /= fCount
	r.TempF /= fCount
	if floS > 0 {
		r.GPM /= float32(floS)
	} else {
		r.GPM = 0
	}
	return r
}

func (a *TelemetryAggregator) Append(inputs []TelemetryData) {
	if a == nil || len(inputs) == 0 {
		return
	}
	for _, v := range inputs {
		ts := timeBucketUnix(v.Timestamp/1000, a.BucketSec)
		if arr, ok := a.batchMap[ts]; ok {
			if len(arr) >= int(a.BucketSec) {
				continue
			}
			a.batchMap[ts] = append(arr, v)
			a.InputRows++
		} else {
			a.batchMap[ts] = make([]TelemetryData, 1, a.BucketSec)
			a.batchMap[ts][0] = v
			a.InputRows++
			a.BatchMapCount++
		}
	}
	return
}

func (a *TelemetryAggregator) Results() []TelemetryData {
	if a == nil {
		return nil
	}
	res := make([]TelemetryData, a.BatchMapCount)
	i := 0
	for k, v := range a.batchMap {
		r := a.aggregate(k, v)
		if r != nil {
			res[i] = *r
			i++
		}
	}
	res = res[0:i]
	if i > 0 {
		sort.Slice(res, func(i, j int) bool {
			return res[i].Timestamp < res[j].Timestamp
		})
	}
	return res
}
