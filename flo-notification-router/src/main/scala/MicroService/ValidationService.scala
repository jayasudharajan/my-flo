package MicroService

import MicroService.Validation.{ICDValidation, LocationValidation}
import Models.Mediums.AndroidMobileDeviceMessage
import Models.ExternalActions.ValveStatusActorMessage
import com.flo.Models.{ICD, ICDAlarmNotificationDeliveryRules, Location}
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.KafkaMessages.{ICDAlarmIncident, ICDAlarmIncidentStatus}
import com.flo.Models.Users.UserAlarmNotificationDeliveryRules
import com.typesafe.scalalogging.LazyLogging

import scala.util.Try

/**
  * Created by Francisco on 1/11/2017.
  */
/**
  * The purpose of this micro service is for general validations, kafka messages, methods params etc
  **/
class ValidationService extends LazyLogging {
  private lazy val icdValidation = new ICDValidation()
  private lazy val locationValidation = new LocationValidation()

  /**
    * this method validates the message from Kafka we get for external actions -> valve status, which is pretty much only the Telemetry Compact object, however for this particular actor there are some telemetry values that are a most. It returns true if validated, throws an illegal argument exception otheriwise.
    **/

  def valveStatusActorMessageValidator(m: ValveStatusActorMessage): Boolean = m match {

    case empty if empty == null =>
      throw new IllegalArgumentException("ValveStatusActorMessage cannot be  null ")
    case noTelemetry if noTelemetry.telemetry.isEmpty =>
      throw new IllegalArgumentException("telemetry cannot be None ")
    case missingEssentials if missingEssentials.telemetry.get.did.isEmpty || missingEssentials.telemetry.get.sw1.isEmpty || missingEssentials.telemetry.get.sw2.isEmpty =>
      throw new IllegalArgumentException("did, sw1, sw2 are required")
    case _ =>
      true
  }


  /**
    * This method will validate the message we receive from kafka for external-action-valve-status returns true if message passes validation returns an exception with a message explaining the validation failure otherwise.
    **/
  def iCDAlarmIncidentStatusValidator(msg: ICDAlarmIncidentStatus): Boolean = {

    if (msg.data.isEmpty) {
      throw new IllegalArgumentException("data property of kafka message cannot be empty")
    }
    else if (msg.status.isEmpty) {
      throw new IllegalArgumentException("Status property of kafka message cannot be empty")
    }
    else if (msg.deviceId.isEmpty) {
      throw new IllegalArgumentException("Device id  property of kafka message cannot be empty")
    }
    else if (msg.data.get.snapshot == null) {
      throw new IllegalArgumentException("Snapshot property of kafka message cannot be empty")
    }
    true

  }

  /**
    * This methods is similar to the regular Incident Message validation except it checks the scheduled notification first, it will throw an exception if there is a validation error, it will return true otherwise.
    **/
  def scheduledNotificationMessageValidation(m: ICDAlarmIncident): Try[Boolean] = {

    val did = m.deviceId
    if (m.scheduledNotificationInfo.isEmpty) {
      throw new IllegalArgumentException(s"scheduledNotificationInfo cannot be empty did: $did ")
    }
    if (m.scheduledNotificationInfo.get.mediums.isEmpty)
      throw new IllegalArgumentException(s"scheduledNotificationInfo.mediums cannot be empty did: $did")
    if (m.scheduledNotificationInfo.get.scheduledDeliveryTime.isEmpty)
      throw new IllegalArgumentException(s"scheduledNotificationInfo.scheduledDeliveryTime cannot be empty did: $did")
    if (m.scheduledNotificationInfo.get.scheduledAt.isEmpty)
      throw new IllegalArgumentException(s"scheduledNotificationInfo.scheduledAt cannot be empty did: $did")

    try {
      iCDAlarmIncidentMessageValidation(m)
    }
    catch {
      case e: Throwable =>
        throw e
    }
    Try(true)

  }

  /**
    * This method verifies the integrity of the message sent from the FLo Device to the cloud, many thing can make this
    * message corrupt including the firmware version of the device. This method will return True if the message is legit,
    * it will return an exception  otherwise.
    **/
  def iCDAlarmIncidentMessageValidation(m: ICDAlarmIncident): Boolean = {

    if (m.data.alarm.alarmId < 1) {
      throw new IllegalArgumentException(s"data.alarm.alarmId was empty in notification message received. Device-id: ${m.deviceId}")
    }
    true

  }

  /**
    * This method is to verify that all required properties are sent to the Android Push notification actor
    **/
  def validateAndroidMobileDeviceMessage(m: AndroidMobileDeviceMessage): Boolean = m match {

    case noAndroidPushNotification if noAndroidPushNotification.androidPushNotification.isEmpty =>
      throw new IllegalArgumentException("androidPushNotification needs to be defined")
    case noNotificationTokens if noNotificationTokens.notificationTokens.isEmpty =>
      throw new IllegalArgumentException("needs to have notification tokens")
    case noAndroidPushNotificationTokens if noAndroidPushNotificationTokens.notificationTokens.get.androidToken.isEmpty =>
      throw new IllegalArgumentException("needs to have notification tokens for android")
    case _ =>
      true

  }

