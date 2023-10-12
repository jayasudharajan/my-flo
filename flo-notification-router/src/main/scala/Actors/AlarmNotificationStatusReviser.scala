package Actors

import MicroService.{AlertService, TimeService, ValidationService}
import Models.PostResolutionAlertMessage
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, ActorRef, ActorSystem, OneForOneStrategy, Props, SupervisorStrategy}
import akka.stream.ActorMaterializer
import com.flo.Enums.Notifications.AlarmNotificationStatuses
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.{AlarmNotificationDeliveryFiltersEndpoints, ICDAlarmIncidentRegistryEndpoints, ICDAlarmNotificationStatusRegistryEndpoints, ICDEndpoints}
import com.flo.Models.AlarmNotificationDeliveryFilters
import com.flo.Models.KafkaMessages.ICDAlarmIncidentStatus
import com.flo.Models.Logs.{ICDAlarmIncidentRegistry, ICDAlarmNotificationStatusRegistry}
import com.flo.utils.HttpMetrics
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

/**
  * Created by Francisco on 10/19/2016.
  */

/**
  * This actor will handle and coordinate all the revisions that need to happen when an alarm incident self-resolve and user
  * action is no longer needed to resolve the notification.
  **/
class AlarmNotificationStatusReviser(decisionEngine: ActorRef) extends Actor with ActorLogging {
  implicit val materializer: ActorMaterializer = ActorMaterializer()(context)
  implicit val system: ActorSystem = context.system

