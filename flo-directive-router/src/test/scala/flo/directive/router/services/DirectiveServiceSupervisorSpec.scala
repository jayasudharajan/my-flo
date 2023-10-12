package flo.directive.router.services

import akka.testkit.TestProbe
import com.flo.Models.KafkaMessages.{Directive, DirectiveMessage}
import com.flo.utils.FromCamelToSneakCaseSerializer
import org.joda.time.DateTime

import scala.concurrent.duration._

class DirectiveServiceSupervisorSpec extends BaseActorsSpec {

  val date = DateTime.now()
  val directiveMessage = DirectiveMessage(
    "1", Directive("1", "test", "", date, "", None), 2
  )

  "The DirectiveServiceSupervisor" should {
    "success to send a directive at first attempt" in {
      val proxy = TestProbe()
      val mqttClient = mqttClientThatSuccess
      val serializer = new FromCamelToSneakCaseSerializer
      val directiveServiceSupervisor = system.actorOf(
        DirectiveServiceSupervisor.props(
          mqttClient,
          "my-topic",
          "my-topic",
          directiveTrackingEndpoints,
          icdForcedSystemModesEndpoints,
          x => serializer.serialize[Directive](x)
        )
      )

      proxy.send(directiveServiceSupervisor, directiveMessage)

      awaitAssert({
        mqttClient.getMessages.find(m => m == directiveMessage.directive) shouldEqual Some(directiveMessage.directive)
      }, 1.second, 100.milliseconds)
    }

    "fails the first attempt but success to send a directive at second attempt" in {
      val proxy = TestProbe()
      val mqttClient = mqttClientThatFailTwoTimesBeforeSuccess
      val serializer = new FromCamelToSneakCaseSerializer
      val directiveServiceSupervisor = system.actorOf(
        DirectiveServiceSupervisor.props(
          mqttClient,
          "my-topic",
          "my-topic",
          directiveTrackingEndpoints,
          icdForcedSystemModesEndpoints,
          x => serializer.serialize[Directive](x)
        )
      )

      proxy.send(directiveServiceSupervisor, directiveMessage)

      awaitAssert({
        mqttClient.getMessages.length shouldEqual 1
        mqttClient.getAttempts shouldEqual 3

        mqttClient.getMessages.find(m => m == directiveMessage.directive) shouldEqual Some(directiveMessage.directive)
      }, 10.second, 100.milliseconds)
    }
  }
}

