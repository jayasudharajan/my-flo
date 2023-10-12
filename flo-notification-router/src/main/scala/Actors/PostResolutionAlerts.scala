package Actors

import Models.PostResolutionAlertMessage
import akka.actor.{Actor, ActorLogging, ActorRef, Props}
import akka.stream.ActorMaterializer
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.{ICDAlarmIncidentData, ICDAlarmIncidentDataAlarm, PostAutoResolutionInfo}
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.duration._


/**
  * Created by Francisco on 7/6/2017.
  */
class PostResolutionAlerts(decisionEngine: ActorRef) extends Actor with ActorLogging {
  private val materializer = ActorMaterializer()(context)
  val system = context.system

  override def preStart = {
    log.info(s"started actor ${self.path.name} @ ${self.path.address}")
  }

  override def postStop = {
    log.info(s"stopped actor ${self.path.name} @ ${self.path.address}")

  }


  def receive = {
    case postResolutionMessage: PostResolutionAlertMessage =>

      val incidentTimeInMs = DateTime.now(DateTimeZone.UTC).getMillis

      val autoResolutionAlarm = ICDAlarmIncident(
        id = java.util.UUID.randomUUID().toString,
        ts = incidentTimeInMs,
        deviceId = postResolutionMessage.autoResolveIncident.deviceId.get,
        data = ICDAlarmIncidentData(
          alarm = ICDAlarmIncidentDataAlarm(
            alarmId = 45,
            happenedAt = Some(postResolutionMessage.autoResolveIncident.ts.getOrElse(incidentTimeInMs)),
            defer = None,
            acts = None
          ),
          snapshot = postResolutionMessage.autoResolveIncident.data.get.snapshot
        ),
        scheduledNotificationInfo = None,
        userActivityEvent = None,
        postAutoResolutionInfo = Some(
          PostAutoResolutionInfo(
            alarmId = postResolutionMessage.originalAlert.alarmId,
            alarmFriendlyName = postResolutionMessage.originalAlert.friendlyName,
            previousIncidentTimeUTC = postResolutionMessage.originalAlert.incidentTime,
            statusMessage = postResolutionMessage.autoResolveIncident.statusMessage
          )
        )
      )
      log.info(s"Send Auto Resolution Alert to Decision engine for deviceId: ${postResolutionMessage.autoResolveIncident.deviceId.get} Auto resolution for Alarm id : ${postResolutionMessage.originalAlert.alarmId} ")
      decisionEngine ! autoResolutionAlarm


      context.stop(self)

  }

}

object PostResolutionAlerts {
  def props(
             decisionEngine: ActorRef
           ): Props = Props(classOf[PostResolutionAlerts], decisionEngine)
}