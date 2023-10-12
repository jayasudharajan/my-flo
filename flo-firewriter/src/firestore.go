package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"time"

	firebase "firebase.google.com/go"
	"github.com/google/uuid"
	"github.com/opentracing/opentracing-go"
	"google.golang.org/api/option"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type fsUpsert = func(string, map[string]map[string]interface{}) error

const safeBatchWritesLimit = 480

const nanoToMilliDivisor = 1000000

var WriterChan *WriterChannels

// Firestore is a firebase client
var Firestore *firestore.Client

// FirebaseApp is the reference to firebase application
var FirebaseApp *firebase.App

// RtdbCtx is the real time database context
var RtdbCtx = context.Background()

// FirestoreAuth is the struct to hold the data for authentication with firestore
type FirestoreAuth struct {
	Devices   []string `json:"devices" example:"[0c1c57aea625,0c1c57aec334]"`
	Locations []string `json:"locations" example:"[07f97c2f-81b1-42d9-ac2c-b4675810319e,06f97c2f-71b1-53d9-ac2c-b4675801210e]"`
	Users     []string `json:"users" example:"[08f97c2f-51b1-22d9-ac2c-b4675810310e,16f97c2f-01b1-53d9-ac2c-b4675801210a]"`
}

type FirestoreToken struct {
	Token string `json:"token" example:"tbd"`
}

// InitFirestore is the function to initialize firestore client
func InitFirestore() (*firestore.Client, error) {

	var app *firebase.App
	var err error

	logDebug("Loading Firestore credentials from '%v'", GoogleAppCreds)
	if _, err = os.Stat(GoogleAppCreds); os.IsNotExist(err) {
		conf := &firebase.Config{ProjectID: GoogleProjectID}
		app, err = firebase.NewApp(RtdbCtx, conf)
	} else {
		serviceAccountCreds := option.WithCredentialsFile(GoogleAppCreds)
		app, err = firebase.NewApp(RtdbCtx, nil, serviceAccountCreds)
	}

	if err != nil {
		return nil, logError("Error loading credentials for '%v' project using '%v' files", GoogleProjectID, GoogleAppCreds)
	}

	if app != nil {
		FirebaseApp = app
		Firestore, err = app.Firestore(RtdbCtx)
		if err != nil {
			return nil, logError("Failed to connect to the Firestore for '%v' project, error: %v", GoogleProjectID, err.Error())
		}
		logInfo("Connected to Firestore Project '%v' successfully", GoogleProjectID)
	} else {
		return nil, logError("Firestore app is nil for '%v' project using '%v' credentials", GoogleProjectID, GoogleAppCreds)
	}

	return Firestore, nil
}

// / FsWriterRepo is the device repository
type FsWriterRepo struct {
	Firestore *firestore.Client
}

type WriteOperationChannels struct {
	Readiness map[string]chan bool
	Data      map[string]chan map[string]map[string]interface{}
}

type WriterChannels struct {
	SingleWriteChan WriteOperationChannels
	BatchWriteChan  WriteOperationChannels
}

type Stats struct {
	NumOfSuccessfulWrites int
	NumOfFailedWrites     int
	AverageWriteTimeMs    int
	SlowestWriteTimeMs    int
	FastestWriteTimeMs    int
	LastWriteTimeMs       int
}

// DeleteDoc deletes a document for provided collection and id
func (r *FsWriterRepo) DeleteDoc(collection string, id string) (int, error) {
	_, err := r.Firestore.Collection(collection).Doc(id).Delete(RtdbCtx)

	if err != nil {
		statusC, _ := status.FromError(err)
		c := statusC.Code()
		if c == codes.NotFound {
			return http.StatusNotFound, err
		} else {
			return http.StatusInternalServerError, err
		}
	}

	return 0, nil
}

// GetRealTimeData gets real time data from Firestore
func (r *FsWriterRepo) GetRealTimeData(collection string, deviceId string) (map[string]interface{}, int, error) {

	collectionRef := r.Firestore.Collection(collection)
	docRef := collectionRef.Doc(deviceId)

	data := make(map[string]interface{})

	docSnap, err := docRef.Get(RtdbCtx)
	if err != nil {
		statusC, _ := status.FromError(err)
		c := statusC.Code()
		if c == codes.NotFound {
			return data, http.StatusNotFound, nil
		} else {
			return data, http.StatusInternalServerError, err
		}
	}

	return docSnap.Data(), http.StatusOK, nil
}

