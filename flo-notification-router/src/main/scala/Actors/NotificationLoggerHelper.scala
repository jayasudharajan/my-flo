package Actors

import MicroService.{SnapShotMicroService, _}
import Utils.ApplicationSettings
import akka.actor.ActorContext
import akka.event.LoggingAdapter
import akka.stream.ActorMaterializer
import com.flo.Enums.Notifications.{AlarmNotificationStatuses, DeliveryMediums, ICDAlarmIncidentRegistryLogStatus}
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.FloApi.v2.{LocationEndpoints, _}
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.{ICDAlarmIncidentDataSnapshot, UserActivityEvent}
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.Logs.{ICDAlarmIncidentRegistry, ICDAlarmIncidentRegistryLog}
import com.flo.Models.Users.UserAlarmNotificationDeliveryRules
import com.flo.Models.{AlarmNotificationDeliveryFilters, ICD, ICDAlarmNotificationDeliveryRules, Location}
import com.flo.utils.HttpMetrics
import kamon.Kamon
import org.joda.time.{DateTime, DateTimeZone}

import scala.collection.parallel.mutable.ParSet
import scala.concurrent.{Await, Future}
import scala.concurrent.duration._


class NotificationLoggerHelper(context: ActorContext, log: LoggingAdapter) {

  import context.dispatcher

  implicit val mt = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  val icdAlarmNotificationDeliveryRulesEndpoint = new ICDAlarmNotificationDeliveryRulesEndpoints(clientCredentialsTokenProvider)
  val userAlarmDeliveryRulesEndpoints = new UserAlarmDeliveryRulesEndpoints(clientCredentialsTokenProvider)
  val icdAlarmIncidentRegistryEndpoints = new ICDAlarmIncidentRegistryEndpoints(clientCredentialsTokenProvider)
  val alarmNotificationDeliveryFiltersEndpoints = new AlarmNotificationDeliveryFiltersEndpoints(clientCredentialsTokenProvider)
  private lazy val FLO_PROXY_USER_CONTACT_INFORMATION = new UserContactInformationEndpoints(clientCredentialsTokenProvider)

  // services
  val timeService = new TimeService()
  val snapshotService = new SnapShotMicroService()
  val iCDAlarmNotificationDeliveryRuleService = new ICDAlarmNotificationDeliveryRuleService()


  def getUUID(): String = java.util.UUID.randomUUID().toString

  def getIcdAlarmIncidentRegistryLog(
                                      icdIncidentRegistryRecord: ICDAlarmIncidentRegistry
                                    ): ICDAlarmIncidentRegistryLog = {
    ICDAlarmIncidentRegistryLog(
      id = Some(getUUID),
      createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
      icdAlarmIncidentRegistryId = Some(icdIncidentRegistryRecord.id),
      userId = None,
      deliveryMedium = Some(DeliveryMediums.FILTERED),
      status = Some(ICDAlarmIncidentRegistryLogStatus.NONE),
      receiptId = Some(getUUID)
    )
  }


  def getIcdAlarmNotificationDeliveryRules(alarmId: Int, systemMode: Int): Future[Option[ICDAlarmNotificationDeliveryRules]] = {
    icdAlarmNotificationDeliveryRulesEndpoint.GetByAlarmIdAndBySystemMode(alarmId, systemMode) recoverWith {
      case e: Throwable =>
        log.error(s"fIcdAlarmNotificationDeliveryRules ${e.toString}")
        throw e
    }
  }

  def createIcdIncidentRegistryRecord(
                                       icd: ICD,
                                       icdLocation: Location,
                                       alarmId: Int,
                                       alarmDeliveryRules: ICDAlarmNotificationDeliveryRules,
                                       deviceId: String,
                                       snapshot: ICDAlarmIncidentDataSnapshot,
                                       ultimateUserAlarmNotificationDeliveryRules: ParSet[UserAlarmNotificationDeliveryRules],
                                       icdAlarmIncidentTimestamp: Option[Long],
                                       id: String,
                                       incident: ICDAlarmIncident,
                                       unitSystem: MeasurementUnitSystem
                                     ): Future[Option[ICDAlarmIncidentRegistry]] = {

    val templateService = new TemplateService(unitSystem)
    icdAlarmIncidentRegistryEndpoints.Post(Some(ICDAlarmIncidentRegistry(
      id,
      createdAt = DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString(),
      accountId = icdLocation.accountId,
      locationId = icdLocation.locationId,
      icdId = icd.id.get,
      users = iCDAlarmNotificationDeliveryRuleService.ICDAlarmIncidentRegistryUserGenerator(Some(ultimateUserAlarmNotificationDeliveryRules)),
      incidentTime = timeService.epochTimeStampToStringISODate(icdAlarmIncidentTimestamp),
      alarmId = alarmId,
      alarmName = Some(alarmDeliveryRules.messageTemplates.name),
      userActionTaken = None,
      acknowledgeByUser = 0,
      icdData = ICD(
        deviceId = Some(deviceId),
        timeZone = snapshot.timeZone,
        systemMode = snapshot.systemMode,
        localTime = snapshot.localTime,
        id = icd.id,
        locationId = icd.locationId
      ),
      telemetryData = snapshotService.snapshotToTelemetryGenerator(snapshot),
      severity = alarmDeliveryRules.severity,
      friendlyName = alarmDeliveryRules.messageTemplates.friendlyName,
      selfResolved = Some(0),
      selfResolvedMessage = None,
      friendlyDescription = templateService.deconstructIncidentRegistryFriendlyDescription(alarmDeliveryRules.messageTemplates.friendlyDescription, icdLocation.timezone.get, timeService.epochTimeStampToStringISODate(icdAlarmIncidentTimestamp), TimeFormat.MM_DD_HH_MM_A, snapshot, incident.postAutoResolutionInfo, incident.userActivityEvent, userName = getUserNameForUserActivityEvent(incident.userActivityEvent), Some(alarmId), unitSystem)

    ))) recoverWith {
      case e: Throwable =>
        log.error(s"fCreateIcdIncidentRegistryRecord ${e.toString}")
        throw e
    }
  }

