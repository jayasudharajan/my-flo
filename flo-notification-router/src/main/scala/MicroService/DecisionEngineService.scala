package MicroService

import Utils.ApplicationSettings
import com.flo.Enums.Notifications.{AlarmSeverity, DeliveryMediums}
import com.flo.Models._
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.ZITInterrupt.APNSZITInterruptedResult
import com.flo.Models.ZITSuccess.APNSZITSuccessResult
import com.typesafe.scalalogging.LazyLogging
import org.joda.time.{DateTime, DateTimeZone}
import argonaut.Argonaut._
import com.flo.Enums.Templates.TemplateKeywords
import com.flo.Models.Android.{Data, GCM, Notification, PushNotification}
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.PostAutoResolutionInfo
import com.flo.Models.Locale.MeasurementUnitSystem


/**
  * Created by Francisco on 9/6/2016.
  */
class DecisionEngineService(unitSystem: MeasurementUnitSystem) extends LazyLogging {

  private lazy val templateService = new TemplateService(unitSystem)
  private lazy val enumService = new EnumsToStringService()
  private lazy val timeService = new TimeService()
  private lazy val graveyardTimeMicroService = new GraveyardTimeMicroService()


  /**
    * Translate the Alarm Severity enum into its string value, it returns an empty string otherwise
    **/
  def SeverityEnumToString(severity: Int): String = enumService.alarmSeverityToString(severity)

  /**
    * Builds a 150 characters SMS
    **/
  def SMSTextnator1505000(notification: ICDAlarmNotificationDeliveryRules, postAutoResolutionInfo: Option[PostAutoResolutionInfo] = None): Option[String] = {

    Some(s"${templateService.deconstructSMSText(notification, postAutoResolutionInfo)}")
  }

  /**
    * Builds the push notification Title  display message for android devices
    */
  def androidPushNotificationTitleGenerator(notification: ICDAlarmNotificationDeliveryRules): String = {

    templateService.deconstructPushNotificationTitle(notification, SeverityEnumToString(notification.severity))

  }

  /**
    * Builds the push notification Body  display message for android devices
    */
  def androidPushNotificationBodyGenerator(notification: ICDAlarmNotificationDeliveryRules, postAutoResolutionInfo: Option[PostAutoResolutionInfo] = None): String = {
    postAutoResolutionInfo match {
      case None =>
        templateService.deconstructAlarmName(notification.messageTemplates.pushNotificationMessage.body, TemplateKeywords.ALERT_FRIENDLY_NAME, notification.messageTemplates.friendlyName)
      case Some(info) if info.alarmId == 45 || notification.alarmId == 45 =>
        templateService.deconstructAlarmName(notification.messageTemplates.pushNotificationMessage.body, TemplateKeywords.PREVIOUS_ALERT_FRIENDLY_NAME, info.alarmFriendlyName)

    }

  }

  /**
    * Builds the push notification display message
    */
  def PushNotificationMessageGenerator(notification: ICDAlarmNotificationDeliveryRules, postAutoResolutionInfo: Option[PostAutoResolutionInfo] = None): Option[String] = {
    val severity: String = SeverityEnumToString(notification.severity)

    val body: String = postAutoResolutionInfo match {
      case None =>
        templateService.deconstructAlarmName(notification.messageTemplates.pushNotificationMessage.body, TemplateKeywords.ALERT_FRIENDLY_NAME, notification.messageTemplates.friendlyName)
      case Some(info) if info.alarmId == 45 || notification.alarmId == 45 =>
        templateService.deconstructAlarmName(notification.messageTemplates.pushNotificationMessage.body, TemplateKeywords.PREVIOUS_ALERT_FRIENDLY_NAME, info.alarmFriendlyName)
      case _ =>
        templateService.deconstructAlarmName(notification.messageTemplates.pushNotificationMessage.body, TemplateKeywords.ALERT_FRIENDLY_NAME, notification.messageTemplates.friendlyName)
    }
    Some(body)
  }


  /**
    * Builds the call back URL for the email tracking. When message is sent to email service and processed email service
    * will use this URL to post Updates
    **/
  def EmailStatusCallbackGenerator(url: String, iCDAlarmIncidentRegistryId: Option[String], userId: String): Option[String] = {
    if (iCDAlarmIncidentRegistryId.isEmpty || userId.isEmpty || url.isEmpty) {
      throw new Exception("All parameters need to not be empty to successfully create Email Status Callback url")
    }
    Some(s"$url/hooks/email/${iCDAlarmIncidentRegistryId.get}/$userId")
  }

