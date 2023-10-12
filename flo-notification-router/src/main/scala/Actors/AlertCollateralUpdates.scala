package Actors

import MicroService.AlertService
import Models.AlertCollateralUpdatesMessage
import akka.actor.{Actor, ActorLogging, PoisonPill}
import akka.stream.ActorMaterializer
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global


/**
  * Created by Francisco on 6/26/2017.
  * This actor is in charge of updating alert that are unresolved, but another alert will collaterally change their status
  *
  */
class AlertCollateralUpdates extends Actor with ActorLogging {

  implicit val materializer = ActorMaterializer()(context)
  implicit val system = context.system

  private lazy val alarmService = new AlertService(context)

  override def preStart = {
    log.info(s"started actor ${self.path.name} @ ${self.path.address}")
  }

  override def postStop = {
    log.info(s"stopped actor ${self.path.name} @ ${self.path.address}")

  }

  def receive = {
    case msg: AlertCollateralUpdatesMessage =>

      log.info(s"Starting to process collateral updates for internal Alarm id : ${msg.internalAlarmId} icdID: ${msg.icdId} incidentId: ${msg.incidentId.getOrElse("N/A")}")
      alarmService.resolveAlarmsCollaterally(msg.internalAlarmId, msg.icdId)
      system.scheduler.scheduleOnce(30 seconds, self, PoisonPill)


  }

}
