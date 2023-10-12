package Nators

import MicroService._
import akka.actor.ActorContext
import akka.stream.ActorMaterializer
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.UserAlarmNotificationDeliveryRules
import com.flo.Models.{ICD, ICDAlarmNotificationDeliveryRules, Location}
import org.joda.time.{DateTime, DateTimeZone}

import scala.collection.parallel.mutable.ParSet

class ICDAlarmIncidentRegistryGenerators(context: ActorContext, unitSystem: MeasurementUnitSystem) {


  implicit val materializer = ActorMaterializer()(context)
  implicit val system = context.system

  //services
  private lazy val decisionService = new DecisionEngineService(unitSystem)
  private lazy val templateService = new TemplateService(unitSystem)
  private lazy val alertService = new AlertService(context)
  private lazy val timeService = new TimeService()
  private lazy val iCDAlarmNotificationDeliveryRuleService = new ICDAlarmNotificationDeliveryRuleService()
  private lazy val snapshotService = new SnapShotMicroService()

  def incidentPostGenerator(icdLocation: Location, iCD: ICD, icdAlarmIncidentMessage: ICDAlarmIncident, icdAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules, usersDeliveryRules: ParSet[UserAlarmNotificationDeliveryRules], incidentId: String, userName: String): ICDAlarmIncidentRegistry = {
    val deviceId = icdAlarmIncidentMessage.deviceId

    val snapshot = icdAlarmIncidentMessage.data.snapshot
    ICDAlarmIncidentRegistry(
      id = incidentId,
      createdAt = DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString(),
      accountId = icdLocation.accountId,
      locationId = icdLocation.locationId,
      icdId = iCD.id.get,
      users = iCDAlarmNotificationDeliveryRuleService.ICDAlarmIncidentRegistryUserGenerator(Some(usersDeliveryRules)),
      incidentTime = timeService.epochTimeStampToStringISODate(Some(icdAlarmIncidentMessage.ts)),
      alarmId = icdAlarmIncidentMessage.data.alarm.alarmId,
      alarmName = Some(icdAlarmNotificationDeliveryRules.messageTemplates.name),
      userActionTaken = None,
      acknowledgeByUser = if (alertService.isAlarmAutoLog(icdAlarmNotificationDeliveryRules.internalId) || alertService.isAlarmInfoLevel(icdAlarmNotificationDeliveryRules.severity) || alertService.hasUserMutedTheAlarm(usersDeliveryRules)) 1 else 0,
      icdData = ICD(
        deviceId = Some(deviceId),
        timeZone = snapshot.timeZone,
        systemMode = snapshot.systemMode,
        localTime = snapshot.localTime,
        id = iCD.id,
        locationId = iCD.locationId
      ),
      telemetryData = snapshotService.snapshotToTelemetryGenerator(snapshot),
      severity = icdAlarmNotificationDeliveryRules.severity,
      friendlyName = icdAlarmNotificationDeliveryRules.messageTemplates.friendlyName,
      selfResolved = Some(0),
      selfResolvedMessage = None,
      friendlyDescription = templateService.deconstructIncidentRegistryFriendlyDescription(icdAlarmNotificationDeliveryRules.messageTemplates.friendlyDescription, icdLocation.timezone.get, timeService.epochTimeStampToStringISODate(Some(icdAlarmIncidentMessage.ts)), TimeFormat.MM_DD_HH_MM_A, snapshot, icdAlarmIncidentMessage.postAutoResolutionInfo, icdAlarmIncidentMessage.userActivityEvent, userName, Some(icdAlarmNotificationDeliveryRules.alarmId), unitSystem)
    )
  }

}