  /**
    * Creates a GCM push notification  and creates  json object, it will turn an exception if json codification fails otherwise.
    **/
  def androidPushNotificationObjectGenerator(alarm: Option[ICDAlarmNotificationDeliveryRules], icdAlarmIncidentRegistry: ICDAlarmIncidentRegistry, icd: ICD, location: Location, postAutoResolutionInfo: Option[PostAutoResolutionInfo] = None): Option[PushNotification] = {
    try {
      if (alarm.isEmpty) throw new IllegalArgumentException("alarm cannot be empty")
      if (icdAlarmIncidentRegistry.id.isEmpty) throw new IllegalArgumentException("icdAlarmIncidentRegistryId cannot be empty ")

      var timezone = DateTimeZone.UTC
      if (location.timezone.isDefined) timezone = DateTimeZone.forID(location.timezone.get)
      val incidentTime = new DateTime(icdAlarmIncidentRegistry.incidentTime, timezone).toDateTimeISO.toString()

      Some(PushNotification(
        default = None,
        gcm = GCM(
          notification = Notification(
            body = androidPushNotificationBodyGenerator(alarm.get, postAutoResolutionInfo),
            title = androidPushNotificationTitleGenerator(alarm.get),
            tag = androidNotificationTagGenerator(alarm.get),
            color = androidNotificationColorGenerator(alarm.get.severity),
            clickAction = "com.flotechnologies.intent.action.INCIDENT"
          ),
          data = Data(
            FloAlarmNotification(
              iCDAlarmIncidentRegistryId = icdAlarmIncidentRegistry.id,
              ts = incidentTime,
              notification = FloAlarmNotificationAlarm(alarmId = alarm.get.alarmId, name = alarm.get.messageTemplates.name, severity = alarm.get.severity, icdAlarmIncidentRegistry.friendlyDescription),
              icd = FloAlarmNotificationIcd(icd.deviceId.get, timeZone = icd.timeZone.getOrElse(""), icd.systemMode.get, icd.id.getOrElse("")),
              version = 1
            )
          )
        ).asJson.nospaces.toString

      ))
    }
    catch {
      case e: Throwable => logger.error(s"during json codification for GCM push notification incident registry id : ${icdAlarmIncidentRegistry.id}  ${e.toString}")
        throw new Exception(e.toString)
    }


  }

  /**
    * For android push notifications Tags are like an id and if you send the same tag in multiple push notifications,
    * the android push notifications would delete the old ones and leave the most recent, we use alarm_id and system_mode
    * as a string as the tag for the push notification.
    **/
  def androidNotificationTagGenerator(alarm: ICDAlarmNotificationDeliveryRules): String = {
    alarm.alarmId.+(alarm.systemMode.toString)
  }

  /**
    * This method will generate the RGB color for the push notification for Android.
    **/
  def androidNotificationColorGenerator(severity: Int): String = severity match {
    case AlarmSeverity.HIGH =>
      "#D7342F"
    case AlarmSeverity.MEDIUM =>
      "#ED7B15"
    case AlarmSeverity.LOW =>
      "#1A77AC"
    case _ =>
      "#1A77AC"
  }

