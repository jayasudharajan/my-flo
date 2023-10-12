package main

import (
	"os"
	"time"

	"github.com/pkg/errors"

	parquetLocal "github.com/xitongsys/parquet-go-source/local"
	parquetReader "github.com/xitongsys/parquet-go/reader"
	"github.com/xitongsys/parquet-go/source"
)

type TelemetryV7 struct {
}

func (_ *TelemetryV7) CastToParquetFile(file *os.File) (source.ParquetFile, error) {
	if file == nil {
		return nil, logWarn("TelemetryV7.CastToParquetFile: input is nil")
	}
	myFile := new(parquetLocal.LocalFile)
	myFile.FilePath = file.Name()
	myFile.File = file
	if _, err := file.Seek(0, 0); err != nil {
		return nil, logWarn("TelemetryV7.CastToParquetFile: can't seek %v => %v", myFile.FilePath, err.Error())
	}
	logTrace("TelemetryV7.CastToParquetFile: OK %v", myFile.FilePath)
	return myFile, nil
}

func (t *TelemetryV7) ReadAllFromFile(file *os.File) ([]TelemetryData, func(), error) {
	fr, ex := t.CastToParquetFile(file)
	if ex != nil {
		return nil, void, ex //already logged
	}
	fileName := file.Name()
	raw, closer, e := t.ReadAllFromParquet(fr)
	if e != nil {
		return nil, void, logWarn("TelemetryV7.ReadAllFromFile: can't read %v => %v", fileName, e.Error())
	}
	//fr.Close()
	res := make([]TelemetryData, 0, 300)
	for _, v := range raw {
		arr := t.expandV7ToV3(v)
		res = append(res, arr...)
	}
	logTrace("TelemetryV7.ReadAllFromFile: EXIT OK %v => %v rows", fileName, len(res))
	return res, func() { closer(); fr.Close() }, nil
}

func (_ *TelemetryV7) ReadAllFromParquet(fr source.ParquetFile) ([]Telemetry, func(), error) {
	pr, err := parquetReader.NewParquetReader(fr, new(Telemetry), 1)
	if err != nil {
		return nil, void, errors.Wrap(err, "Failed Reader Load")
	}

	num := int(pr.GetNumRows())
	rows := make([]Telemetry, num)
	if num > 0 {
		if err = pr.Read(&rows); err != nil {
			return nil, void, errors.Wrapf(err, "Failed File Load")
		}
	} else {
		logTrace("TelemetryV7.ReadAllFromParquet: EMPTY rows %v", fr)
	}
	return rows, func() { pr.ReadStop() }, nil
}

// Takes a V7 telemetry obj and converts it to backward compatible v3 array
func (v7 *TelemetryV7) expandV7ToV3(t Telemetry) []TelemetryData {
	//startTime := time.Unix(0, t.StartTS*int64(time.Millisecond)).UTC()
	legacyCollection := make([]TelemetryData, 0)
	for idx, _ := range t.TM {
		startTime := time.Unix(0, t.StartTS*int64(time.Millisecond)).UTC()
		startTime = startTime.Add(time.Second * time.Duration(idx))
		event := t.TM[idx]

		legacy := v7.telemetryPayloadV7toLegacyV3(&t, startTime, event)
		legacyCollection = append(legacyCollection, legacy)
	}
	//logTrace("TelemetryV7.expandV7ToV3: %v %v %v", t.DeviceID, t.StartTS, startTime.Format(time.RFC3339))
	return legacyCollection
}

func (_ *TelemetryV7) telemetryPayloadV7toLegacyV3(ref *Telemetry, eventTime time.Time, item PayLoad) TelemetryData {
	// this is legacy per second data, truncate milliseconds
	evtTime := eventTime.Truncate(time.Second).UnixNano()
	if evtTime <= 0 {
		return TelemetryData{}
	}

	rv := TelemetryData{}
	rv.MacAddress = ref.DeviceID
	rv.Timestamp = evtTime / int64(time.Millisecond)
	rv.TempF = item.Temperature
	rv.SystemMode = int(item.SystemMode)
	rv.ValveState = int(item.ValveState)
	//rv.WiFiStrength = 0 // should already be 0

	ct := 0
	totalPSI := float32(0)
	totalFlowRate := float32(0)
	if len(item.HR) > 0 {
		for _, flow := range item.HR {
			totalPSI += flow.Pressure
			totalFlowRate += flow.FlowRate
			ct++
		}
	}
	if totalPSI > 0 && ct > 0 {
		rv.PSI = totalPSI / float32(ct)
	}
	if totalFlowRate > 0 && ct > 0 {
		rv.GPM = totalFlowRate / float32(ct)
	}
	if rv.GPM > 0 && ct > 0 {
		rv.UseGallons = rv.GPM / 60
	}
	return rv
}

type Telemetry struct {
	DeviceID           string    `parquet:"name=did, type=UTF8"`
	StartTS            int64     `parquet:"name=start_ts, type=TIMESTAMP_MILLIS"`
	EndTS              int64     `parquet:"name=end_ts, type=TIMESTAMP_MILLIS"`
	TotalGallons       float32   `parquet:"name=total_gallons, type=FLOAT"`
	TotalCount         int16     `parquet:"name=total_count, type=INT_16"`
	AveragePSI         float32   `parquet:"name=avg_p, type=FLOAT"`
	AverageTemperature float32   `parquet:"name=avg_t, type=FLOAT"`
	AverageFlowRate    float32   `parquet:"name=avg_fr, type=FLOAT"`
	TM                 []PayLoad `parquet:"name=tm, type=LIST"` // up-to 300 entries. 1 data point per 1000ms
}
type PayLoad struct {
	Temperature float32 `parquet:"name=t, type=FLOAT"`   // 70-90
	SystemMode  int16   `parquet:"name=sm, type=INT_16"` // 2,3,5,7
	ValveState  int16   `parquet:"name=v, type=INT_16"`  // -1, 0,1,2,3
	HR          []Flow  `parquet:"name=hr, type=LIST"`   // up-to 10 entries. 1 data point per 100ms
}
type Flow struct {
	Pressure float32 `parquet:"name=p, type=FLOAT"`
	FlowRate float32 `parquet:"name=fr, type=FLOAT"`
}
