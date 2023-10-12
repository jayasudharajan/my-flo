package main

import (
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/go-redis/redis"
	"github.com/lib/pq"
)

const redisDeviceSetName = "incident-archiver.devices"
const redisLock = "incident-archiver.lock"

type IncidentArchiverCfg struct {
	olderThanInDays int
}

type IncidentArchiver struct {
	_redis    *RedisConnection
	_pgRead   *PgSqlDb
	_pgWrite  *PgSqlDb
	_s3       *S3Handler
	_dynamoDb *DynamoDbHandler
	_config   *IncidentArchiverCfg
}

type IncidentArchiverConfig struct {
	olderThanInDays int
}

func NewIncidentArchiver(config *IncidentArchiverConfig, redis *RedisConnection, pgRead *PgSqlDb, pgWrite *PgSqlDb, s3 *S3Handler, dynamoDb *DynamoDbHandler) (*IncidentArchiver, error) {
	archiver := new(IncidentArchiver)
	archiver._redis = redis
	archiver._pgRead = pgRead
	archiver._pgWrite = pgWrite
	archiver._s3 = s3
	archiver._dynamoDb = dynamoDb
	archiver._config = &IncidentArchiverCfg{
		olderThanInDays: config.olderThanInDays,
	}
	return archiver, nil
}

func (a *IncidentArchiver) Start() {
	lockAcquired, err := a._redis.SetNX(redisLock, "", 300)

	if err != nil {
		logWarn("archiver: Start: error acquiring lock - %v", err)
	}

	deviceCount, err := a._redis.SCard(redisDeviceSetName)
	if err != nil {
		logWarn("archiver: Start: error retrieving incident count - %v", err)
		deviceCount = 0
	}

	if deviceCount == 0 && lockAcquired {
		if count := a.populateDeviceSet(); count == 0 {
			logInfo("archiver: Start: no incidents to archive.")
		}
	}

	if lockAcquired {
		logDebug("archiver: Start: deleting redis lock key")
		if err = a.deleteLockKey(); err != nil {
			logWarn("archiver: Start: error deleting redis lock - %v", err)
		}
	} else {
		logDebug("archiver: Start: waiting for device set to be populated...")
		// Wait 15 minutes at most
		if err = a.waitForDeviceSet(15*time.Second, 60); err != nil {
			logWarn("archiver: Start: device set is empty. Nothing to be done.")
			return
		}
		logDebug("archiver: Start: device set ready")
	}

	stop := false
	for !stop {
		logDebug("archiver: Start: popping device from set")
		deviceId, err := a.popDeviceFromSet()
		if err == nil && deviceId != "" {
			logDebug("archiver: Start: popped device %s from set", deviceId)
			logInfo("archiver: Start: processing device %s", deviceId)
			// TODO: This could be run in parallel in a "Go Routine pool".
			a.processDevice(deviceId)
			logInfo("archiver: Start: device %s successfully processed", deviceId)
		} else {
			stop = true
			if err != nil {
				logError("archiver: Start: error popping device from set - %v", err)
			} else {
				logDebug("archiver: Start: no more devices to process")
			}
		}
	}
}

func (a *IncidentArchiver) popDeviceFromSet() (string, error) {
	var deviceId string

	err := RetryIfError(
		func() error {
			id, err := a._redis.SPop(redisDeviceSetName)
			if err == redis.Nil {
				deviceId = ""
				return nil
			}
			deviceId = id
			return err
		},
		5*time.Second,
		3,
	)
	return deviceId, err
}

func (a *IncidentArchiver) processDevice(deviceId string) {
	logDebug("archiver: processDevice: retrieving macAddress for device %s", deviceId)
	macAddress, err := a.getMacAddress(deviceId)
	if err != nil || macAddress == "" {
		logError("archiver: processDevice: error retrieving mac address for device %s - %v", deviceId, err)
		return
	}
	logDebug("archiver: processDevice: retrieved macAddress %s for device %s", macAddress, deviceId)

	logDebug("archiver: processDevice: retrieving incidents for device %s", deviceId)
	incidents, err := a.retrieveIncidents(deviceId)
	if err != nil {
		logError("archiver: processDevice: error querying incidents for device %s - %v", deviceId, err)
		return
	}
	defer incidents.Close()

	incidentListMap := a.rowsToList(incidents)
	logDebug("archiver: processDevice: retrieved %d incidents for device %s", len(incidentListMap), deviceId)
	if len(incidentListMap) == 0 {
		logDebug("archiver: skipping device %s", deviceId)
		return
	}

	logDebug("archiver: processDevice: archiving %d incidents", len(incidentListMap))
	lastArchivedDate := a.archiveIncidents(incidentListMap, macAddress, deviceId)

	logDebug("archiver: processDevice: setting %s as last archived date for device %s", lastArchivedDate, deviceId)
	if err := a.setLastArchivedDate(deviceId, lastArchivedDate); err != nil {
		logWarn("archiver: processDevice: error while setting last archived date %s for device %s", lastArchivedDate, deviceId)
	}

	logDebug("archiver: processDevice: successfully archived incidents for device %s", deviceId)
}