  /**
    * Creates a ApplePushNotification and creates the right json object based on the internal id of the alarm
    * notification, it will turn an exception if json codification fails otherwise.
    **/
  def ApplePushNotificationObjectGenerator(alarm: Option[ICDAlarmNotificationDeliveryRules], iCDAlarmIncidentRegistry: ICDAlarmIncidentRegistry, icd: ICD, loc: Location, postAutoResolutionInfo: Option[PostAutoResolutionInfo]): Option[ApplePushNotification] = {
    try {
      if (alarm.isEmpty) throw new IllegalArgumentException("notification cannot be empty")
      if (iCDAlarmIncidentRegistry.id.isEmpty) throw new IllegalArgumentException("icdAlarmIncidentRegistryId cannot be empty ")

      var timezone = DateTimeZone.UTC
      if (loc.timezone.isDefined) timezone = DateTimeZone.forID(loc.timezone.get)
      val incidentTime = new DateTime(iCDAlarmIncidentRegistry.incidentTime, timezone).toDateTimeISO.toString()

      Some(
        ApplePushNotification(
          apns = alarm.get.internalId match {
            case case1 if case1 == 1064 || case1 == 1065 || case1 == 1066 || case1 == 1070 || case1 == 1071 || case1 == 1072 =>
              logger.info(s"APNSZITSuccessResult notification internal if ${alarm.get.internalId}")
              APNSZITSuccessResult(
                aps = ZITSuccess.aps(
                  alert = PushNotificationMessageGenerator(alarm.get).getOrElse(throw new Exception("notification sent to PushNotificationMessageGenerator was not able to generate a alert message")),
                  category = ZITSuccess.category(
                    ZITSuccess.FloAlarmNotification(
                      iCDAlarmIncidentRegistryId = iCDAlarmIncidentRegistry.id,
                      ts = incidentTime,
                      notification = ZITSuccess.FloAlarmNotificationAlarm(alarmId = alarm.get.alarmId, name = alarm.get.messageTemplates.name, severity = alarm.get.severity),
                      icd = ZITSuccess.FloAlarmNotificationIcd(icd.deviceId.get, timeZone = icd.timeZone.getOrElse(""), icd.systemMode.get, icd.id.getOrElse(""))
                    )
                  )
                )
              ).asJson.toString()
            case case2 if case2 == 1067 || case2 == 1068 || case2 == 1069 =>
              logger.info(s"APNSZITInterruptedResult notification internal if ${alarm.get.internalId}")
              APNSZITInterruptedResult(
                aps = ZITInterrupt.aps(
                  alert = PushNotificationMessageGenerator(alarm.get).getOrElse(throw new Exception("notification sent to PushNotificationMessageGenerator was not able to generate a alert message")),
                  category = ZITInterrupt.category(
                    ZITInterrupt.FloAlarmNotification(
                      iCDAlarmIncidentRegistryId = iCDAlarmIncidentRegistry.id,
                      ts = incidentTime,
                      notification = ZITInterrupt.FloAlarmNotificationAlarm(alarmId = alarm.get.alarmId, name = alarm.get.messageTemplates.name, severity = alarm.get.severity),
                      icd = ZITInterrupt.FloAlarmNotificationIcd(icd.deviceId.get, timeZone = icd.timeZone.getOrElse(""), icd.systemMode.get, icd.id.getOrElse(""))
                    )
                  )
                )
              ).asJson.toString()
            case _ =>
              logger.info(s"regular  notification internal if ${alarm.get.internalId}")

              APNS(
                aps = aps(
                  alert = PushNotificationMessageGenerator(alarm.get, postAutoResolutionInfo).getOrElse(throw new Exception("notification sent to PushNotificationMessageGenerator was not able to generate a alert message")),
                  category = category(
                    FloAlarmNotification(

                      iCDAlarmIncidentRegistryId = iCDAlarmIncidentRegistry.id,
                      ts = incidentTime,
                      notification = FloAlarmNotificationAlarm(alarmId = alarm.get.alarmId, name = alarm.get.messageTemplates.name, severity = alarm.get.severity,
                        iCDAlarmIncidentRegistry.friendlyDescription),
                      icd = FloAlarmNotificationIcd(icd.deviceId.get, timeZone = icd.timeZone.getOrElse(""), icd.systemMode.get, icd.id.getOrElse("")),
                      version = 2
                    )
                  )
                )
              ).asJson.toString()
          }

        )
      )
    }
    catch {
      case e: Throwable => logger.error(s"during json codification  ${e.toString}")
        throw new Exception(e.toString)
    }
  }

  /**
    * based on notification-router environmnetal varaibles settings a medium can bypass graveyardshift, if a medium is
    * exempted from graveyard it will return true, otherwise if a medium is not exempted or not found in application
    * settings it will return false.
    **/
  def CanMediumSendDuringGraveYardShift(medium: Int): Boolean = medium match {
    case DeliveryMediums.PUSH_NOTIFICATION =>
      ApplicationSettings.flo.graveyardTime.sendAppNotifications
    case DeliveryMediums.EMAIL =>
      ApplicationSettings.flo.graveyardTime.sendEmails
    case DeliveryMediums.SMS =>
      ApplicationSettings.flo.graveyardTime.sendSMS
    case _ =>
      logger.warn(s"Medium's setting for graveyard were not found medium enum: $medium")
      false
  }


  /**
    * EMAIL
    **/

  def isTestIcd(deviceId: String): Boolean = {
    val testIcds = Set("8cc7aa027858", "8cc7aa027800", "8cc7aa027844", "8cc7aa0275ac", "8cc7aa02773c", "8cc7aa0277c0", "8cc7aa02784c", "8cc7aa0277ac", "8cc7aa0280ac", "8cc7aa0277bc", "8cc7aa027840", "8cc7aa02759c", "8cc7aa027868", "8cc7aa02765c", "8cc7aa02781c", "8cc7aa028108", "8cc7aa027870", "8cc7aa02774c")

    if (testIcds.contains(deviceId.trim)) {
      logger.info(s"this is a test icd $deviceId")
      true
    } else {
      logger.info(s"this is NOT a test icd $deviceId")
      false
    }

  }

  /**
    * List of alarms we don't want cs to get emails about.
    **/
  def isAlarmBlackListedForCSEmails(internalAlarmId: Int): Boolean = {
    true
  }

  /**
    * This function is a match function that will remove all the items in the Set which property is_deleted is equal to true, it will return None otherwise.
    */
  def AppDeviceInfoGetNonDeleted(appDeviceInfoSet: Option[Set[AppDeviceNotificationInfo]]): Option[Set[AppDeviceNotificationInfo]] = appDeviceInfoSet match {
    case Some(deviceInfoSet) => Some(deviceInfoSet.filter(i => !i.isDeleted.getOrElse(false)))
    case _ => None
  }


}
