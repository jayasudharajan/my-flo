package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/google/uuid"
	"github.com/robfig/cron/v3"
)

type FloDetectDevice struct {
	MacAddress     string    `db:"mac_address"`
	InstalledAt    time.Time `db:"installed_at"`
	Timezone       string    `db:"timezone"`
	AccountId      string    `db:"account_id"`
	SubscriptionId string    `db:"subscription_id"`
	CreatedAt      string    `db:"created_at"`
	UpdatedAt      string    `db:"updated_at"`
}

type FloDetectMessage struct {
	DeviceId          string `json:"device_id"`
	RequestId         string `json:"request_id"`
	StartDate         string `json:"start_date"`
	EndDate           string `json:"end_date"`
	DurationInSeconds int    `json:"duration_in_seconds"`
}

func generateUUID() (string, error) {
	uuidV4, err := uuid.NewRandom()

	if err != nil {
		return "", err
	}

	return uuidV4.String(), nil
}

func parseFloDetectDeviceDbRecord(rows *sql.Rows) (FloDetectDevice, error) {
	var device FloDetectDevice

	err := rows.Scan(&device.MacAddress, &device.InstalledAt, &device.Timezone, &device.AccountId)

	return device, err
}

func shouldComputeWeekly(device FloDetectDevice) bool {
	location, err := time.LoadLocation(device.Timezone)

	if err != nil {
		location = time.UTC
	}

	return time.Now().In(location).Hour() == 0
}

func scheduleFloDetectComputation(pgDb *PgSqlDb, kafkaConn *KafkaConnection, redisConn *RedisConnection, topic string, timeSinceInstall time.Duration, duration time.Duration, shouldCompute func(d FloDetectDevice) bool) error {
	if pgDb == nil {
		return fmt.Errorf("postgres connection is nil")
	}

	if kafkaConn == nil {
		return fmt.Errorf("kafka connection is nil")
	}

	logDebug("scheduling flodetect %v computation", duration)
	minInstallDate := time.Now().Add(-timeSinceInstall)
	query := "SELECT \"mac_address\", \"installed_at\", \"account_id\", \"timezone\" FROM flodetect_devices "
	query += "WHERE \"installed_at\" <= $1 "
	query += "ORDER BY \"mac_address\""
	rows, err := pgDb.Query(query, minInstallDate)

	if err != nil {
		return err
	}

	for rows.Next() {
		device, err := parseFloDetectDeviceDbRecord(rows)

		if err != nil {
			logError("failed to parse flodetect device record")
		}

		if !shouldCompute(device) {
			continue
		}

		err = queueFloDetectComputation(kafkaConn, redisConn, topic, duration, device)

		if err != nil {
			logError("failed to queue flodetect computation %v", device)
		}
	}

	logDebug("flodetect %v computation successfully scheduled", duration)

	return nil
}

func queueFloDetectComputation(kafkaConn *KafkaConnection, redisConn *RedisConnection, topic string, duration time.Duration, device FloDetectDevice) error {
	if kafkaConn == nil {
		return fmt.Errorf("kafka connection is nil")
	}

	if redisConn == nil {
		return fmt.Errorf("redis connection is nil")
	}

	key := fmt.Sprintf("mutex:flodetect:computation-%v:%v", duration.String(), device.MacAddress)
	result, err := redisConn.SetNX(key, true, 60)

	if err != nil {
		return err
	}

	if !result {
		return nil
	}

	requestId, err := generateUUID()

	if err != nil {
		return err
	}

	endDate := time.Now()
	startDate := endDate.Add(-duration)
	message := FloDetectMessage{
		DeviceId:          device.MacAddress,
		RequestId:         requestId,
		StartDate:         startDate.UTC().Format(time.RFC3339),
		EndDate:           endDate.UTC().Format(time.RFC3339),
		DurationInSeconds: int(duration.Truncate(time.Second).Seconds()),
	}

	logDebug("publishing message to kafka: %v", message)

	err = kafkaConn.Publish(topic, message, nil)

	go func() {
		select {
		case event := <-kafkaConn.Producer.Events():
			logDebug("%v", event)
		}
	}()

	if err != nil {
		logError("message failed to publish: request_id %v. %v", message.RequestId, err.Error())
		return err
	}

	return nil
}