func (a *IncidentArchiver) setLastArchivedDate(deviceId string, lastArchivedDate string) error {
	err := RetryIfError(
		func() error {
			_, err := a._pgWrite.Exec(`
				INSERT INTO incident_archive (device_id, last_archived_date)
				VALUES ($1, $2)
				ON CONFLICT (device_id)
				DO UPDATE SET last_archived_date = EXCLUDED.last_archived_date
				`, deviceId, lastArchivedDate)
			return err
		},
		5*time.Second,
		3,
	)
	return err
}

func (a *IncidentArchiver) rowsToList(incidents *sql.Rows) []map[string]interface{} {
	incidentListMap := make([]map[string]interface{}, 0)
	for incidents.Next() {
		incidentMap := a.incidentRowToMap(incidents)
		incidentListMap = append(incidentListMap, incidentMap)
	}

	return incidentListMap
}

func (a *IncidentArchiver) deleteIncidents(incidentIds []string) error {
	err := RetryIfError(
		func() error {
			_, err := a._pgWrite.Exec(`
				DELETE FROM incident i WHERE i.id = ANY($1)
				`, pq.Array(incidentIds))
			return err
		},
		5*time.Second,
		3,
	)
	return err
}

func (a *IncidentArchiver) retrieveIncidents(deviceId string) (*sql.Rows, error) {
	return a._pgRead.Query(`
		SELECT 
			to_char(date_trunc('day', i.create_at), 'YYYY/MM/DD') AS date, 
			i.id AS id,
			json_strip_nulls(to_json(i)) AS incident, 
			json_strip_nulls(coalesce(to_json(incident_source), '{}')) AS incident_source,
			json_strip_nulls(coalesce(to_json(incident_text), '{}')) AS incident_text,
			de.items AS delivery_event
		FROM incident i
		LEFT JOIN incident_source
			ON i.id = incident_source.id
		LEFT JOIN incident_text
			ON i.id = incident_text.incident_id
		LEFT JOIN LATERAL (
			SELECT json_strip_nulls(coalesce(json_agg(delivery_event), '[]')) AS items
			FROM delivery_event
			WHERE i.id = delivery_event.alarm_event_id
		) AS de ON TRUE
		LEFT JOIN incident_archive ia ON i.icd_id = ia.device_id
		WHERE
			i.icd_id = $1 AND
			DATE(i.create_at) < DATE(NOW() - ($2 || ' days')::interval) AND
			DATE(i.create_at) > COALESCE(ia.last_archived_date, '1900-01-01'::date)
		ORDER BY i.create_at ASC;
	`, deviceId, a._config.olderThanInDays)
}

func (a *IncidentArchiver) archiveIncidents(incidentListMap []map[string]interface{}, macAddress string, deviceId string) string {
	var (
		s                   strings.Builder
		inFlightIncidentIds []string
		lastProcessedDate   string
	)

	for _, incident := range incidentListMap {
		currentDate := fmt.Sprintf("%v", incident["date"])

		if lastProcessedDate != "" && lastProcessedDate != currentDate {
			// Day Changed - Send
			if err := a.sendIncidentsToS3(lastProcessedDate, macAddress, s); err != nil {
				logWarn("archiver: archiveIncidents: error archiving incidents - %v", err)
				return lastProcessedDate
			}
			s.Reset()
			inFlightIncidentIds = nil
		}

		if len(inFlightIncidentIds) > 0 {
			// Next row
			s.WriteByte('\n')
		}

		incidentId := fmt.Sprintf("%v", incident["id"])
		inFlightIncidentIds = append(inFlightIncidentIds, incidentId)

		jsonStr := a.incidentMapToJson(incident)
		s.WriteString(jsonStr)
		lastProcessedDate = currentDate
	}

	if len(inFlightIncidentIds) > 0 {
		if err := a.sendIncidentsToS3(lastProcessedDate, macAddress, s); err != nil {
			logWarn("archiver: archiveIncidents: error archiving incidents - %v", err)
			return lastProcessedDate
		}
	}

	return lastProcessedDate
}

func (a *IncidentArchiver) incidentMapToJson(incident map[string]interface{}) string {
	var (
		jsonStr strings.Builder
		i       int
	)
	// Delete unneeded attributes
	delete(incident, "id")
	delete(incident, "date")
	jsonStr.WriteByte('{')
	for key, element := range incident {
		if i > 0 {
			jsonStr.WriteByte(',')
		}
		jsonStr.WriteByte('"')
		jsonStr.WriteString(key)
		jsonStr.WriteString(`":`)
		jsonStr.WriteString(fmt.Sprintf("%v", element))
		i++
	}
	jsonStr.WriteByte('}')
	return jsonStr.String()
}