  /**
    * LAVISH VALIDATION
    **/
  def snapshotLavishValidation(snapshot: ICDAlarmIncidentDataSnapshot, deviceId: String): Unit = {

    val lMessage = s"VALIDATION+ snapshot for $deviceId is missing property: "

    if (snapshot.eventFlowLimit.isEmpty) logger.warn(s"$lMessage eventFlowLimit")
    if (snapshot.eventFlow.isEmpty) logger.warn(s"$lMessage eventFlow")
    if (snapshot.eventFlowDurationInSeconds.isEmpty) logger.warn(s"$lMessage eventFlowDurationInSeconds")
    if (snapshot.flow.isEmpty) logger.warn(s"$lMessage flow")
    if (snapshot.eventFlowDurationLimitInSeconds.isEmpty) logger.warn(s"$lMessage eventFlowDurationLimitInSeconds")
    if (snapshot.flowRate.isEmpty) logger.warn(s"$lMessage flowRate")
    if (snapshot.flowRateLimit.isEmpty) logger.warn(s"$lMessage flowRateLimit")
    if (snapshot.flowTotalization.isEmpty) logger.warn(s"$lMessage flowTotalization")
    if (snapshot.flowTotalizationLimit.isEmpty) logger.warn(s"$lMessage flowTotalizationLimit")
    if (snapshot.localTime.isEmpty) logger.warn(s"$lMessage localTime")
    if (snapshot.pressure.isEmpty) logger.warn(s"$lMessage pressure")
    if (snapshot.pressureMaximus.isEmpty) logger.warn(s"$lMessage pressureMaximus")
    if (snapshot.pressureMinimum.isEmpty) logger.warn(s"$lMessage pressureMinimum")
    if (snapshot.systemMode.isEmpty) logger.warn(s"$lMessage systemMode")
    if (snapshot.temperature.isEmpty) logger.warn(s"$lMessage temperature")
    if (snapshot.temperatureMaximum.isEmpty) logger.warn(s"$lMessage temperatureMaximum")
    if (snapshot.temperatureMinimum.isEmpty) logger.warn(s"$lMessage temperatureMinimum")
    if (snapshot.timeZone.isEmpty) logger.warn(s"$lMessage timeZone")
    if (snapshot.valveSwitch1.isEmpty) logger.warn(s"$lMessage valveSwitch1")
    if (snapshot.valveSwitch2.isEmpty) logger.warn(s"$lMessage valveSwitch2")
  }

  def userAlarmNotificationDeliveryRulesLavishValidation(userAlarmNotificationDeliveryRules: UserAlarmNotificationDeliveryRules, deviceId: String): Unit = {

    val lMessage = s"VALIDATION+ UserAlarmNotificationDeliveryRules for device id: $deviceId userId: ${userAlarmNotificationDeliveryRules.userId} alarm id : ${userAlarmNotificationDeliveryRules.alarmId} system mode: ${userAlarmNotificationDeliveryRules.systemMode} is missing property: "
    if (userAlarmNotificationDeliveryRules.filterSettings.isEmpty) logger.warn(s"$lMessage filterSettings")
    if (userAlarmNotificationDeliveryRules.graveyardTime.isEmpty) logger.warn(s"$lMessage graveyardTime")

  }

  def icdLavishValidation(icd: ICD): Unit = {

    val lMessage = s"VALIDATION+ ICD for device id: ${icd.deviceId.getOrElse("N/A")} is missing property: "
    if (icd.deviceId.isEmpty) logger.warn(s"$lMessage deviceId")
    if (icd.id.isEmpty) logger.warn(s"$lMessage id")
    if (icd.locationId.isEmpty) logger.warn(s"$lMessage locationId")

  }

  def icdAlarmNotificationDeliveryRulesLavishValidation(rules: ICDAlarmNotificationDeliveryRules): Unit = {

    val lMessage = s"VALIDATION+ ICDAlarmNotificationDeliveryRules for alarm id: ${rules.alarmId} system mode: ${rules.systemMode} is missing property: "
    if (rules.filterSettings.isEmpty) logger.warn(s"$lMessage filterSettings")
    if (rules.graveyardTime.isEmpty) logger.warn(s"$lMessage graveyardTime")
    if (rules.userActions.isEmpty) logger.warn(s"$lMessage userActions")
    if (rules.userActions.isDefined && rules.userActions.nonEmpty && rules.userActions.get.supportOptions.isEmpty) logger.warn(s"$lMessage supportOptions")
  }

  def iCDAlarmIncidentLavishValidation(incident: ICDAlarmIncident): Unit = {

    val lMessage = s"VALIDATION+ ICDAlarmIncident for icd alarm incident id: ${incident.id} is missing property: "
    if (incident.id.isEmpty) logger.warn(s"$lMessage id")
    if (incident.deviceId.isEmpty) logger.warn(s"$lMessage deviceId")

  }


  def validateRudimentaryInfo(icd: Option[ICD], userIdList: Option[Set[String]], location: Option[Location]): Either[Throwable, Boolean] = {
    var passed = true
    icdValidation.validateIcd(icd) match {
      case Left(ex) => Left(throw new IllegalArgumentException("following issues happened validating icd: ", ex))
      case Right(valid) => passed = valid
    }

    if (userIdList.isEmpty) Left(throw new IllegalStateException("This icd doesn't have any users, useridList is empty"))

    locationValidation.validateLocation(location) match {
      case Left(ex) => Left(throw new IllegalArgumentException("following issue happened validating location", ex))
      case Right(valid) => passed = valid

    }
    Right(passed)
  }


}
