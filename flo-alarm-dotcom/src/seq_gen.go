package main

import (
	"sync/atomic"
	"time"
)

var _seqGen SeqGen = &seqGen{}

// SeqGen logic satisfy Alarm.com SequenceId requirement for various response
// SEE: https://answers.alarm.com/ADC/Partner/Partner_Tools_and_Services/Growth_and_Productivity_Services/Integrations/Alarm.com_Standard_API/Sequence_ID
type SeqGen interface {
	Next() int64
}

type seqGen struct {
	counter int64
}

func (seq *seqGen) Next() int64 {
	const (
		lim   = 1_000_000 //1M
		limLo = lim - 1
	)
	var (
		ms = time.Now().UnixNano() / lim      //truncated milliseconds
		ns = ms * lim                         //conv back to nano
		c  = atomic.AddInt64(&seq.counter, 1) //counter val
	)
	//inc 1 each next, unless func is called 1M times each ms sec, we're good!
	if c == limLo { //attempt reset
		atomic.CompareAndSwapInt64(&seq.counter, limLo, 0)
	}
	return ns + c
}
