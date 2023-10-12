package kafka

import (
	"log"
	cluster "github.com/bsm/sarama-cluster"
	"encoding/json"
	logging "main/loggy"
	"main/Structures/Kafka"
	twi "main/TwilioUtil"
	"sync"
)

var loggy = logging.Init()

func StartConsumingMessages(consumer cluster.Consumer, serviceCommandChannel chan int64, wg *sync.WaitGroup) {
	defer wg.Done()
	// consume messages, watch errors and notifications
	for {
		select {
		case msg, more := <-consumer.Messages():
			if more {
				consumer.MarkOffset(msg, "") // mark message as processed
				var twilioCallMessage Kafka.VoiceMessage
				if err := json.Unmarshal(msg.Value, &twilioCallMessage); err != nil {
					loggy.Log.Println(loggy.Error(err, "error deserializing kafka message"))
					continue
				}
				twi.MakeCall(twilioCallMessage)
			}
		case err, more := <-consumer.Errors():
			if more {
				loggy.Log.Println(loggy.Error(err, "kafka consumer error: "))
			}
		case ntf, more := <-consumer.Notifications():
			if more {
				log.Printf("Rebalanced: %+v\n", ntf)
			}
		case cmd := <-serviceCommandChannel:
			if cmd == 2 {
				loggy.Log.Println(loggy.Warning("Service command to stop service detected.... standing by "))
				return
			}
		}
	}

}
