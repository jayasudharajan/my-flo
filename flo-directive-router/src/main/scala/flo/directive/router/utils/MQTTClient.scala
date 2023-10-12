package flo.directive.router.utils

import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence
import org.eclipse.paho.client.mqttv3.{MqttClient, MqttConnectOptions, MqttMessage}

class MQTTClient(
                    broker: String,
                    qos: Int,
                    clientId: String,
                    securityProvider: Option[IMQTTSecurityProvider] = None
                  ) extends IMQTTClient {


  private def getClient(): MqttClient = {
    val persistence = new MemoryPersistence()
    val uuid = java.util.UUID.randomUUID.toString
    val client = new MqttClient(broker, clientId + uuid, persistence)
    client
  }

  val connectOptions = new MqttConnectOptions()
  connectOptions.setCleanSession(true)

  securityProvider.map(x =>
    connectOptions.setSocketFactory(x.getSocketFactory())
  )

  def send[T <: AnyRef](topic: String, message: T, serializer: T => String): Unit = {
    val client = getClient()
    val serializedMessage = serializer(message)
    val mqttMessage = new MqttMessage(serializedMessage.getBytes)

    mqttMessage.setQos(qos)
    client.connect(connectOptions)
    client.publish(topic, mqttMessage)

    client.disconnect()
  }
}