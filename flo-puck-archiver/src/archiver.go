package main

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"fmt"
	"strings"
	"sync/atomic"
	"time"
)

const ARCHIVE_MAX_BATCH_SIZE = 10000

type archiver struct {
	logger            *Logger
	s3                *S3Handler
	repo              *archiverRepo
	archiveCutoffDays int
	archiveDaysLimit  int
	state             int32
}

func newArchiver(logger *Logger, s3 *S3Handler, pgsql, readpgsql *PgSqlDb) *archiver {
	return &archiver{
		logger:            logger.CloneAsChild("Archiver"),
		s3:                s3,
		repo:              CreateArchiverRepo(pgsql, readpgsql, logger),
		archiveCutoffDays: defaultArchiveRecordsOlderThan,
		archiveDaysLimit:  defaultArchiveMaxLimit,
		state:             0,
	}
}

func (a *archiver) Open() {
	a.state = 1
}

func (a *archiver) IsOpen() bool {
	return a.state == 1
}

func (a *archiver) Run() {
	defer func() {
		a.logger.Info("closing")
		a.Close()
	}()

	log := a.logger.CloneAsChild("Run")
	cutoff := time.Now().UTC().AddDate(0, 0, 0-a.archiveCutoffDays)
	cutoff = cutoff.Truncate(DUR_1_DAY)
	currentArchiveEndDate, err := a.getAttributeAsDate(ATTRIBUTE_PUCK_TLM_ARCHIVE_END)
	if err != nil {
		log.Error("error reading last marker %v", err)
		return
	}
	currentArchiveEndDate = currentArchiveEndDate.UTC().Truncate(DUR_1_DAY)
	if !currentArchiveEndDate.Before(cutoff) {
		log.Notice("archiving not needed, current archive end date is %v", currentArchiveEndDate)
		return
	}

	offset := 0
	archiveEnd := currentArchiveEndDate
	log.Notice("archiving from %v until %v", currentArchiveEndDate, cutoff)

	for archiveEnd.Before(cutoff) && a.archiveDaysLimit > 0 {
		if a.state == 0 { // if we need to stop, abort this
			return
		}

		end := archiveEnd.Add(ARCHIVE_STEP_UP_DUR).UTC()
		blocks, err := a.GetArchivableEntries(archiveEnd, end, offset, ARCHIVE_MAX_BATCH_SIZE)

		if err != nil {
			log.Error("error reading entries, %v", err)
			return
		}

		if len(blocks) == 0 {
			archiveEnd = archiveEnd.Add(ARCHIVE_STEP_UP_DUR).UTC()
			// update attribute
			attr, err := a.repo.EditAttribute(ATTRIBUTE_PUCK_TLM_ARCHIVE_END)
			if err != nil {
				a.logger.Error("error getting attribute: %v", err)
				return
			}

			attr.Value = archiveEnd.Format(STD_DATE_LAYOUT)
			a.repo.UpdateAttribute(attr)

			log.Notice("updated marker to %v", attr.Value)
			// reset storage
			offset = 0
			a.archiveDaysLimit--
			continue
		}

		log.Notice("found %d archivable groups from %v until %v (offset %d)",
			len(blocks), archiveEnd, end, offset)
		if errA := a.moveToArchive(archiveEnd, offset, blocks); errA != nil {
			log.Fatal("failed to archive data, %v", errA)
			return
		}
		offset += ARCHIVE_MAX_BATCH_SIZE
	}
	err = a.DeleteArchivedEntries(archiveEnd)
	if err != nil {
		log.Error("failed to drop archived entries %v", err)
	}
}

