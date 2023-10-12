package flo.directive.router.services

import akka.actor.ActorSystem
import akka.testkit.{ImplicitSender, TestKit}
import com.flo.FloApi.v2.{IDirectiveTrackingEndpoints, IIcdForcedSystemModesEndpoints}
import com.flo.Models.KafkaMessages.DirectiveMessage
import com.flo.Models.SystemModeDetail
import flo.directive.router.utils.IMQTTClient
import org.eclipse.paho.client.mqttv3.MqttException
import org.scalatest.{BeforeAndAfterAll, Matchers, WordSpecLike}
import scala.concurrent.Future

abstract class BaseActorsSpec extends TestKit(ActorSystem("MySpec"))
  with ImplicitSender
  with WordSpecLike with Matchers with BeforeAndAfterAll {

  implicit val context = system.dispatcher

  override def afterAll() = {
    TestKit.shutdownActorSystem(system)
  }

  def mqttClientThatSuccess = new IMQTTClient {
    private var messages: List[Any] = Nil

    def getMessages = messages

    override def send[T <: AnyRef](topicTemplate: String, message: T, serializer: T => String): Unit = {
      messages = message :: messages
    }
  }

  def mqttClientThatFailTwoTimesBeforeSuccess = new IMQTTClient {
    private var messages: List[Any] = Nil
    private var attempts = 0

    def getMessages = messages
    def getAttempts = attempts

    override def send[T <: AnyRef](topicTemplate: String, message: T, serializer: T => String): Unit = {
      attempts = attempts + 1

      if(attempts <= 2)
        throw new MqttException(32000)

      messages = message :: messages
    }
  }

  val icdForcedSystemModesEndpoints = new IIcdForcedSystemModesEndpoints {
    override def latest(deviceId: String): Future[List[SystemModeDetail]] = Future(Nil)
  }

  val directiveTrackingEndpoints = new IDirectiveTrackingEndpoints {
    override def create(directive: DirectiveMessage): Future[Boolean] = Future(true)
  }
}