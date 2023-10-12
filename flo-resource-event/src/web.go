package main

import (
	"sync"

	"flotechnologies.com/flo-resource-event/src/commons/topic"
	"flotechnologies.com/flo-resource-event/src/commons/utils"
	"flotechnologies.com/flo-resource-event/src/resourceevent/resourceeventprocess"
	"flotechnologies.com/flo-resource-event/src/resourceevent/resourceeventprocess/mappers"
	"flotechnologies.com/flo-resource-event/src/storages/sql/stores"
	"github.com/gin-gonic/gin"
	//_ "gitlab.com/flotechnologies/flo-resource-event/docs"
)

var (
	_resourceEventService resourceeventprocess.ResourceEventProcessor
	_initLock             sync.Mutex
)

func resourceEventServiceSingleton(log *utils.Logger, resourceEventStore stores.ResourceEventStore, internalResourceEventMapper mappers.ResourceEventMapper) resourceeventprocess.ResourceEventProcessor {
	if _resourceEventService == nil { //cheaper double checked lock
		_initLock.Lock()
		defer _initLock.Unlock()
		if _resourceEventService == nil {
			_resourceEventService = resourceeventprocess.CreateResourceEvent(log, resourceEventStore, internalResourceEventMapper)
		}
	}
	return _resourceEventService
}

func initKafka() *topic.KafkaConnection {
	kafkaConnection, err := topic.OpenKafka(utils.GetEnvOrExit("FLO_KAFKA_CN"), nil)
	if err != nil {
		utils.LogFatal("initKafka: error creating kafka connection - %v", err)
		SignalExit()
		return nil
	}
	utils.LogNotice("initKafka: OK")
	return kafkaConnection
}

func registerRoutes(w *WebServer) {
	internalResourceEventMapper := mappers.NewResourceEventMapper()
	resourceEventStore := stores.CreateResourceEventStore(w.Logger())

	resourceEventService := resourceEventServiceSingleton(w.Logger(), resourceEventStore, internalResourceEventMapper)
	pgPing := func() (string, error) {
		return "pg", resourceEventStore.Ping()
	}

	kafkaConnection := initKafka()
	kafkaConfig := &ResourceEventKafkaConfig{
		KafkaConnection: kafkaConnection,
		GroupId:         utils.GetEnvOrDefault("FLO_KAFKA_GROUP_ID", "flo-resource-event"),
		Topic:           utils.GetEnvOrDefault("FLO_KAFKA_TOPIC_RESOURCE_EVENT", "resource-event-v1"),
	}
	kafPing := func() (string, error) {
		return "kafka", kafkaConnection.Ping()
	}

	pings := []func() (string, error){
		pgPing,
		kafPing,
	}
	newHandler := func() *ResourceEventHandler {
		return CreateResourceEventHandler(w, kafkaConfig, _validator, resourceEventService, pings)
	}
	w.closers = append(w.closers, newHandler()) //get a copy & use it as singleton handle for open/close

	w.router.GET("/", func(c *gin.Context) {
		newHandler().Health(c)
	})
	w.router.GET("/ping", func(c *gin.Context) {
		newHandler().Health(c)
	})
	w.router.POST("/ping", func(c *gin.Context) {
		newHandler().Health(c)
	})
	w.router.POST("/event", func(c *gin.Context) {
		newHandler().ProcessResourceEventPost(c)
	})
	w.router.POST("/event/publish", func(c *gin.Context) {
		newHandler().TestPublishResourceEvent(c)
	})
	w.router.GET("/event", func(c *gin.Context) {
		newHandler().AllResourceEventByAccountIdGet(c)
	})
}
