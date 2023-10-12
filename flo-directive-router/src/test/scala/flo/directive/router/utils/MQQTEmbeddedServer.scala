package flo.directive.router.utils

import java.util.Arrays._
import io.moquette.interception.AbstractInterceptHandler
import io.moquette.interception.messages.InterceptPublishMessage
import io.moquette.server.Server
import io.moquette.server.config.IConfig

class MQQTEmbeddedServer(val port: Int) {
  val mqttBroker = new Server()
  private var receivedMessages: Map[String, List[String]] = Map()
  val sslPort = port + 1
  val keyStorePassword = "123456789"

  def start(): Unit = {
    val userHandlers = asList(new PublisherListener())
    mqttBroker.startServer(new Config(port.toString, sslPort.toString), userHandlers)
  }

  def stop(): Unit = {
    mqttBroker.stopServer()
  }

  def getReceivedMessages(topic: String): List[String] = {
    receivedMessages.get(topic).getOrElse(Nil)
  }

  class Config(port: String, sslPort: String) extends IConfig {

    var configurations = Map(
      "host" -> "localhost",
      "port" -> port,
      "ssl_port" -> sslPort,
      "allow_anonymous" -> "true",
      "jks_path" -> getClass.getResource("/serverkeystore.jks").getPath,
      "key_store_password" -> keyStorePassword,
      "key_manager_password" -> keyStorePassword
    )

    override def getProperty(name: String): String = {
      configurations.get(name).getOrElse(null)
    }

    override def getProperty(name: String, defaultValue: String): String = {
      configurations.get(name).getOrElse(defaultValue)
    }

    override def setProperty(name: String, value: String): Unit = {
      configurations = configurations + (name -> value)
    }
  }

  class PublisherListener extends AbstractInterceptHandler {
    override def onPublish(msg: InterceptPublishMessage): Unit = {
      val topic = msg.getTopicName()
      val message = new String(msg.getPayload().array())
      val topicData = receivedMessages.get(topic).getOrElse(Nil)
      val updatedTopicData = message :: topicData

      receivedMessages = receivedMessages + (topic -> updatedTopicData)
    }
  }
}