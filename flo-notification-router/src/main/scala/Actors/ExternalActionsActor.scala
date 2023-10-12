package Actors

import MicroService.ValidationService
import Models.ExternalActions.ValveStatusActorMessage
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorSystem, Props}
import akka.stream.ActorMaterializer
import argonaut.Argonaut._
import com.flo.Enums.Notifications.UserActionsIDs
import com.flo.FloApi.v2.Abstracts.{ClientCredentialsTokenProvider, FloTokenProviders}
import com.flo.FloApi.v2.ICDEndpoints
import com.flo.utils.HttpMetrics
import kamon.Kamon

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}


/**
  * Created by Francisco on 1/11/2017.
  */
class ExternalActionsActor extends Actor with ActorLogging {

  implicit val materializer: ActorMaterializer = ActorMaterializer()(context)
  implicit val system: ActorSystem = context.system

  implicit val httpMetrics: HttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider: ClientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  private lazy val VALIDATION_SERVICE = new ValidationService()
  private lazy val FLO_PROXY_ICD = new ICDEndpoints(clientCredentialsTokenProvider)


  def receive = {
    case valveStatusMsg: ValveStatusActorMessage =>
      VALIDATION_SERVICE.valveStatusActorMessageValidator(valveStatusMsg)

      // identify the state of the valve CLOSE, OPENED, TRANSITION
      valveStatusMsg.telemetry.get match {
        case valveOpen if valveOpen.sw1.get == 1 && valveOpen.sw2.get == 0 =>
          FLO_PROXY_ICD.PostManualValveAction(valveOpen.did, Some(UserActionsIDs.OPEN_VALVE_MANUALLY)).onComplete {
            case Success(ok) => log.info(s"Successfully sent user action for opening valve manually for did: ${valveOpen.did.getOrElse("N/A")}")
            case Failure(ex) => log.error(s"The following exception happened trying to send user action for manual open valve for did: ${valveOpen.did.getOrElse("N/A")} exception: ${ex.toString}")

          }
        case valveClose if valveClose.sw1.get == 0 && valveClose.sw2.get == 1 =>
          FLO_PROXY_ICD.PostManualValveAction(valveClose.did, Some(UserActionsIDs.CLOSE_VALVE_MANUALLY)).onComplete {
            case Success(ok) => log.info(s"Successfully sent user action for closing valve manually for did: ${valveClose.did.getOrElse("N/A")}")
            case Failure(ex) => log.error(s"The following exception happened trying to send user action for manual close valve for did: ${valveClose.did.getOrElse("N/A")} exception: ${ex.toString}")

          }

        case valveInTransition if valveInTransition.sw1.get == 0 && valveInTransition.sw2.get == 0 =>
          log.info(s"received in transition  valve from did: ${valveInTransition.did.getOrElse("N/A")}")

        case _ =>
          log.error(s"Unknown valve state received from did: ${valveStatusMsg.telemetry.get.did.getOrElse("N/A")} telemetry: ${valveStatusMsg.telemetry.get.asJson.nospaces}")

      }


    case _ =>
      log.error("Unknown message sent to external actions actor")
  }
}

object ExternalActionsActor {
  def props(): Props = Props(classOf[ExternalActionsActor])
}