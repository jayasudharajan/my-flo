package flo.directive.router.services

import akka.actor.{Actor, ActorLogging, Props}
import com.flo.FloApi.v2.{IDirectiveTrackingEndpoints, IIcdForcedSystemModesEndpoints}
import com.flo.Models.KafkaMessages.{Directive, DirectiveMessage}
import flo.directive.router.services.DirectiveService.{Send, Stop}
import flo.directive.router.services.DirectiveServiceSupervisor.Sent
import flo.directive.router.utils.{BackoffStrategy, IMQTTClient, RetryStrategy}
import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

class DirectiveService(
                        mqttClient: IMQTTClient,
                        mqttDirectivesTopicTemplate: String,
                        mqttUpgradeTopicTemplate: String,
                        directiveTrackingEndpoints: IDirectiveTrackingEndpoints,
                        iIcdForcedSystemModesEndpoints: IIcdForcedSystemModesEndpoints,
                        serializer: Directive => String,
                        backoffStrategy: BackoffStrategy,
                        retryStrategy: RetryStrategy,
                        directive: DirectiveMessage
                      )
  extends Actor with ActorLogging {

  import context.dispatcher

  override def preStart(): Unit = {
    if(!retryStrategy.isRetryLimitReached()) {
      context.system.scheduler.scheduleOnce(backoffStrategy.backoffTime, self, directive)
    }
    backoffStrategy.increment()
    retryStrategy.increment()
  }

  def isDeviceInForcedSleepState(deviceId: String)(implicit ec: ExecutionContext): Future[Boolean] =
    iIcdForcedSystemModesEndpoints.latest(deviceId) map { systemModeDetails =>
      systemModeDetails match {
        case systemMode :: tail if systemMode != 5 => false
        case Nil => false
        case _ => true
      }
    }

  // The only stable data the actor has during restarts is those embedded in
  // the Props when it was created.
  def receive = {
    case message: DirectiveMessage =>

      if(message.directive.directive == Directive.setSystemMode) {
        isDeviceInForcedSleepState(message.directive.deviceId) map { isForcedSleep =>
          if (!isForcedSleep) self ! Send(message)
        } onFailure {
          case e: Exception => log.error(e, "There was an error retrieving latest system mode using api. ")
        }
      } else {
        self ! Send(message)
      }
    case Send(message) =>

      val topic = if(message.directive.directive.startsWith("upgrade")) {
        mqttUpgradeTopicTemplate.replace("@DEVICE_ID", message.directive.deviceId)
      } else {
        mqttDirectivesTopicTemplate.replace("@DEVICE_ID", message.directive.deviceId)
      }

      log.info(s"About to send directive ${message.directive.directive} to device ${message.icdId}")

      mqttClient.send[Directive](topic, message.directive, serializer)

      log.info(s"Directive ${message.directive.directive} sent to device ${message.icdId}")

      //Send directive tracking data
      directiveTrackingEndpoints.create(message) onComplete {
        case Success(result) =>
          self ! Stop
        case Failure(exception) =>
          log.error(exception, "Directive could not saved using directive tracking endpoint.")
          self ! Stop
      }

      backoffStrategy.reset()

      //indicate to supervisor that the operation was a success
      context.parent ! Sent(message)
    case Stop =>
      // Don't forget to stop the actor after it has nothing more to do
      context.stop(self)
  }
}

object DirectiveService {
  case object Stop
  case class Send(directiveMessage: DirectiveMessage)

  def props(mqttClient: IMQTTClient,
            mqttDirectivesTopicTemplate: String,
            mqttUpgradeTopicTemplate: String,
            directiveTrackingEndpoints: IDirectiveTrackingEndpoints,
            iIcdForcedSystemModesEndpoints: IIcdForcedSystemModesEndpoints,
            serializer: Directive => String,
            backoffStrategy: BackoffStrategy,
            retryStrategy: RetryStrategy,
            directive: DirectiveMessage) =
    Props(classOf[DirectiveService],
      mqttClient,
      mqttDirectivesTopicTemplate,
      mqttUpgradeTopicTemplate,
      directiveTrackingEndpoints,
      iIcdForcedSystemModesEndpoints,
      serializer,
      backoffStrategy,
      retryStrategy,
      directive)
}