  implicit val httpMetrics: HttpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )

  private val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()
  //API
  private lazy val FLO_PROXY_ALARM_NOTIFICATION_DELIVERY_FILTERS = new AlarmNotificationDeliveryFiltersEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_ICD = new ICDEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY = new ICDAlarmIncidentRegistryEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_ICD_ALARM_NOTIFICATION_STATUS_REGISTRY = new ICDAlarmNotificationStatusRegistryEndpoints(clientCredentialsTokenProvider)

  //services
  private lazy val VALIDATION_SERVICE = new ValidationService()
  private lazy val alertService = new AlertService(context)
  private lazy val timeService = new TimeService()

  override def supervisorStrategy = OneForOneStrategy() {
    case (ex: Throwable) => log.error(ex, "")
      SupervisorStrategy.Stop
  }

  def receive = {
    case alarmIncidentStatusMsg: ICDAlarmIncidentStatus =>
      try {

        // Validate message
        if (!VALIDATION_SERVICE.iCDAlarmIncidentStatusValidator(alarmIncidentStatusMsg)) {
          throw new Exception("kafka alarmIncidentStatusMsg could not be validated")
        }

        val incidentTime = timeService.epochTimeStampToStringISODate(alarmIncidentStatusMsg.ts)

        for {
          //Get Icd by device id
          icd <- FLO_PROXY_ICD.GetByDeviceId(alarmIncidentStatusMsg.deviceId.get) recoverWith {
            case e: Throwable =>
              log.error(s"ficd ${e.toString}")
              throw e
          }

          // Retrieve alarm notification filter record
          alarmFilter <- FLO_PROXY_ALARM_NOTIFICATION_DELIVERY_FILTERS.GetByIcdIdAndByAlarmIdAndBySystemMode(
            icdId = icd.get.id.getOrElse(throw new IllegalArgumentException("Missing icd.id property")),
            alarmId = alarmIncidentStatusMsg.data.get.alarm.alarmId,
            systemMode = alarmIncidentStatusMsg.data.get.snapshot.systemMode.getOrElse(throw new IllegalArgumentException("Missing alarmIncidentStatusMsg.data.get.snapshot.systemMode property"))
          ) recoverWith {
            case e: Throwable =>
              log.error(s"falarmFilter ${e.toString}")
              throw e
          }

          // retrieve ICDAlarmNotificationIncidentRegistry Record
          icdAlarmIncidentRegistry <- FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY.Get(alarmFilter.getOrElse(throw new Exception("No filter found")).lastIcdAlarmIncidentRegistryId.get) recoverWith {
            case e: Throwable =>
              log.error(s"ficdAlarmIncidentRegistry ${e.toString}")
              throw e
          }

        } yield {

          //Validation for info queries  ICD, Alarm Filter, and incident registry

          if (icd.get.id.isEmpty) {
            throw new Exception(s"icd with device id : ${alarmIncidentStatusMsg.deviceId.getOrElse("N/A")} not found")
          }
          else if (alarmFilter.get.lastIcdAlarmIncidentRegistryId.isEmpty) {
            throw new Exception(s"alarmFilter for icd id ${icd.get.id.getOrElse("N/A")} alarm and system mode ${alarmIncidentStatusMsg.data.get.alarm.alarmId} - ${alarmIncidentStatusMsg.data.get.snapshot.systemMode.getOrElse("N/A")}  was not found ")
          }
          else if (icdAlarmIncidentRegistry.get.id.isEmpty) {
            throw new Exception(s"icdAlarmIncidentRegistry with id ${alarmFilter.get.lastIcdAlarmIncidentRegistryId.getOrElse("N/A")} not found ")

          }

          /** Auto Resolution alarm flow
            * */

          if (alertService.triggersAutoResolutionAlert(icdAlarmIncidentRegistry.get.alarmId, icdAlarmIncidentRegistry.get.icdData.systemMode.get)) {
            val postResolutionAlertsActor = context.actorOf(PostResolutionAlerts.props(decisionEngine))

            postResolutionAlertsActor ! PostResolutionAlertMessage(
              icdAlarmIncidentRegistry.get,
              alarmIncidentStatusMsg
            )
          }

          /** Auto Resolution alarm flow  Ends
            * */

          // Record ICDAlarm Notification Status Message in Registry

          FLO_PROXY_ICD_ALARM_NOTIFICATION_STATUS_REGISTRY.Post(
            Some(
              ICDAlarmNotificationStatusRegistry(
                id = Some(java.util.UUID.randomUUID().toString),
                icdAlarmIncidentRegistryId = Some(icdAlarmIncidentRegistry.get.id),
                createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
                incidentTime = Some(incidentTime),
                status = alarmIncidentStatusMsg.status,
                alarmIncidentStatusMsg.statusMessage,
                icdId = icd.get.id,
                data = alarmIncidentStatusMsg.data

              )
            )
          ).onComplete {
            case Success(s) =>
              log.info(s"Successfully posted alarm notification status for icd id: ${icd.get.id.getOrElse("N/A")}")
            case Failure(e) => log.error(s"FLO_PROXY_ICD_ALARM_NOTIFICATION_STATUS_REGISTRY.Post ${e.toString}")
          }

          // Update Filter Status to resolved
          FLO_PROXY_ALARM_NOTIFICATION_DELIVERY_FILTERS.Put(
            Some(
              AlarmNotificationDeliveryFilters(
                icdId = alarmFilter.get.icdId,
                alarmId = alarmFilter.get.alarmId,
                systemMode = alarmFilter.get.systemMode,
                createdAt = alarmFilter.get.createdAt,
                updatedAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
                expiresAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
                lastDecisionUserId = alarmFilter.get.lastDecisionUserId,
                status = Some(AlarmNotificationStatuses.RESOLVED),
                lastIcdAlarmIncidentRegistryId = alarmFilter.get.lastIcdAlarmIncidentRegistryId,
                incidentTime = alarmFilter.get.incidentTime,
                severity = alarmFilter.get.severity
              )
            )
          ).onComplete {
            case Success(s) =>
              log.info(s"Succesfully made put for alarm notification status delivery filter icd id: ${icd.get.id.getOrElse("N/A")} alarm id and system mode ${alarmFilter.get.alarmId.getOrElse("N/A")}-${alarmFilter.get.systemMode.getOrElse("N/A")} ")
            case Failure(e) => log.error(s"FLO_PROXY_ALARM_NOTIFICATION_DELIVERY_FILTERS.Put ${e.toString}")

          }

          // Update ICDAlarmNotificationIncidentRegistry record with necessary information
          FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY.Put(
            Some(
              ICDAlarmIncidentRegistry(
                id = icdAlarmIncidentRegistry.get.id,
                incidentTime = icdAlarmIncidentRegistry.get.incidentTime,
                createdAt = icdAlarmIncidentRegistry.get.createdAt,
                accountId = icdAlarmIncidentRegistry.get.accountId,
                locationId = icdAlarmIncidentRegistry.get.locationId,
                icdId = icdAlarmIncidentRegistry.get.icdId,
                alarmId = icdAlarmIncidentRegistry.get.alarmId,
                alarmName = icdAlarmIncidentRegistry.get.alarmName,
                users = icdAlarmIncidentRegistry.get.users,
                userActionTaken = icdAlarmIncidentRegistry.get.userActionTaken,
                acknowledgeByUser = icdAlarmIncidentRegistry.get.acknowledgeByUser,
                icdData = icdAlarmIncidentRegistry.get.icdData,
                telemetryData = icdAlarmIncidentRegistry.get.telemetryData,
                severity = icdAlarmIncidentRegistry.get.severity,
                friendlyName = icdAlarmIncidentRegistry.get.friendlyName,
                selfResolved = Some(1),
                selfResolvedMessage = alarmIncidentStatusMsg.statusMessage,
                friendlyDescription = icdAlarmIncidentRegistry.get.friendlyDescription
              )
            )
          ).onComplete {
            case Success(s) => log.info(s"Successfully made put operation for ICD_ALARM_INCIDENT_REGISTRY registry id : ${icdAlarmIncidentRegistry.get.id}")
            case Failure(ex) => log.error(ex, s"FLO_PROXY_ICD_ALARM_INCIDENT_REGISTRY.Put failed for incident id ${icdAlarmIncidentRegistry.get.id} DID : ${icdAlarmIncidentRegistry.get.icdData.deviceId}")
          }

        }

      }
      catch {
        case e: Throwable =>
          log.error(e.toString)
      }

  }

}

object AlarmNotificationStatusReviser {
  def props(
             decisionEngine: ActorRef
           ): Props = Props(classOf[AlarmNotificationStatusReviser], decisionEngine)
}

// Walk like a dinosaur
/*
	* 	*                                                     .--.__
	*                                                       .~ (@)  ~~~---_
	*                                                      {     `-_~,,,,,,)
	*                                                      {    (_  ',
	*                                                       ~    . = _',
	*                                                        ~-   '.  =-'
	*                                                          ~     :
	*       .                                             _,.-~     ('');
	*       '.                                         .-~        \  \ ;
	*         ':-_                                _.--~            \  \;      _-=,.
	*           ~-:-.__                       _.-~                 {  '---- _'-=,.
	*              ~-._~--._             __.-~                     ~---------=,.`
	*                  ~~-._~~-----~~~~~~       .+++~~~~~~~~-__   /
	*                       ~-.,____           {   -     +   }  _/
	*                               ~~-.______{_    _ -=\ / /_.~
	*                                    :      ~--~    // /         ..-
	*                                    :   / /      // /         ((
	*                                    :  / /      {   `-------,. ))
	*                                    :   /        ''=--------. }o
	*                       .=._________,'  )                     ))
	*                       )  _________ -''                     ~~
	*                      / /  _ _
	*                     (_.-.'O'-'.
	*/