const statsSizeLimit = 250000

type StatsRecorder struct {
	Success    bool
	Time       int
	Collection string
}

type StatsAccumulator struct {
	NumOfErrors              int
	SlowestWriteSoFar        int
	FastestWriteSoFar        int
	SeriesOfSuccessfulWrites []int
}

var StatsRecorderChan chan StatsRecorder

func GetStatsRecorderChan() chan StatsRecorder {
	if StatsRecorderChan == nil {
		StatsRecorderChan = make(chan StatsRecorder)
	}
	return StatsRecorderChan
}

var StatChanChan chan chan map[string]Stats

func GetStatsChanChan() chan chan map[string]Stats {
	if StatChanChan == nil {
		StatChanChan = make(chan chan map[string]Stats)
	}
	return StatChanChan
}

func startFsWriteStats() {
	statsRecorderChan := GetStatsRecorderChan()
	statsChanChan := GetStatsChanChan()

	go func() {
		firstStatsMeasurement := true

		var statsAccumulator = make(map[string]StatsAccumulator)
		for _, coll := range KnownFsCollections {
			statsAccumulator[coll] = StatsAccumulator{
				NumOfErrors:              0,
				SlowestWriteSoFar:        0,
				FastestWriteSoFar:        0,
				SeriesOfSuccessfulWrites: []int{},
			}
		}

		for {
			select {
			case statsRecorder := <-statsRecorderChan:
				c := statsRecorder.Collection
				tempStats := statsAccumulator[c]

				if len(tempStats.SeriesOfSuccessfulWrites) >= statsSizeLimit {
					statsAccumulator[c] = StatsAccumulator{
						NumOfErrors:              0,
						SlowestWriteSoFar:        0,
						FastestWriteSoFar:        0,
						SeriesOfSuccessfulWrites: []int{},
					}
					firstStatsMeasurement = true
				} else {
					if !statsRecorder.Success {
						tempStats.NumOfErrors = tempStats.NumOfErrors + 1
						statsAccumulator[c] = tempStats
					} else {
						if firstStatsMeasurement {
							tempStats.FastestWriteSoFar = statsRecorder.Time
							tempStats.SlowestWriteSoFar = statsRecorder.Time
							firstStatsMeasurement = false
						} else {
							if statsRecorder.Time < tempStats.FastestWriteSoFar {
								tempStats.FastestWriteSoFar = statsRecorder.Time
							} else {
								tempStats.SlowestWriteSoFar = statsRecorder.Time
							}
						}
						tempStats.SeriesOfSuccessfulWrites = append(tempStats.SeriesOfSuccessfulWrites, statsRecorder.Time)
						statsAccumulator[c] = tempStats
					}
				}
			case statsChan := <-statsChanChan:
				statsMap := make(map[string]Stats)
				for collection, stats := range statsAccumulator {
					numOfSuccessfulWrites, avgWriteTimeMs, lastWriteTimeMs := calcTimeStats(stats.SeriesOfSuccessfulWrites)
					collStats := Stats{
						NumOfSuccessfulWrites: numOfSuccessfulWrites,
						NumOfFailedWrites:     stats.NumOfErrors,
						AverageWriteTimeMs:    avgWriteTimeMs,
						SlowestWriteTimeMs:    stats.SlowestWriteSoFar,
						FastestWriteTimeMs:    stats.FastestWriteSoFar,
						LastWriteTimeMs:       lastWriteTimeMs,
					}
					statsMap[collection] = collStats
				}
				statsChan <- statsMap
			}
		}
	}()
}

func calcTimeStats(timeSeries []int) (int, int, int) {
	total := len(timeSeries)
	if total == 0 {
		return 0, 0, 0
	}
	var totalWriteTime int64
	for _, t := range timeSeries {
		totalWriteTime += int64(t)
	}
	avg := totalWriteTime / int64(total)
	return total, int(avg), timeSeries[total-1]
}

