package flo.directive.router.services

import akka.actor.SupervisorStrategy.{Restart, Stop}
import akka.actor.{Actor, ActorLogging, OneForOneStrategy, Props}
import com.flo.FloApi.v2.{IDirectiveTrackingEndpoints, IIcdForcedSystemModesEndpoints}
import com.flo.Models.KafkaMessages.{Directive, DirectiveMessage}
import flo.directive.router.services.DirectiveServiceSupervisor.Sent
import flo.directive.router.utils.{IMQTTClient, SimpleBackoffStrategy, SimpleRetryStrategy}
import org.eclipse.paho.client.mqttv3.MqttException

class DirectiveServiceSupervisor(
                                  mqttClient: IMQTTClient,
                                  mqttDirectivesTopicTemplate: String,
                                  mqttUpgradeTopicTemplate: String,
                                  directiveTrackingEndpoints: IDirectiveTrackingEndpoints,
                                  iIcdForcedSystemModesEndpoints: IIcdForcedSystemModesEndpoints,
                                  serializer: Directive => String
                                )

  extends Actor with ActorLogging {

  log.info("DirectiveServiceSupervisor started!")

  override val supervisorStrategy = OneForOneStrategy(loggingEnabled = false) {
    case e: MqttException =>
      log.error(e, s"There was an error when trying to send the directive to the ICD, restarting.")
      Restart
    case e: Exception =>
      log.error(e, "Unexpected failure.")
      Stop
  }

  def receive = {
    case message: DirectiveMessage => {
      context.actorOf(
        DirectiveService.props(
          mqttClient,
          mqttDirectivesTopicTemplate,
          mqttUpgradeTopicTemplate,
          directiveTrackingEndpoints,
          iIcdForcedSystemModesEndpoints,
          serializer,
          new SimpleBackoffStrategy,
          new SimpleRetryStrategy(3),
          message
        )
      )
    }
    case Sent(directive) =>
      //Make some post process
  }
}

object DirectiveServiceSupervisor {
  def props(
             mqttClient: IMQTTClient,
             mqttDirectivesTopicTemplate: String,
             mqttUpgradeTopicTemplate: String,
             directiveTrackingEndpoints: IDirectiveTrackingEndpoints,
             iIcdForcedSystemModesEndpoints: IIcdForcedSystemModesEndpoints,
             serializer: Directive => String
           ) =
    Props(classOf[DirectiveServiceSupervisor],
      mqttClient,
      mqttDirectivesTopicTemplate,
      mqttUpgradeTopicTemplate,
      directiveTrackingEndpoints,
      iIcdForcedSystemModesEndpoints,
      serializer
    )

  case class Sent(message: DirectiveMessage)
}



