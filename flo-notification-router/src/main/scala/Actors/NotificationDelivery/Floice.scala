package Actors.NotificationDelivery

import MicroService.FloiceService
import Models.Mediums.FloiceActorMessage
import Models.ProducerMessages.ProducerVoiceMessage
import Nators.ICDAlarmIncidentRegistryLogGenerator
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorRef, Props}
import akka.stream.ActorMaterializer
import com.flo.Enums.Notifications.{DeliveryMediums, ICDAlarmIncidentRegistryLogStatus}
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.ICDAlarmIncidentRegistryLogEndpoints
import com.flo.Models.KafkaMessages.Floice.FloiceMessage
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.utils.HttpMetrics
import kamon.Kamon

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

class Floice(producer: ActorRef, unitSystem: MeasurementUnitSystem) extends Actor with ActorLogging {
  lazy private val floiceService = new FloiceService(unitSystem)

  implicit val materializer = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )

  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  //proxy
  private lazy val proxyIncidentRegistryLog = new ICDAlarmIncidentRegistryLogEndpoints(clientCredentialsTokenProvider)

  //nators
  private lazy val incidentRegistryLogNator = new ICDAlarmIncidentRegistryLogGenerator()


  override def preStart = {
    log.info(s"started actor ${self.path.name} @ ${self.path.address}")
  }

  override def postStop = {
    log.info(s"stopped actor ${self.path.name} @ ${self.path.address}")

  }

  def receive = {
    case floiceMsg: FloiceActorMessage =>



      val floice = FloiceMessage(
        id = floiceService.createId(),
        requestInfo = floiceService.getRequestInfoForDefaultCall(),
        message = floiceService.defaultCallJsonGenerator(floiceMsg.incidentRegistry, floiceMsg.userContactInformation, floiceMsg.location, floiceMsg.iCDAlarmNotificationDeliveryRules.internalId, floiceMsg.iCDAlarmNotificationDeliveryRules.messageTemplates.friendlyName, floiceMsg.snapshot, floiceMsg.isUserTenant)

      )
      val producerVoiceMessage = ProducerVoiceMessage(floice, floiceMsg.incidentRegistry.id, floiceMsg.userContactInformation.userId.getOrElse("N/A"))

      producer ! producerVoiceMessage

      proxyIncidentRegistryLog.Post(Some(
        incidentRegistryLogNator.registryLogPost(
          floiceMsg.incidentRegistry.id,
          userId = floiceMsg.userContactInformation.userId.get,
          DeliveryMediums.VOICE,
          ICDAlarmIncidentRegistryLogStatus.TRIGGERED,
          None
        )
      )).onComplete {
        case Success(s) => context.stop(self)
        case Failure(e) => log.error(e, s"proxyIncidentRegistryLog for incidentRegistry id: ${floiceMsg.incidentRegistry.id} ")
          context.stop(self)
      }
  }

}

object Floice {
  def props(
             producer: ActorRef,
             unitSystem: MeasurementUnitSystem
           ): Props = Props(classOf[Floice], producer, unitSystem)
}
