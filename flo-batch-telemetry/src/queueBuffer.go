package main

import (
	"strconv"
	"sync"
	"sync/atomic"
	"time"
)

const ENVVAR_QUEUE_BUF_SIZE = "FLO_QUEUE_BUF_SIZE"

// logic to buffer queue request so we don't hit redis as hard
type queueBuffer struct {
	queueFunc func(...string) error
	buffer    []string
	bufMax    int   //max items to hold in buffer
	bufHoldS  int64 //max seconds to hold buffer
	lastFlush int64 //unix time
	mux       sync.Mutex
	log       *Logger
	state     int32 //0=close, 1=open
}

func CreateQueueBuffer(queueFunc func(...string) error, log *Logger) *queueBuffer {
	q := queueBuffer{
		queueFunc: queueFunc,
		log:       log.CloneAsChild("qBuf"),
		bufHoldS:  5, //default to 5s buffer flush hold
		mux:       sync.Mutex{},
		lastFlush: time.Now().Unix(),
	}
	if n, e := strconv.Atoi(getEnvOrDefault(ENVVAR_QUEUE_BUF_SIZE, "")); e != nil || n <= 0 {
		q.bufMax = 30 //default to 20 items in buffer max
	} else {
		q.bufMax = n
	}
	q.buffer = make([]string, 0, q.bufMax)
	q.log.Notice("%v=%v", ENVVAR_QUEUE_BUF_SIZE, q.bufMax)
	return &q
}

func (q *queueBuffer) Open() {
	if atomic.CompareAndSwapInt32(&q.state, 0, 1) {
		sleep := time.Duration(q.bufHoldS) * time.Second
		q.log.Notice("Open: flushing every %v", sleep)
		for atomic.LoadInt32(&q.state) == 1 {
			time.Sleep(sleep)
			q.Flush(false)
		}
		q.log.Info("Open: exit")
	} else {
		q.log.Warn("Open: already open")
	}
}

func (q *queueBuffer) Close() {
	if atomic.CompareAndSwapInt32(&q.state, 1, 0) {
		q.log.Notice("Close: closing")
		q.Flush(false)
	} else {
		q.log.Warn("Close: already closed")
	}
}

func (q *queueBuffer) Queue(arr ...string) error {
	q.mux.Lock()
	defer q.mux.Unlock()

	var (
		qLen = len(q.buffer)
		es   = make([]error, 0)
	)
	for _, s := range arr {
		q.buffer = append(q.buffer, s)
		qLen++
		if qLen >= q.bufMax {
			if e := q.Flush(true); e != nil {
				es = append(es, e)
			}
			qLen = 0
		}
	}
	return wrapErrors(es)
}

func (q *queueBuffer) Flush(noLock bool) error {
	defer panicRecover(q.log, "Flush: %v", noLock)
	if !noLock {
		q.mux.Lock()
		defer q.mux.Unlock()
	}
	var (
		now  = time.Now().Unix()
		qLen = len(q.buffer)
	)
	if qLen == 0 || q.lastFlush > now-q.bufHoldS {
		q.log.Trace("Flush: noLock=%v | skipping", noLock)
		return nil //not yet time to flush
	}
	q.lastFlush = now
	err := q.queueFunc(q.buffer...)
	q.log.Debug("Flush: noLock=%v | %v items | %v", noLock, qLen, err)
	q.buffer = q.buffer[:0] //empty buffer
	return err
}
