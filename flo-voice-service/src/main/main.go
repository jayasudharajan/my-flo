package main

import (
	logging "main/loggy"
	cluster "github.com/bsm/sarama-cluster"
	"github.com/Shopify/sarama"

	"main/util"
	"main/kafka"
	"net/http"
	"fmt"
	"os"
	"os/signal"
	"sync"
  "syscall"
)

var loggy = logging.Init()

func main() {
	loggy.Log.Println(loggy.Info("Getting Configuration"))
	appConfig, err1 := util.GetConfiguration()
	if err1 != nil {
		loggy.Log.Println(loggy.Error(err1, "error getting app configuration"))
	}
	kafkaConfig := cluster.NewConfig()
	kafkaConfig.Consumer.Return.Errors = true
	kafkaConfig.Group.Return.Notifications = true
	kafkaConfig.Consumer.Offsets.Initial = sarama.OffsetNewest

	// service state
	serviceCommand := make(chan int64, 1)
	serviceCommand <- appConfig.ServiceCommand

	//starting kafka consumer
	// init consumer
	brokers := appConfig.KafkaHost
	topics := []string{appConfig.KafkaVoiceTopic}
	groupId := appConfig.KafkaGroupId
	loggy.Log.Println(loggy.Info("Starting kafka Consumer..."))
	consumer, err := cluster.NewConsumer(brokers, groupId, topics, kafkaConfig)
	if err != nil {
		loggy.Log.Println(loggy.Error(err, "error creating kafka consumer"))
	}
	defer consumer.Close()
	
	var wg sync.WaitGroup
	wg.Add(1)
		
	loggy.Log.Println(loggy.Info("starting to process kafka messages..."))
	go kafka.StartConsumingMessages(*consumer, serviceCommand, &wg)

	// Graceful shutdown 
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
	go func(){
		<-sigs
		consumer.Close()
		serviceCommand <- 2
		wg.Wait()
		os.Exit(0)
	}()

	loggy.Log.Println(loggy.Info("Starting health point...."))
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8000", nil)

}
func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "OK\nHi there moFLo!")
}
