package main

import (
	"strconv"
	"sync/atomic"
	"time"
)

const (
	ENVVAR_ARCHIVE_CRON_SCHEDULE           = "FLO_ARCHIVE_TASK_CRON_SCHEDULE"
	ENVVAR_TIMESCALE_ARCHIVE_CUTOFF        = "FLO_TIMESCALE_ARCHIVE_CUTOFF_DAYS"
	ENVVAR_TIMESCALE_ARCHIVE_PROCESS_LIMIT = "FLO_TIMESCALE_ARCHIVE_PROC_LIMIT_DAYS"
	ARCHIVE_MAX_BATCH_SIZE                 = 4000
	ARCHIVE_STEP_UP_DUR                    = DUR_1_DAY
)

type ArchiveTsdTask struct {
	locker            lockFunc
	waterReader       WaterReader
	waterWriter       WaterWriter
	archiveCutoffDays int
	archiveDaysLimit  int
	log               *Logger
}

func NewArchiveTsdTask(waterReader WaterReader, waterWriter WaterWriter, locker lockFunc) *ArchiveTsdTask {
	ret := ArchiveTsdTask{
		locker:      locker,
		waterReader: waterReader,
		waterWriter: waterWriter,
		log:         _log.CloneAsChild("Archie"),
	}
	ret.archiveCutoffDays = 100
	if c, err := strconv.Atoi(getEnvOrDefault(ENVVAR_TIMESCALE_ARCHIVE_CUTOFF, "")); err == nil && c > 0 {
		ret.archiveCutoffDays = c
	}

	ret.archiveDaysLimit = 2
	if l, err := strconv.Atoi(getEnvOrDefault(ENVVAR_TIMESCALE_ARCHIVE_PROCESS_LIMIT, "")); err == nil && l > 0 {
		ret.archiveDaysLimit = l
	}
	return &ret
}

func (task *ArchiveTsdTask) Name() string {
	return task.log.GetName()
}

func (task *ArchiveTsdTask) Spawn() (ICloser, error) {
	if ok, err := task.locker("ArchiveTSDB", DUR_TASK_LOCK); !ok {
		task.log.IfWarnF(err, "could not get lock to run task")
		return nil, err
	}
	return &ArchiveTaskCtx{
		waterReader:       task.waterReader,
		waterWriter:       task.waterWriter,
		archiveCutoffDays: task.archiveCutoffDays,
		archiveDaysLimit:  task.archiveDaysLimit,
		log:               task.log.CloneAsChild("cx"),
	}, nil
}

func (task *ArchiveTsdTask) CronExpression() string {
	return getEnvOrDefault(ENVVAR_ARCHIVE_CRON_SCHEDULE, "0 0 * * *") //once a day by default
}

type ArchiveTaskCtx struct {
	archiveCutoffDays int
	archiveDaysLimit  int
	state             int32
	waterReader       WaterReader
	waterWriter       WaterWriter
	log               *Logger
}

func (ctx *ArchiveTaskCtx) Open() {
	if atomic.CompareAndSwapInt32(&ctx.state, 0, 1) {
		ctx.log.Debug("Opening")
		go ctx.run()
	}
}

func (ctx *ArchiveTaskCtx) run() {
	if _noWrite {
		return
	}

	cutoff := time.Now().UTC().AddDate(0, 0, 0-ctx.archiveCutoffDays).Truncate(DUR_1_DAY)
	var currentArchiveEndDate time.Time
	if dt, err := ctx.waterReader.GetArchiveEndTime(); err != nil {
		ctx.log.IfErrorF(err, "run")
		return
	} else {
		currentArchiveEndDate = dt.UTC().Truncate(DUR_1_DAY)
	}

	if !currentArchiveEndDate.Before(cutoff) {
		ctx.log.Notice("run archiving not needed, current archive end date is %v", currentArchiveEndDate)
		return
	}
	offset := 0
	dataWritten := 0
	archiveEnd := currentArchiveEndDate
	ctx.log.Notice("run archiving from %v until %v", currentArchiveEndDate, cutoff)

	for archiveEnd.Before(cutoff) && ctx.archiveDaysLimit > 0 {
		if state := atomic.LoadInt32(&ctx.state); state == 0 { // if we need to stop, abort this
			return
		}
		end := archiveEnd.Add(ARCHIVE_STEP_UP_DUR).UTC()
		a := ctx.waterReader.GetArchiveableRows(archiveEnd, end, offset, ARCHIVE_MAX_BATCH_SIZE)
		rowsCount := len(a)
		if rowsCount == 0 {
			if dataWritten > 0 {
				ctx.updateAttr(WATER_METER_ATTRIBUTE_ARCHIVE_END, archiveEnd)
			}
			archiveEnd = archiveEnd.Add(ARCHIVE_STEP_UP_DUR).UTC()
			offset = 0
			ctx.archiveDaysLimit--
			continue
		}

		ctx.log.Notice("run found %d archivable groups from %v until %v (offset %d)", len(a), archiveEnd, end, offset)
		dataWritten += rowsCount
		ctx.waterWriter.MoveToArchive(a, "ts")
		offset += rowsCount
	}
	ctx.updateAttr(WATER_METER_ATTRIBUTE_LIVE_START, archiveEnd)
}

func (ctx *ArchiveTaskCtx) updateAttr(attrName string, archiveEnd time.Time) {
	attr, err := ctx.waterWriter.EditAttribute(attrName)
	if err != nil {
		ctx.log.IfErrorF(err, "updateAttr")
		return
	}
	attr.Value = archiveEnd.Format(STD_DATE_LAYOUT)
	ctx.waterWriter.UpdateAttribute(attr)
	ctx.log.Notice("updateAttr set marker %v to %v", attrName, attr.Value)
}

func (ctx *ArchiveTaskCtx) Close() {
	if atomic.CompareAndSwapInt32(&ctx.state, 1, 0) {
		ctx.log.Debug("Closing")
	}
}
