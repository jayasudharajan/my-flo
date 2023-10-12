package main

import (
	"container/list"
)

type SimpleQ struct {
	Q *list.List
}

// New creates a new SimpleQ
func (sq *SimpleQ) New() SimpleQ {
	sq.Q = list.New()
	return *sq
}

// Enqueue adds an item to the end of the queue
func (sq *SimpleQ) Enqueue(t interface {}) {
	sq.Q.PushBack(t)
}

// Dequeue removes an item from the start of the queue
func (sq *SimpleQ) Dequeue() bool {
	if sq.Q.Len() > 0 {
		e := sq.Q.Front()
		sq.Q.Remove(e)
		return true
	}
	return false
}

// Front returns the item next in the queue, without removing it
func (sq *SimpleQ) Front() (interface {}, bool) {
	if sq.Q.Len() > 0 {
		return sq.Q.Front().Value, true
	}
	return nil, false
}

// IsEmpty returns true if the queue is empty
func (sq *SimpleQ) IsEmpty() bool {
	return sq.Q.Len() == 0
}

// Size returns the number of Items in the queue
func (sq *SimpleQ) Size() int {
	return sq.Q.Len()
}