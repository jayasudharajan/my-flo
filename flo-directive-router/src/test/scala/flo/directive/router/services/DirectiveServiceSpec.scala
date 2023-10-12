package flo.directive.router.services

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.Models.KafkaMessages.{Directive, DirectiveMessage}
import com.flo.utils.FromCamelToSneakCaseSerializer
import flo.directive.router.services.DirectiveServiceSupervisor.Sent
import flo.directive.router.utils.{SimpleBackoffStrategy, SimpleRetryStrategy}
import org.joda.time.DateTime

class DirectiveServiceSpec extends BaseActorsSpec {

  val date = DateTime.now()

  "The DirectiveService" should {
    "success to send a directive and notify the parent" in {
      val parent = TestProbe()
      val mqttClient = mqttClientThatSuccess
      val serializer = new FromCamelToSneakCaseSerializer
      val directive = DirectiveMessage(
        "1",
        Directive("1", "test", "", date, "", None),
        1
      )

      val directiveServiceSupervisor = TestActorRef(
        DirectiveService.props(
          mqttClient,
          "my-topic",
          "my-topic",
          directiveTrackingEndpoints,
          icdForcedSystemModesEndpoints,
          x => serializer.serialize[Directive](x),
          new SimpleBackoffStrategy,
          new SimpleRetryStrategy(3),
          directive
        ),
        parent.ref,
        "DirectiveService"
      )
      directiveServiceSupervisor ! directive

      parent.expectMsg(Sent(directive))
    }
  }
}