func scheduleFloDetectTraining(pgDb *PgSqlDb, kafkaConn *KafkaConnection, redisConn *RedisConnection, topic string, minDuration time.Duration, maxDuration time.Duration) error {
	if pgDb == nil {
		return fmt.Errorf("postgres connection is nil")
	}

	if kafkaConn == nil {
		return fmt.Errorf("kafka connection is nil")
	}

	logDebug("scheduling flodetect training")
	minInstallDate := time.Now().Add(-minDuration)
	query := "SELECT \"mac_address\", \"installed_at\", \"account_id\", \"timezone\" FROM flodetect_devices "
	query += "WHERE \"installed_at\" <= $1 "
	query += "ORDER BY \"mac_address\""
	rows, err := pgDb.Query(query, minInstallDate)

	if err != nil {
		return err
	}

	for rows.Next() {
		device, err := parseFloDetectDeviceDbRecord(rows)

		if err != nil {
			logError("failed to parse flodetect device record")
		}

		err = queueFloDetectTraining(kafkaConn, redisConn, topic, maxDuration, device)

		if err != nil {
			logError("failed to queue training for %v", device)
		}
	}

	logDebug("flodetect training successfully scheduled")

	return nil
}

func queueFloDetectTraining(kafkaConn *KafkaConnection, redisConn *RedisConnection, topic string, maxDuration time.Duration, device FloDetectDevice) error {
	if kafkaConn == nil {
		return fmt.Errorf("kafka connection is nil")
	}

	if redisConn == nil {
		return fmt.Errorf("redis connection is nil")
	}

	key := fmt.Sprintf("mutex:flodetect:training:%v", device.MacAddress)
	result, err := redisConn.SetNX(key, true, 60)

	if err != nil {
		return err
	}

	if !result {
		return nil
	}

	endDate := time.Now()
	timeSinceInstallation := endDate.Sub(device.InstalledAt)

	var duration time.Duration

	if timeSinceInstallation > maxDuration {
		duration = maxDuration
	} else {
		duration = timeSinceInstallation
	}

	startDate := endDate.Add(-duration)
	requestId, err := generateUUID()

	if err != nil {
		return err
	}

	message := FloDetectMessage{
		DeviceId:          device.MacAddress,
		RequestId:         requestId,
		StartDate:         startDate.UTC().Format(time.RFC3339),
		EndDate:           endDate.UTC().Format(time.RFC3339),
		DurationInSeconds: int(duration.Truncate(time.Second).Seconds()),
	}

	logDebug("publishing message to kafka: %v", message)

	err = kafkaConn.Publish(topic, message, nil)

	if err != nil {
		logError("message failed to publish: request_id %v. %v", message.RequestId, err.Error())
		return err
	}

	return nil
}

func populateFloDetectDevices(pgDb *PgSqlDb, redisConn *RedisConnection) error {
	if pgDb == nil {
		return fmt.Errorf("postgres connection is nil")
	}

	if redisConn == nil {
		return fmt.Errorf("redis connection is nil")
	}

	key := "mutex:flodetect:scan-subscribers"
	result, err := redisConn.SetNX(key, true, 300)

	if err != nil {
		return err
	}

	if !result {
		return nil
	}

	next := ""
	pageNum := 0

	for {
		logDebug("retrieving subscription page %v", pageNum)
		page, err := getSubscriptions(next, []string{
			"location(account(id),timezone,devices(macAddress,installStatus(isInstalled,installDate)))",
			"id",
			"isActive",
			"provider",
		})

		if err != nil {
			logError("subscription page %v failed to retrieve: %v", err.Error())
			return err
		}

		logDebug("subscription page %v successfully retrieved with %v items", pageNum, len(page.Items))

		for _, sub := range page.Items {
			devices := sub.Location.Devices

			if sub.IsActive {
				_, err = upsertDevices(pgDb, devices, sub.Id, sub.Location.Account.Id, sub.Location.Timezone)
			} else {
				err = removeDevices(pgDb, devices)
			}

			if err != nil {
				return err
			}
		}

		if page.Next == "" {
			logDebug("successfully retrieved all %v pages of subscriptions", pageNum)
			break
		} else {
			next = page.Next
			pageNum += 1
		}
	}

	return nil
}

