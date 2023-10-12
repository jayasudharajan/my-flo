package flo.directive.router.services

import akka.actor.Props
import com.flo.FloApi.v2.{IDirectiveTrackingEndpoints, IIcdForcedSystemModesEndpoints}
import com.flo.Models.KafkaMessages.{Directive, DirectiveMessage}
import com.flo.communication.IKafkaConsumer
import flo.directive.router.services.DirectiveKafkaConsumer.DirectiveKafkaConsumerSettings
import flo.directive.router.utils.IMQTTClient

class DirectiveKafkaConsumer(settings: DirectiveKafkaConsumerSettings)
  extends KafkaActorConsumer[DirectiveMessage](settings.kafkaConsumer, settings.deserializer, settings.filter, settings.filterTimeInSeconds) {

  log.info("DirectiveKafkaConsumer started!")

  val directiveServiceSupervisor = context.actorOf(
    DirectiveServiceSupervisor.props(
      settings.mqttClient,
      settings.mqttDirectivesTopicTemplate,
      settings.mqttUpgradeTopicTemplate,
      settings.directiveTrackingEndpoints,
      settings.iIcdForcedSystemModesEndpoints,
      settings.serializer
    ),
    "directive-service-supervisor"
  )

  def consume(kafkaMessage: DirectiveMessage): Unit = {
    directiveServiceSupervisor ! kafkaMessage
  }
}

object DirectiveKafkaConsumer {
  case class DirectiveKafkaConsumerSettings(
                                           kafkaConsumer: IKafkaConsumer,
                                           mqttClient: IMQTTClient,
                                           mqttDirectivesTopicTemplate: String,
                                           mqttUpgradeTopicTemplate: String,
                                           directiveTrackingEndpoints: IDirectiveTrackingEndpoints,
                                           iIcdForcedSystemModesEndpoints: IIcdForcedSystemModesEndpoints,
                                           serializer: Directive => String,
                                           deserializer: String => DirectiveMessage,
                                           filter: Option[DirectiveMessage => Boolean],
                                           filterTimeInSeconds: Int
                                         )

  def props(settings: DirectiveKafkaConsumerSettings) = Props(classOf[DirectiveKafkaConsumer], settings)
}