  private def getUserNameForUserActivityEvent(userActivityEvent: Option[UserActivityEvent]): String = userActivityEvent match {
    case None =>
      "N/A"
    case Some(userActivity) =>

      Await.result(FLO_PROXY_USER_CONTACT_INFORMATION.GetPlusEmail(userActivity.userId), 10 seconds) match {
        case None =>
          "N/A"
        case Some(info) =>
          s"${info.firstName.getOrElse("")} ${nameToInitial(info.lastName, addPeriod = true)}"
      }


  }

  private def nameToInitial(name: Option[String], addPeriod: Boolean = false): String = name match {
    case None =>
      ""
    case Some(userName) if userName.isEmpty =>
      ""
    case Some(n) =>
      s"${n.subSequence(0, 1).toString.toUpperCase()}${if (addPeriod) "."} "
  }

  def getUltimateAlarmNotificationDeliveryFilters(
                                                   icd: ICD,
                                                   alarmNotificationDeliveryFilters: Option[AlarmNotificationDeliveryFilters],
                                                   createIcdIncidentRegistryRecord: ICDAlarmIncidentRegistry,
                                                   icdAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules,
                                                   snapshot: ICDAlarmIncidentDataSnapshot,
                                                   incidentTimestamp: Option[Long]
                                                 ): Future[Option[AlarmNotificationDeliveryFilters]] = {
    ultimateNotificationDeliveryService(alarmNotificationDeliveryFilters, icd, Some(createIcdIncidentRegistryRecord.id), icdAlarmNotificationDeliveryRules, snapshot, incidentTimestamp) recoverWith {
      case e: Throwable =>
        log.error(e, s"fUltimateAlarmNoticatificationDeliveryFilters ${e.toString}")
        throw e
    }
  }

  def getUserAlarmNotificationDeliveryRules(
                                             icd: ICD,
                                             icdAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules,
                                             snapshot: ICDAlarmIncidentDataSnapshot
                                           ): Future[Option[Set[UserAlarmNotificationDeliveryRules]]] = {
    userAlarmDeliveryRulesEndpoints.GetByLocationIdAndAlarmDeliveryRulesIdAndSystemMode(
      icd.locationId.getOrElse(throw new IllegalArgumentException("location_id was not found in icd retrieved")),
      icdAlarmNotificationDeliveryRules.alarmId,
      snapshot.systemMode.getOrElse(throw new IllegalArgumentException("systemMode was not found in icd object received from ICDAlarmIncident"))) recoverWith {
      case e: Throwable =>
        log.error(s"fUserAlarmNotificationDeliveryRules ${e.toString}")
        throw e
    }
  }

  def getAlarmNotificationDeliveryFilters(icd: ICD, alarmId: Int, systemMode: Int): Future[Option[AlarmNotificationDeliveryFilters]] = {
    alarmNotificationDeliveryFiltersEndpoints.GetByIcdIdAndByAlarmIdAndBySystemMode(icd.id.get, alarmId, systemMode) recoverWith {
      case e: Throwable =>
        log.error(s"fAlarmNotificationDeliveryFilters ${e.toString}")
        throw e
    }
  }

  def ultimateNotificationDeliveryService(
                                           filters: Option[AlarmNotificationDeliveryFilters],
                                           icd: ICD,
                                           incidentId: Option[String],
                                           deliveryRules: ICDAlarmNotificationDeliveryRules,
                                           snapshot: ICDAlarmIncidentDataSnapshot,
                                           incidentTs: Option[Long]
                                         ): Future[Option[AlarmNotificationDeliveryFilters]] = {
    if (filters.isDefined && filters.get.icdId.isDefined) {
      Future {
        filters
      }
    }
    else {
      alarmNotificationDeliveryFiltersEndpoints.Post(
        Some(
          AlarmNotificationDeliveryFilters(
            icdId = icd.id,
            alarmId = Some(deliveryRules.alarmId),
            createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            updatedAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            expiresAt = Some(DateTime.now(DateTimeZone.UTC).plusYears(100).toDateTimeISO.toString()),
            lastDecisionUserId = None,
            status = Some(AlarmNotificationStatuses.UNRESOLVED),
            systemMode = snapshot.systemMode,
            lastIcdAlarmIncidentRegistryId = incidentId,
            incidentTime = Some(timeService.epochTimeStampToStringISODate(incidentTs)),
            severity = Some(deliveryRules.severity)
          )
        )
      )
    }
  }
}
