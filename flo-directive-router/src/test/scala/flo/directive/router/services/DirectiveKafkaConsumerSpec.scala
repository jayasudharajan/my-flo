package flo.directive.router.services

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.Models.KafkaMessages.{Directive, DirectiveMessage}
import com.flo.communication.{IKafkaConsumer, TopicRecord}
import com.flo.utils.{FromCamelToSneakCaseSerializer, FromSneakToCamelCaseDeserializer}
import org.joda.time.DateTime

class DirectiveKafkaConsumerSpec extends BaseActorsSpec {

  val date = DateTime.now()

  val directiveMessage1 = DirectiveMessage(
    "1", Directive("1", Directive.factoryReset, "", date, "", None), 2
  )

  val directiveMessage2 = DirectiveMessage(
    "2", Directive("2", Directive.factoryReset, "", date, "", None), 4
  )

  val kafkaConsumer: IKafkaConsumer =
    new IKafkaConsumer {

      def shutdown(): Unit = {}

      override def consume[T <: AnyRef](deserializer: (String) => T, processor: TopicRecord[T] => Unit)(implicit m: Manifest[T]): Unit = {
        List(
          TopicRecord(directiveMessage1, DateTime.now()),
          TopicRecord(directiveMessage2, DateTime.now())
        ).asInstanceOf[Iterable[TopicRecord[T]]] foreach { x =>
          processor(x)
        }
      }

      override def pause(): Unit = ???

      override def resume(): Unit = ???

      override def isPaused(): Boolean = false
    }

  "The DirectiveKafkaConsumer" should {
    "start receive data using the consumer" in {
      val parent = TestProbe()

      val mqttClient = mqttClientThatSuccess
      val deserializer = new FromSneakToCamelCaseDeserializer
      val serializer = new FromCamelToSneakCaseSerializer

      val directiveConsumerProps = DirectiveKafkaConsumer.props(
        DirectiveKafkaConsumer.DirectiveKafkaConsumerSettings(
          kafkaConsumer,
          mqttClient,
          "my-topic",
          "my-topic",
          directiveTrackingEndpoints,
          icdForcedSystemModesEndpoints,
          x => serializer.serialize[Directive](x),
          x => deserializer.deserialize[DirectiveMessage](x),
          Some(x => Directive.isValid(x.directive)),
          100000
        )
      )

      TestActorRef(
        directiveConsumerProps,
       parent.ref,
       "DirectiveKafkaConsumer"
      )

      awaitAssert(mqttClient.getMessages should contain only (
        directiveMessage1.directive,
        directiveMessage2.directive
        )
      )
    }
  }
}