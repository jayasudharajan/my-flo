package main

import (
	"compress/gzip"
	"errors"
	"fmt"
	"os"
	path2 "path"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gocarina/gocsv"
)

type gzFileWriter struct { //proxy the 2 internal classes to satisfy IFileWriter
	path        string
	file        *os.File
	gzw         *gzip.Writer
	log         *Logger
	state       int32 //0 == open, 1 == closed, 2 == removed
	mux         sync.RWMutex
	appendNames map[string]BulkFileSource
	rows        int32
}

func RandomCsvGzFile(basePath, typeName string, l *Logger) (*gzFileWriter, error) {
	var (
		log        = l.CloneAsChild("gz")
		uuid, _, e = newUuid()
		tmpFn      string
	)
	if e != nil {
		uuid, _, e = newUuid() //try again
		if e != nil {
			return nil, log.IfErrorF(e, "can't generate UUID!")
		}
	}
	if typeName == "" {
		tmpFn = fmt.Sprintf("%v/%v.csv.gz", basePath, uuid)
	} else {
		tmpFn = fmt.Sprintf("%v/%v.%v.csv.gz", basePath, uuid, typeName)
	}
	return CreateCsvGzFile(tmpFn, log)
}
func CreateCsvGzFile(path string, l *Logger) (*gzFileWriter, error) {
	log := l
	if l.GetName() != "gz" {
		log = l.CloneAsChild("gz")
	}
	tmp, e := os.Create(path)
	if e != nil {
		return nil, log.Error("can't create %v", path)
	}
	return &gzFileWriter{
		path:        path,
		file:        tmp,
		gzw:         gzip.NewWriter(tmp),
		log:         log,
		mux:         sync.RWMutex{},
		appendNames: make(map[string]BulkFileSource),
	}, nil
}
func (cg *gzFileWriter) AppendFilesCount() int32 {
	cg.mux.RLock()
	defer cg.mux.RUnlock()

	n := int32(len(cg.appendNames))
	return n
}
func (cg *gzFileWriter) AppendKeys() (keys []string) {
	cg.mux.RLock()
	defer cg.mux.RUnlock()

	keys = make([]string, 0, len(cg.appendNames))
	for k, _ := range cg.appendNames {
		keys = append(keys, k)
	}
	return keys
}
func (cg *gzFileWriter) AppendRowsCount() int32 {
	cg.mux.RLock()
	defer cg.mux.RUnlock()
	return cg.rows
}
func (cg *gzFileWriter) State() int32 {
	if cg == nil {
		return -1
	}
	return atomic.LoadInt32(&cg.state)
}
func (cg *gzFileWriter) Name() string { //os.File interface proxy
	if cg == nil || cg.file == nil {
		return ""
	}
	return cg.file.Name()
}
func (cg *gzFileWriter) Write(p []byte) (int, error) { //os.File & os.Writer interface proxy
	if atomic.LoadInt32(&cg.state) == 0 {
		return cg.gzw.Write(p)
	}
	return 0, errors.New("gzFileWriter: already closed")
}
func (cg *gzFileWriter) Close() error { //os.File & os.Writer interface proxy
	if cg == nil {
		return errors.New("binding is nil")
	}
	if atomic.CompareAndSwapInt32(&cg.state, 0, 1) {
		cg.log.PushScope("Close", cg.Name())
		defer cg.log.PopScope()
		cg.mux.Lock()
		defer cg.mux.Unlock()

		var es = make([]error, 0)
		if e := cg.gzw.Close(); e != nil {
			es = append(es, cg.log.IfWarnF(e, "gzw"))
		}
		if e := cg.file.Close(); e != nil {
			es = append(es, cg.log.IfWarnF(e, "file"))
		}
		if len(es) != 0 {
			return wrapErrors(es)
		}
		cg.log.Trace("OK")
	}
	return nil
}
func (cg *gzFileWriter) Dispose() { //delete from file system, also remove file from OS
	if cg == nil {
		return
	}
	cg.Close()
	if atomic.CompareAndSwapInt32(&cg.state, 1, 2) {
		cg.log.PushScope("Dispose", cg.Name())
		defer cg.log.Dispose() //no need to popScope, dispose rm scopes :)

		cg.gzw = nil
		cg.file = nil
		cg.appendNames = nil
		if e := os.Remove(cg.path); e != nil {
			return
		} else {
			cg.path = ""
			cg.log.Debug("OK")
		}
	}
	return
}
func (cg *gzFileWriter) Path() string {
	return cg.path
}

func (b *gzFileWriter) AppendCsv(meta *BulkFileSource, entries interface{}, entryLen int32) (rows int32, err error) {
	started := time.Now()
	name := meta.AppenderName
	if name == "" {
		name = meta.SourceUri
		if strings.HasPrefix(meta.SourceUri, "telemetry-") { // TODO remove when shard prefix is done
			name = path2.Base(meta.SourceUri)
		}
	}
	b.log.PushScope("appendCSV", name, meta.DateBucket().Unix())
	defer b.log.PopScope()
	b.mux.Lock()
	defer b.mux.Unlock()

	if meta == nil || meta.SourceUri == "" {
		return 0, b.log.Warn("meta is nil")
	} else if entryLen == 0 {
		return 0, b.log.Warn("entries are empty")
	} else if atomic.LoadInt32(&b.state) != 0 {
		return 0, b.log.Error("file state is not open %v", b.state)
	}

	var (
		fileCount = len(b.appendNames)
		batch     = entries
	)
	if fileCount == 0 {
		err = gocsv.Marshal(batch, b.gzw)
	} else {
		err = gocsv.MarshalWithoutHeaders(batch, b.gzw)
	}
	if err != nil {
		return rows, b.log.IfErrorF(err, "csv marshal: %v rows | appenderFiles=%v", entryLen, fileCount)
	}

	b.appendNames[name] = *meta
	rows = entryLen
	b.rows += entryLen
	b.log.Trace("%vms appended %v rows -> (%p) %v", time.Since(started).Milliseconds(), rows, b, b.Name())
	return rows, err
}