func (a *IncidentArchiver) sendIncidentsToS3(lastProcessedDate string, macAddress string, s strings.Builder) error {
	key := a.buildS3Key(lastProcessedDate, macAddress)
	logDebug("archiver: sendIncidentsToS3: sending incidents to s3 for key %s", key)
	if err := a.sendToS3(key, s.String()); err != nil {
		return fmt.Errorf("archiver: sendIncidentsToS3: error sending incidents to s3 for key %s - %v", key, err)
	}
	return nil
}

func (a *IncidentArchiver) buildS3Key(lastProcessedDate string, macAddress string) string {
	return fmt.Sprintf("%s/flo-incidents-%s-%s.json", lastProcessedDate, macAddress, strings.ReplaceAll(lastProcessedDate, "/", "-"))
}

func (a *IncidentArchiver) sendToS3(key string, s string) error {
	gzipped, err := toGzip([]byte(s))
	if err != nil {
		return err
	}
	err = RetryIfError(
		func() error {
			return a._s3.UploadFile(key+".gz", gzipped)
		},
		5*time.Second,
		3,
	)
	return err
}

func (a *IncidentArchiver) incidentRowToMap(incidentRow *sql.Rows) map[string]interface{} {
	incidentMap := make(map[string]interface{})
	cols, _ := incidentRow.Columns()
	columns := make([]string, len(cols))
	columnPointers := make([]interface{}, len(cols))

	for i := range columns {
		columnPointers[i] = &columns[i]
	}

	incidentRow.Scan(columnPointers...)

	for i, colName := range cols {
		incidentMap[colName] = columns[i]
	}

	return incidentMap
}

func (a *IncidentArchiver) populateDeviceSet() int {
	logDebug("archiver: populateDeviceSet: retrieving devices with unarchived incidents older than %d days", a._config.olderThanInDays)

	candidateDevices, err := a._pgRead.Query(`
		SELECT DISTINCT i.icd_id AS device_id
		FROM incident i
		LEFT JOIN incident_archive ia ON i.icd_id = ia.device_id
		WHERE
			DATE(i.create_at) < DATE(NOW() - ($1 || ' days')::interval) AND
			DATE(i.create_at) > COALESCE(ia.last_archived_date, '1900-01-01'::date);
	`, a._config.olderThanInDays)

	if err != nil {
		logWarn("archiver: populateDeviceSet: error retrieving candidate devices - %v", err)
		return 0
	}

	defer candidateDevices.Close()

	var (
		deviceIdChunk     []string
		chunkSize         = 500
		candidateDeviceId string
		i                 int
		total             int
	)
	for candidateDevices.Next() {
		candidateDevices.Scan(&candidateDeviceId)
		deviceIdChunk = append(deviceIdChunk, candidateDeviceId)
		if i++; i == chunkSize {
			err = a.addDevicesToSet(deviceIdChunk)
			if err != nil {
				logWarn("archiver: populateDeviceSet: error adding devices to redis - %v", err)
			} else {
				total += chunkSize
			}
			i = 0
			deviceIdChunk = nil
		}
	}
	if len(deviceIdChunk) > 0 {
		err = a.addDevicesToSet(deviceIdChunk)
		if err != nil {
			logWarn("archiver: populateDeviceSet: error adding devices to redis - %v", err)
		} else {
			total += len(deviceIdChunk)
		}
	}
	return total
}

func (a *IncidentArchiver) addDevicesToSet(devices []string) error {
	err := RetryIfError(
		func() error {
			err := a._redis.SAdd(redisDeviceSetName, devices)
			return err
		},
		5*time.Second,
		3,
	)
	return err
}

func (a *IncidentArchiver) waitForDeviceSet(interval time.Duration, attempsLeft int) error {
	err := RetryIfError(
		func() error {
			count, err := a._redis.SCard(redisDeviceSetName)
			if err != nil {
				return err
			}
			if count == 0 {
				return errors.New("no devices in set")
			}
			return nil
		},
		interval,
		attempsLeft,
	)

	return err
}

func (a *IncidentArchiver) deleteLockKey() error {
	err := RetryIfError(
		func() error {
			_, err := a._redis.Delete(redisLock)
			return err
		},
		5*time.Second,
		3,
	)
	return err
}

func (a *IncidentArchiver) getMacAddress(deviceId string) (string, error) {
	var macAddress string
	err := RetryIfError(
		func() error {
			mac, err := a._dynamoDb.QueryMacAddress(deviceId)
			macAddress = mac
			return err
		},
		5*time.Second,
		3,
	)

	if err != nil {
		return "", err
	}
	return macAddress, nil
}