func GetWriterChannels() *WriterChannels {
	if WriterChan == nil {
		WriterChan = &WriterChannels{
			SingleWriteChan: WriteOperationChannels{
				Readiness: createReadinessChans(KnownFsCollections),
				Data:      createDataChans(KnownFsCollections),
			},
			BatchWriteChan: WriteOperationChannels{
				Readiness: createReadinessChans(KnownFsCollections),
				Data:      createDataChans(KnownFsCollections),
			},
		}
	}
	return WriterChan
}

func StartWriterProcesses(fsRepo *FsWriterRepo) (err error) {

	// kick-in stats collector goroutine (it is one instance for all collections)
	startFsWriteStats()

	writerChannels := GetWriterChannels()
	statsRecorderChan := GetStatsRecorderChan()
	collections := KnownFsCollections
	for _, collection := range collections {

		err = startFsWriter(fsRepo.UpsertIndividual, collection, writerChannels.SingleWriteChan.Data,
			writerChannels.SingleWriteChan.Readiness, statsRecorderChan)
		if err != nil {
			return err
		}

		err = startFsWriter(fsRepo.UpsertInBatch, collection, writerChannels.BatchWriteChan.Data,
			writerChannels.BatchWriteChan.Readiness, statsRecorderChan)
		if err != nil {
			return err
		}

	}
	return nil
}

// UpsertIndividual creates a new doc for provided id or updates the existing one in the named collection
func (r *FsWriterRepo) UpsertIndividual(collection string, inputData map[string]map[string]interface{}) error {
	sp, ctx := opentracing.StartSpanFromContext(context.Background(), "UpsertIndividual")
	defer sp.Finish()

	// get the present devices
	start := time.Now()
	data := inputData

	collectionRef := r.Firestore.Collection(collection)
	numOfRecords := len(data)
	flushRecords := make([]string, 0)

	if numOfRecords == 0 {
		logWarn("number of records to store is 0")
	} else {
		for id, d := range data {
			flushRecords = append(flushRecords, id)
			docRef := collectionRef.Doc(id)

			sp := MakeSpanRpcClient(ctx, "FirestoreUpsert", "", "cloud.google.com/go/firestore.DocumentRef.Set")
			_, err := docRef.Set(RtdbCtx, d, firestore.MergeAll)
			sp.Finish()

			if err != nil {
				return fmt.Errorf("failed to update document for Id_%s for collection %s, err: %v", id, collection, err)
			}
		}
		logDebug("UpsertIndividual: collection: %v total: %v ids: %v", collection, numOfRecords, flushRecords)
	}
	end := time.Now()
	logDebug("FirestoreFlush: %v in %.3f ms - UpsertIndividual", numOfRecords, end.Sub(start).Seconds()*1000)
	return nil
}

// UpsertInBatch creates a new docs for provided collection id or updates the existing one in the named collection
func (r *FsWriterRepo) UpsertInBatch(collection string, inputData map[string]map[string]interface{}) error {
	sp, ctx := opentracing.StartSpanFromContext(context.Background(), "UpsertInBatch")
	defer sp.Finish()

	start := time.Now()
	batch := r.Firestore.Batch()
	collectionRef := r.Firestore.Collection(collection)

	numOfRecords := len(inputData)
	pending := 0
	flushRecords := make([]string, 0)
	if numOfRecords == 0 {
		logWarn("number of records from inputData to store is 0")
	} else {
		logDebug("UpsertInBatch: collection: %v total: %v", collection, numOfRecords)
		batchCount := 1
		for id, data := range inputData {
			docRef := collectionRef.Doc(id)
			batch.Set(docRef, data, firestore.MergeAll)
			// Firestore allows up to 500 writes
			remainder := batchCount % safeBatchWritesLimit
			pending++
			flushRecords = append(flushRecords, id)

			if remainder == 0 {
				logDebug("UpsertInBatch: %v count: %v ids: %v", collection, pending, flushRecords)

				sp := MakeSpanRpcClient(ctx, "FirestoreBatchCommit", "", "cloud.google.com/go/firestore.WriteBatch.Commit")
				_, err := batch.Commit(RtdbCtx)
				sp.Finish()

				if err != nil {
					logError("failed to commit batch %d, err: %v", batchCount, err)
				}
				// TODO: check if it is necessary
				batch = r.Firestore.Batch()
				pending = 0
				flushRecords = make([]string, 0)
			}
			batchCount++
		}

		// adding the last batch if there is a remainder, e.g. numOfRecords=4370, the remainder is 370
		if pending > 0 && batch != nil {
			logDebug("UpsertInBatch: %v count: %v ids: %v", collection, pending, flushRecords)
			sp := MakeSpanRpcClient(ctx, "FirestoreLastBatchCommit", "", "cloud.google.com/go/firestore.WriteBatch.Commit")
			_, err := batch.Commit(RtdbCtx)
			sp.Finish()

			if err != nil {
				logError("failed to commit batch %d, err: %v", batchCount, err)
			}
		}
	}
	end := time.Now()
	logDebug("FirestoreFlush: %v in %.3f ms - UpsertInBatch", numOfRecords, end.Sub(start).Seconds()*1000)
	return nil
}

