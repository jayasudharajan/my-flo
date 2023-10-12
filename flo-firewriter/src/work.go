package main

import (
	"fmt"
	"strings"
	"time"
)

// WorkRequest is the struct defining the work request
type WorkRequest struct {
	Data       map[string]interface{}
	Collection string
}

var _workRequestChannel map[string]chan WorkRequest

func init() {
	defCol := strings.Split(defaultKnownFsCollections, ",")
	_workRequestChannel = createWorkRequestChans(defCol)
}

func StartWorkRequestsProcessing() {
	for _, collection := range KnownFsCollections {
		startWorkRequestProcess(collection, _workRequestChannel)
	}
}

func startWorkRequestProcess(collection string, chanWorkRequestsMap map[string]chan WorkRequest) {
	flushTicker := time.NewTicker(time.Second)
	c := collection
	writerChans := GetWriterChannels()
	workRequestChan := chanWorkRequestsMap[c]
	singleWriteReadinessChan := writerChans.SingleWriteChan.Readiness[c]
	singleWriteDataChan := writerChans.SingleWriteChan.Data[c]
	batchWriteReadinessChan := writerChans.BatchWriteChan.Readiness[c]
	batchWriteDataChan := writerChans.BatchWriteChan.Data[c]

	go func() {
		// need key id for maps merging
		idKey := createIdKey(c)
		logInfo("started caching %s goroutine with idKey %s", c, idKey)

		// map structure to accumulate real time data to be flushed
		fsDataAccumulator := make(map[string]map[string]interface{})
		singleWriteReadiness := true
		batchWriteReadiness := true

		for {
			select {
			case wr := <-workRequestChan:
				if wr.Collection == c {
					data := wr.Data
					if idI, okKey := data[idKey]; okKey {
						if id, ok := idI.(string); ok {
							// merge maps
							temp := fsDataAccumulator[id]
							if temp == nil {
								temp = make(map[string]interface{})
							}
							for k, v := range data {
								// make sure "collection" key/value pair not to be written to the Firestore
								if k != CollectionKey {
									temp[k] = v
								}
							}
							fsDataAccumulator[id] = temp
						} else {
							logError("failed to cast id value %v", idI)
						}
					} else {
						logError("idKey %s doesn't exist", idKey)
					}
				} else {
					logError("work request collection mismatch, expected %s, got %s", c, wr.Collection)
				}
			case ready := <-singleWriteReadinessChan:
				singleWriteReadiness = ready
				logDebug("single write has been completed")
			case ready := <-batchWriteReadinessChan:
				batchWriteReadiness = ready
				logDebug("batch write has been completed")
			case <-flushTicker.C:
				size := len(fsDataAccumulator)
				if size > 0 {
					if size <= batchWriteThreshold {
						if singleWriteReadiness {
							fsDataAccumulatorTemp := fsDataAccumulator
							logDebug("passing %v over to single writer", fsDataAccumulatorTemp)
							singleWriteDataChan <- fsDataAccumulatorTemp
							fsDataAccumulator = make(map[string]map[string]interface{})
							singleWriteReadiness = false
						} else {
							logDebug("single write hasn't been completed, waiting out")
						}
					} else {
						if batchWriteReadiness {
							fsDataAccumulatorTemp := fsDataAccumulator
							logDebug("passing %v over to batch writer", fsDataAccumulatorTemp)
							batchWriteDataChan <- fsDataAccumulatorTemp
							fsDataAccumulator = make(map[string]map[string]interface{})
							batchWriteReadiness = false
						} else {
							logDebug("batch write hasn't been completed, waiting out")
						}
					}
				}
			}
		}
	}()
}

func createWorkRequestChans(collections []string) map[string]chan WorkRequest {
	result := make(map[string]chan WorkRequest)
	for _, c := range collections {
		result[c] = make(chan WorkRequest)
	}
	return result
}

func createIdKey(str string) string {
	strSplit := strings.Split(str, "-")
	c := strSplit[0]
	if last := len(c) - 1; last >= 0 && c[last] == 's' {
		c = c[:last]
	}
	idKey := fmt.Sprintf("%sId", c)
	return idKey
}
