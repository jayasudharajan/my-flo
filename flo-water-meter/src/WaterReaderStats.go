package main

import (
	"fmt"
	"math"
	"sync"
	"sync/atomic"
	"time"
)

type WaterReaderStats struct {
	_start int64      //when the stats capture started
	_state int32      //1= running, 0= stopped
	_mux   sync.Mutex //use to sync reset print ops

	errors        int64 //how many errors during fetch or read so far
	rows          int64 //how many rows read in the response
	queries       int64 //how many queries sent
	tookMsSum     int64 //how long everything added up
	cacheAttempts int64 //how many device & hr bucket cache attempted
	tsCount       int64 //how many ts device & hr bucket cached
	tsaCount      int64 //how many ts archive device & hr bucket cached
}

func CreateWaterReaderStats() *WaterReaderStats {
	s := WaterReaderStats{
		_start: time.Now().UTC().Unix()}
	return &s
}

func (s *WaterReaderStats) Increment(counter *int64, by int64) {
	s._mux.Lock()
	*counter += by
	s._mux.Unlock()
}

func (s *WaterReaderStats) IncrErrors() {
	s.Increment(&s.errors, 1)
}

func (s *WaterReaderStats) IncrRows(count int64) {
	s.Increment(&s.rows, count)
}

func (s *WaterReaderStats) IncrQueries() {
	s.Increment(&s.queries, 1)
}

func (s *WaterReaderStats) IncrQueryDuration(ms float64) {
	v := int64(math.Round(ms))
	s.Increment(&s.tookMsSum, v)
}

func (s *WaterReaderStats) IncrTsCount() {
	s.Increment(&s.tsCount, 1)
}

func (s *WaterReaderStats) IncrTsACount() {
	s.Increment(&s.tsaCount, 1)
}

func (s *WaterReaderStats) IncrAttempts() {
	s.Increment(&s.cacheAttempts, 1)
}

func (s *WaterReaderStats) ResetSPrint() string { // print existing stats then refresh to 0
	s._mux.Lock()
	st := atomic.SwapInt64(&s._start, time.Now().UTC().Unix())

	rows := atomic.SwapInt64(&s.rows, 0)
	errs := atomic.SwapInt64(&s.errors, 0)
	q := atomic.SwapInt64(&s.queries, 0)
	t := atomic.SwapInt64(&s.tookMsSum, 0)
	tsCount := atomic.SwapInt64(&s.tsCount, 0)
	tsaCount := atomic.SwapInt64(&s.tsaCount, 0)
	attempts := atomic.SwapInt64(&s.cacheAttempts, 0)
	cErr := attempts - tsCount - tsaCount
	s._mux.Unlock()

	var avg int64 = 0
	if q > 0 {
		avg = t / q
	}
	since := fmtDuration(time.Since(time.Unix(st, 0).UTC()))
	return fmt.Sprintf("WaterReaderStats: %v queries (%vms avg), %v rows, %v errors in last %v. TS+A: %v+%v. %v attemps, %v failures",
		q, avg, rows, errs, since, tsCount, tsaCount, attempts, cErr)
}

// will not block & will keep its own state
func (s *WaterReaderStats) StartPrintStatsInterval() {
	go s.printStatsInterval() // will run on a thread
}

func (s *WaterReaderStats) printStatsInterval() {
	if atomic.CompareAndSwapInt32(&s._state, 0, 1) {
		for atomic.LoadInt32(&s._state) == 1 {
			time.Sleep(time.Minute) // print once a minute
			logInfo(s.ResetSPrint())
		}
	} else {
		logDebug("waterReader.printStatsInterval: already running")
	}
}

// will not block & will keep its own state
func (s *WaterReaderStats) StopPrintStatsInterval() {
	atomic.StoreInt32(&s._state, 0)
}