func startFsWriter(fsF fsUpsert, collection string, dataChanMap map[string]chan map[string]map[string]interface{},
	readinessChanMap map[string]chan bool, statsRecorderChan chan StatsRecorder) (err error) {

	c := collection
	var readinessChan chan bool
	var ok bool
	if readinessChan, ok = readinessChanMap[c]; !ok {
		err = fmt.Errorf("there is no %s in readinessChanMap", c)
	}
	var upsertChannel chan map[string]map[string]interface{}
	if upsertChannel, ok = dataChanMap[c]; !ok {
		err = fmt.Errorf("there is no %s in readinessChanMap", c)
	}

	go func() {
		logInfo("starting upsert goroutine for %s collection", c)
		for {
			select {
			case data := <-upsertChannel:
				startTimer := time.Now()
				err := fsF(c, data)
				readinessChan <- true
				logDebug("sent message to the readinessChan")
				if err != nil {
					logError(err.Error())
					statsRecorderChan <- StatsRecorder{
						Success:    false,
						Time:       0,
						Collection: c,
					}
				} else {
					stopTimer := time.Now()
					diffNano := stopTimer.Sub(startTimer).Nanoseconds()
					lastWriteTimeMs := int(diffNano / nanoToMilliDivisor)
					logInfo("it took %d ms to flush %d records", lastWriteTimeMs, len(data))
					statsRecorderChan <- StatsRecorder{
						Success:    true,
						Time:       lastWriteTimeMs,
						Collection: c,
					}
				}
				logDebug("stats have been sent")
			}
		}
	}()
	return nil
}

func createReadinessChans(collections []string) map[string]chan bool {
	result := make(map[string]chan bool)
	for _, c := range collections {
		logDebug("creating readiness channel for %s", c)
		result[c] = make(chan bool)
	}
	return result
}

func createDataChans(collections []string) map[string]chan map[string]map[string]interface{} {
	result := make(map[string]chan map[string]map[string]interface{})
	for _, c := range collections {
		logDebug("creating data channel for %s", c)
		result[c] = make(chan map[string]map[string]interface{})
	}
	return result
}

// GenerateFirestoreJwt should match the firestore database rule:
// allow read: if request.auth.uid != null && (request.auth.token.device_ids == '*' || resource.data.deviceId in request.auth.token.ids.split(','));
func (r *FsWriterRepo) GenerateFirestoreJwt(deviceIds string, locationIds string, userIds string) (string, error) {
	defer timeMethod("GenerateFirestoreJwt", deviceIds, locationIds, userIds)()
	logDebug("GenerateFirestoreJwt: Devices: %v Locations: %v Users: %v", deviceIds, locationIds, userIds)

	ctx := context.Background()

	client, err := FirebaseApp.Auth(ctx)
	if err != nil {
		logError("error getting Auth client: %v", err)
		return EmptyString, err
	}

	firestoreJwtUuid := uuid.New().String()

	claims := map[string]interface{}{
		"device_ids":   deviceIds,
		"location_ids": locationIds,
		"user_ids":     userIds,
	}
	token, err := client.CustomTokenWithClaims(ctx, firestoreJwtUuid, claims)
	if err != nil {
		logError("error creating custom jwt with public claim field deviceIds %s: %v", deviceIds, err)
		return EmptyString, err
	}

	return token, nil
}
