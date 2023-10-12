package main

import (
	"context"
	"fmt"

	"github.com/opentracing/opentracing-go/ext"
)

var fwPropMqttTemplate = compileMqttTopic(MqttDeviceFwPropsTopicTemplate, "{deviceId}", "{method}")

// PublishToFwPropsMqttTopic is the func to publish message to MQTT fw props topic
func PublishToFwPropsMqttTopic(ctx context.Context, deviceId string, qos int, msg []byte, method string) bool {
	topic := compileMqttTopic(MqttDeviceFwPropsTopicTemplate, deviceId, method)
	sp := MakeSpanMqttProducer(ctx, "Mqtt "+MqttDeviceFwPropsTopicTemplate+" publish", topic, fwPropMqttTemplate)
	defer sp.Finish()

	// fire and forget, don't wait for the confirmation from the broker
	logDebug("PublishToFwPropsMqttTopic: device %v publishing %s to %s topic", deviceId, string(msg), topic)
	t := MqttPublisherClient.Publish(topic, byte(qos), false, msg)

	if t.Error() != nil {
		logError("PublishToFwPropsMqttTopic: %v %v", deviceId, t.Error().Error())
		sp.SetTag(string(ext.Error), t.Error().Error())
		return false
	} else {
		return true
	}
}

func compileMqttTopic(topicTemplate string, targetId string, mqttMethod string) string {
	return fmt.Sprintf(topicTemplate, targetId, mqttMethod)
}
