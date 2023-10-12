package flo.directive.router.utils

import com.flo.utils.FromCamelToSneakCaseSerializer
import org.scalatest.{BeforeAndAfter, Matchers, WordSpec}
import scala.util.Random

class MQTTClientTest extends WordSpec with Matchers with BeforeAndAfter {

  private val topic = "kafka-producer-test"

  case class MessageData(a: String, b: String)

  def getRandomPort = 8883 + (new Random).nextInt(200)

  val serializer = new FromCamelToSneakCaseSerializer

  "The MQTTProducerTest" should {
    "send data to MQTT and should be received" in {
      val server = new MQQTEmbeddedServer(getRandomPort)

      //Start MQQT Server
      server.start()

      //Send data to MQTT
      val mqttApi = new MQTTClient(s"tcp://localhost:${server.port}", 2, "MQTTProducerTest")
      mqttApi.send[MessageData](topic, new MessageData("Hello", "World"), x => serializer.serialize[MessageData](x))


      val msg = server.getReceivedMessages(topic).head

      "{\"a\":\"Hello\",\"b\":\"World\"}" shouldEqual msg

      //Stop MQQT Server
      server.stop()
    }
  }

  /*
  "send data to MQQT using SSL and should be received" in {
    val server = new MQQTEmbeddedServer(getRandomPort)

    //Start MQQT Server
    server.start()

    //Send data to MQTT
    val sslConfig =  KeyStoreConfiguration(getClass.getResource("/serverkeystore.jks").getPath, server.keyStorePassword)
    val mqttApi = new MQTTClient(s"ssl://localhost:${server.sslPort}", 2, "MQTTProducerTest", Some(sslConfig))
    mqttApi.send[MessageData](topic, new MessageData("Hello", "World"), x => serializer.serialize[MessageData](x))


    val msg = server.getReceivedMessages(topic).head

    "{\"a\":\"Hello\",\"b\":\"World\"}" shouldEqual msg

    //Stop MQQT Server
    server.stop()
  }
  */
}