func upsertDevices(pgDb *PgSqlDb, devices []DeviceApiModel, subscriptionId string, accountId string, timezone string) ([]FloDetectDevice, error) {
	var floDetectDevices []FloDetectDevice

	if pgDb == nil {
		return floDetectDevices, fmt.Errorf("postgres connection is nil")
	}

	query := "INSERT INTO flodetect_devices (\"mac_address\", \"installed_at\", \"account_id\", \"timezone\", \"subscription_id\", \"updated_at\", \"created_at\") "
	query += "VALUES ($1, $2, $3, $4, $5, $6, $6) "
	query += "ON CONFLICT (\"mac_address\") DO "
	query += "UPDATE SET \"mac_address\"=$1, \"installed_at\"=$2, \"account_id\"=$3, \"timezone\"=$4, \"subscription_id\"=$5, \"updated_at\"=$6"

	for _, apiDevice := range devices {
		if !apiDevice.InstallStatus.IsInstalled {
			continue
		}

		floDetectDevice := FloDetectDevice{
			MacAddress:     apiDevice.MacAddress,
			InstalledAt:    apiDevice.InstallStatus.InstallDate,
			Timezone:       timezone,
			AccountId:      accountId,
			SubscriptionId: subscriptionId,
		}
		now := time.Now()

		logDebug("upserting flodetect device %v", floDetectDevice)

		_, err := pgDb.ExecNonQuery(
			query,
			floDetectDevice.MacAddress,
			floDetectDevice.InstalledAt,
			floDetectDevice.AccountId,
			floDetectDevice.Timezone,
			floDetectDevice.SubscriptionId,
			now,
		)

		if err != nil {
			logError("flodetect device failed to upsert %v, %v", floDetectDevice, err.Error())
			return nil, err
		}

		logDebug("flodetect device successfully upserted %v", floDetectDevice)

		floDetectDevices = append(floDetectDevices, floDetectDevice)
	}

	return floDetectDevices, nil
}

func removeDevices(pgDb *PgSqlDb, devices []DeviceApiModel) error {
	if pgDb == nil {
		return fmt.Errorf("postgres connection is nil")
	}

	query := "DELETE FROM flodetect_devices WHERE \"mac_address\"=$1"

	for _, apiDevice := range devices {
		logDebug("deleting flodetect device %v", apiDevice)
		_, err := pgDb.ExecNonQuery(query, apiDevice.MacAddress)

		if err != nil {
			logError("flodetect device failed to delete %v, %v", apiDevice, err.Error())
			return err
		}

		logDebug("flodetect device successfully deleted %v", apiDevice)
	}

	return nil
}

func removeDevicesBySubscriptionId(pgDb *PgSqlDb, subscriptionId string) error {
	if pgDb == nil {
		return fmt.Errorf("postgres connection is nil")
	}

	query := "DELETE FROM flodetect_devices WHERE \"subscription_id\"=$1"

	_, err := pgDb.ExecNonQuery(query, subscriptionId)

	if err != nil {
		return err
	}

	return nil
}

