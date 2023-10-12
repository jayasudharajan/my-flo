package main

import (
	"context"
	"time"
)

const (
	DUR_1_DAY = time.Hour * 24
	DUR_4_HRS = time.Hour * 4
	DUR_1_HR  = time.Hour * 1
)

type lockFunc func(context.Context, string, time.Duration) (bool, error)
