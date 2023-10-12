package main

import (
	"errors"
	"time"
)

type WaterReport interface {
	Consumption(rq *ConsumptionRequest) (*ConsumptionResponse, error)
}

func CreateWaterReport(log *Logger, cache WaterCacheReader) WaterReport {
	return &waterReport{log.CloneAsChild("Report"), cache}
}

type waterReport struct {
	log   *Logger
	cache WaterCacheReader
}

func (w *waterReport) Consumption(req *ConsumptionRequest) (*ConsumptionResponse, error) {
	if req == nil {
		return nil, errors.New("nil req")
	}
	var (
		rv = ConsumptionResponse{}
		es = make([]error, 0)
	)
	rv.Params.MacAddressList = req.MacAddressList
	rv.Params.StartDate = req.StartDate
	rv.Params.EndDate = req.EndDate
	rv.Params.Interval = req.Interval
	rv.Params.TimeZone = req.realTimezone.String()
	rv.Items = make([]*ReportModel, 0, len(rv.Params.MacAddressList))

	for _, macAddress := range rv.Params.MacAddressList {
		var (
			filtered, e = w.cache.Get(macAddress, req.realFrom, req.realTo)
			compressed  = w.applyInterval(w.convTz(filtered, req.realTimezone), req.Interval) //aggregate
			report      = ReportModel{MacAddress: macAddress, Items: compressed}
		)
		if e != nil {
			es = append(es, e)
		}
		rv.Items = append(rv.Items, &report)
	}
	return &rv, wrapErrors(es)
}

func (w *waterReport) convTz(
	parsedData []*WaterUsage, reqTimezone *time.Location) []*WaterUsage {
	for _, data := range parsedData {
		data.Date = data.Date.In(reqTimezone)
	}
	return parsedData
}

func (w *waterReport) truncateMonth(date time.Time) time.Time {
	return time.Date(date.Year(), date.Month(), 1, 0, 0, 0, 0, date.Location())
}

func (w *waterReport) applyInterval(data []*WaterUsage, interval string) []*WaterUsage {
	if interval == "" || interval == "1h" || len(data) == 0 {
		return data
	}
	rv := make([]*WaterUsage, 0)

	if interval == "1d" {
		hasDataCount := 0
		missing := 0
		total := 0
		delta := new(WaterUsage)
		delta.Date = data[0].Date.Truncate(time.Hour * 24)

		for _, d := range data {
			if !delta.Date.Equal(d.Date.Truncate(time.Hour * 24)) {

				delta.Used = cleanFloat(delta.Used)

				if hasDataCount > 0 {
					delta.PSI = cleanFloat(delta.PSI / float64(hasDataCount))
					delta.Temp = cleanFloat(delta.Temp / float64(hasDataCount))
					delta.Rate = cleanFloat(delta.Rate / float64(hasDataCount))
				}
				delta.Missing = missing == total

				rv = append(rv, delta)

				delta = new(WaterUsage)
				delta.Date = d.Date.Truncate(time.Hour * 24)
				hasDataCount = 0
				missing = 0
				total = 0
			}

			delta.Used += d.Used
			delta.PSI += d.PSI
			delta.Temp += d.Temp
			delta.Rate += d.Rate

			total++
			if d.Missing {
				missing++
			} else {
				hasDataCount++
			}
		}

		if total > 0 {
			delta.Used = cleanFloat(delta.Used)
			if hasDataCount > 0 {
				delta.PSI = cleanFloat(delta.PSI / float64(hasDataCount))
				delta.Temp = cleanFloat(delta.Temp / float64(hasDataCount))
				delta.Rate = cleanFloat(delta.Rate / float64(hasDataCount))
			}
			delta.Missing = missing == total
			rv = append(rv, delta)
		}
	}

	if interval == "1m" {
		hasDataCount := 0
		missing := 0
		total := 0
		delta := new(WaterUsage)
		delta.Date = w.truncateMonth(data[0].Date)

		for _, d := range data {

			if !delta.Date.Equal(w.truncateMonth(d.Date)) {
				delta.Used = cleanFloat(delta.Used)

				if hasDataCount > 0 {
					delta.PSI = cleanFloat(delta.PSI / float64(hasDataCount))
					delta.Temp = cleanFloat(delta.Temp / float64(hasDataCount))
					delta.Rate = cleanFloat(delta.Rate / float64(hasDataCount))
				}

				delta.Missing = missing == total

				rv = append(rv, delta)

				delta = new(WaterUsage)
				delta.Date = w.truncateMonth(d.Date)
				hasDataCount = 0
				missing = 0
				total = 0
			}

			delta.Used += d.Used
			delta.PSI += d.PSI
			delta.Temp += d.Temp
			delta.Rate += d.Rate

			total++
			if d.Missing {
				missing++
			} else {
				hasDataCount++
			}
		}

		if total > 0 {
			delta.Used = cleanFloat(delta.Used)

			if hasDataCount > 0 {
				delta.PSI = cleanFloat(delta.PSI / float64(hasDataCount))
				delta.Temp = cleanFloat(delta.Temp / float64(hasDataCount))
				delta.Rate = cleanFloat(delta.Rate / float64(hasDataCount))
			}
			delta.Missing = missing == total
			rv = append(rv, delta)
		}
	}
	return rv
}
