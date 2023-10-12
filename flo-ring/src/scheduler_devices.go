package main

import (
	"context"
	"time"
)

type DeviceScheduleRunContext struct {
	cleaner   Cleanup
	logger    *Logger
	locker    lockFunc
	startTime time.Time
	state     int
}

const (
	DEVICE_STATE_RUNNING int = iota
	DEVICE_STATE_STOPPED int = iota
	DEVICE_STATE_ERROR
)

func NewDeviceScheduleRunContext(cleanup Cleanup, lockerFunc lockFunc, logger *Logger) *DeviceScheduleRunContext {
	ctx := DeviceScheduleRunContext{
		cleaner: cleanup,
		locker:  lockerFunc,
		logger:  logger.CloneAsChild("DeviceScheduleRunContext"),
		state:   int(DEVICE_STATE_RUNNING),
	}
	return &ctx
}

func (ctx *DeviceScheduleRunContext) Open() {
	ctx.startTime = time.Now().UTC()
	ctx.cleaner.Open()
	go ctx.process()
}

func (ctx *DeviceScheduleRunContext) Close() {
	tryClose(ctx.cleaner, ctx.logger, 0)
}

func (ctx *DeviceScheduleRunContext) logRun() {
	diff := time.Now().UTC().Sub(ctx.startTime)
	ll := LL_NOTICE
	if ctx.state == DEVICE_STATE_ERROR {
		ll = LL_WARN
	}
	ctx.logger.Log(ll, "cronDeviceRun: Finished, job took %v", diff)
}

func (ctx *DeviceScheduleRunContext) canCleanUpDevices(c context.Context) bool {
	ctx.logger.PushScope("canCleanUpDevices")
	defer ctx.logger.PopScope()

	ok, e := ctx.locker(c, "mutex:DeviceScheduleRunContext:deviceCleanup", DUR_1_HR)
	ctx.logger.IfWarnF(e, "cronRun: failed to acquire lock")
	return ok
}

func (ctx *DeviceScheduleRunContext) process() {
	defer ctx.logRun()

	c := context.Background()

	if ctx.canCleanUpDevices(c) {
		ctx.logger.Notice("cronDeviceRun: Cleaning up devices")
		ctx.cleaner.CleanDevices(c, &CleanReq{Force: true})
	} else {
		ctx.logger.Notice("cronDeviceRun: Skipping cleaning up devices")
	}
}
