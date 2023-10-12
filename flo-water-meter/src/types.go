package main

import "time"

type ICloser interface {
	Open()
	Close()
}

type ITask interface {
	Name() string
	Spawn() (ICloser, error)
	CronExpression() string
}

type lockFunc func(string, time.Duration) (bool, error)