func (a *archiver) DeleteArchivedEntries(until time.Time) error {
	deviceIdChunks := a.GetArchiveDeviceHints()
	if len(deviceIdChunks) == 0 {
		return a.repo.DeleteEntries(until)
	} else {
		for _, chunkIds := range deviceIdChunks {
			err := a.repo.DeleteEntriesWithHint(until, chunkIds)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

func (a *archiver) GetArchivableEntries(from, to time.Time, offset, limit int) (map[string][]string, error) {
	deviceIdChunks := a.GetArchiveDeviceHints()
	if len(deviceIdChunks) == 0 {
		return a.repo.GetArchivableEntries(from, to, offset, limit)
	} else {
		composed := make(map[string][]string)
		for _, chunkIds := range deviceIdChunks {
			chunk, err := a.repo.GetArchivableEntriesWithHint(from, to, offset, limit, chunkIds)
			if err != nil {
				return nil, err
			}
			for k, v := range chunk {
				composed[k] = append(composed[k], v...)
			}
		}
		return composed, nil
	}
}

func (a *archiver) GetArchiveDeviceHints() [][]string {
	hintsAttr, err := a.repo.EditAttribute(ATTRIBUTE_PUCK_TLM_ARCHIVE_HINT)
	if err != nil {
		return nil
	}
	if hintsAttr != nil && len(hintsAttr.Value) > 1 {
		return chunks(strings.Split(hintsAttr.Value, ","), 100) // any number is fine
	}
	return nil
}

func (a *archiver) Close() {
	if atomic.CompareAndSwapInt32(&a.state, 1, 0) {
		a.repo.Close()
	}
}

func (a *archiver) moveToArchive(date time.Time, offset int, buffer map[string][]string) error {
	totalBytes := 0
	totalEntries := 0
	for did, entries := range buffer {
		filePrefix := fmt.Sprintf("%v-%v-%v", did, date.Format(SHORT_DATE_LAYOUT), offset)

		totalEntries = totalEntries + len(entries)
		bytes, err := packageArchive(filePrefix, entries)
		if err != nil {
			return a.logger.Fatal("failed to add file into tarball %v", err)
		}
		pathPrefix := did[len(did)-1:]
		s3Key := fmt.Sprintf("tlm-%v/%v/%v/%v.tar.gz", pathPrefix, date.Format(SHORT_DATE_PATH_LAYOUT), did, filePrefix)

		err = a.s3.UploadFile(s3Key, bytes)
		if err != nil {
			return a.logger.Fatal("failed to upload to s3, %v", err)
		}
		totalBytes = totalBytes + len(bytes)
	}
	a.logger.Info("wrote %v, (%v rows)", lenReadable(totalBytes, 2), totalEntries)
	return nil
}

func (a *archiver) getAttributeAsDate(attrID string) (time.Time, error) {
	var res time.Time
	attr, err := a.repo.EditAttribute(attrID)
	if err != nil {
		return res, a.logger.Warn("getAttributeAsDate query failed, %v", err.Error())
	}
	return time.Parse(STD_DATE_LAYOUT, attr.Value)
}

func packageArchive(prefix string, entries []string) ([]byte, error) {
	buf := &bytes.Buffer{}
	tw := tar.NewWriter(buf)

	for idx, body := range entries {
		bs := []byte(body)
		hdr := &tar.Header{
			Name:    fmt.Sprintf("%v-%v.json", prefix, idx),
			Mode:    0600,
			Size:    int64(len(bs)),
			ModTime: time.Now().UTC(),
		}
		if err := tw.WriteHeader(hdr); err != nil {
			return nil, err
		}
		if _, err := tw.Write(bs); err != nil {
			return nil, err
		}
	}
	if err := tw.Close(); err != nil {
		return nil, err
	}
	return toGzip(buf.Bytes())
}

func toGzip(buf []byte) ([]byte, error) {
	zBuf := &bytes.Buffer{}
	zw := gzip.NewWriter(zBuf)
	_, e := zw.Write(buf)
	if e != nil {
		return nil, e
	}
	e = zw.Close()
	if e != nil {
		return nil, e
	}
	return zBuf.Bytes(), nil
}