func initFloDetectJobs(pgDb *PgSqlDb, kafkaConn *KafkaConnection, redisConn *RedisConnection) (func(), error) {
	fdCron := cron.New(cron.WithLocation(time.UTC))
	dayDuration := time.Second * 24 * 60 * 60

	_, err := fdCron.AddFunc(_floDetectPopulateCron, func() {
		err := populateFloDetectDevices(pgDb, redisConn)

		if err != nil {
			logError("failed 24 hour computation scheduling: %v", err.Error())
		}
	})

	if err != nil {
		return nil, err
	}

	_, err = fdCron.AddFunc(_floDetect24HrCron, func() {
		err := scheduleFloDetectComputation(pgDb, kafkaConn, redisConn, _floDetect24HrTopic, 21*dayDuration, dayDuration, func(_ FloDetectDevice) bool {
			return true
		})

		if err != nil {
			logError("failed 24 hour computation scheduling: %v", err.Error())
		}
	})

	if err != nil {
		return nil, err
	}

	_, err = fdCron.AddFunc(_floDetect7DCron, func() {
		err := scheduleFloDetectComputation(pgDb, kafkaConn, redisConn, _floDetect7DTopic, 21*dayDuration, 7*dayDuration, shouldComputeWeekly)

		if err != nil {
			logError("failed 7 day computation scheduling: %v", err.Error())
		}
	})

	if err != nil {
		return nil, err
	}

	_, err = fdCron.AddFunc(_floDetectTrainCron, func() {
		err := scheduleFloDetectTraining(pgDb, kafkaConn, redisConn, _floDetectTrainTopic, 21*dayDuration, 30*dayDuration)

		if err != nil {
			logError("failed training scheduling: %v", err.Error())
		}
	})

	if err != nil {
		return nil, err
	}

	//consumer, err := kafkaConn.Subscribe(_kafkaGroupId, []string{ENTITY_ACTIVITY_TOPIC}, func(message *kafka.Message) {
	//	err := processKafkaMessage(message, pgDb)
	//
	//	if err != nil {
	//		logError("failed to process kafka message %v", err.Error())
	//	}
	//})
	//
	//if err != nil {
	//	return nil, err
	//}
	//

	fdCron.Start()

	stop := func() {
		fdCron.Stop()
		//consumer.Close()
	}

	return stop, nil
}

func processKafkaMessage(message *kafka.Message, pgDb *PgSqlDb) error {

	if message == nil || message.TopicPartition.Topic == nil || message.Value == nil || len(message.Value) == 0 {
		return fmt.Errorf("empty kafka message")
	}

	var entityActivity EntityActivityEnvelopeModel

	err := json.Unmarshal(message.Value, &entityActivity)

	if err != nil {
		return err
	}

	if entityActivity.Item == "device" {
		err = handleDeviceEntityActivity(pgDb, entityActivity)
	}

	if entityActivity.Item == "subscription" {
		err = handleSubscriptionEntityActivity(pgDb, entityActivity)
	}

	if err != nil {
		return err
	}

	return nil
}

func handleDeviceEntityActivity(pgDb *PgSqlDb, entityActivity EntityActivityEnvelopeModel) error {

	if entityActivity.Action != "deleted" {
		return nil
	}

	item, ok := entityActivity.Item.(DeviceApiModel)

	if !ok {
		return fmt.Errorf("invalid device entity")
	}

	err := removeDevices(pgDb, []DeviceApiModel{item})

	if err != nil {
		return err
	}

	return nil
}

func handleSubscriptionEntityActivity(pgDb *PgSqlDb, entityActivity EntityActivityEnvelopeModel) error {
	if pgDb == nil {
		return fmt.Errorf("postgres db is nil")
	}

	var sub SubscriptionApiModel

	sub, ok := entityActivity.Item.(SubscriptionApiModel)

	if !ok {
		return fmt.Errorf("invalid subscription entity")
	}

	if entityActivity.Action == "deleted" || !sub.IsActive {
		return removeDevicesBySubscriptionId(pgDb, sub.Id)
	}

	apiSub, err := getSubscription(sub.Id, []string{
		"location(account(id),timezone,devices(macAddress,installStatus(isInstalled,installDate)))",
		"id",
		"isActive",
		"provider",
	})

	if err != nil {
		return err
	}

	_, err = upsertDevices(pgDb, apiSub.Location.Devices, apiSub.Id, apiSub.Location.Account.Id, apiSub.Location.Timezone)

	if err != nil {
		return err
	}

	return nil
}
