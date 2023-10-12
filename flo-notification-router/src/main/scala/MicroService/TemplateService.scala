package MicroService

import java.text.DecimalFormat

import Utils.WaterLostByLeak
import com.flo.Enums.Apps.ClientApps
import com.flo.Enums.Locale.SystemsIds
import com.flo.Enums.Templates.TemplateKeywords
import com.flo.Models.ICDAlarmNotificationDeliveryRules
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.{ICDAlarmIncidentDataSnapshot, PostAutoResolutionInfo, UserActivityEvent}
import com.flo.Models.Locale.MeasurementUnitSystem

/**
  * Created by Francisco on 6/26/2017.
  */
class TemplateService(unitSystem: MeasurementUnitSystem) {
  private lazy val timeService = new TimeService()
  private lazy val enumService = new EnumsToStringService()


  def deconstructSMSText(iCDAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules, postAutoResolutionInfo: Option[PostAutoResolutionInfo] = None): String = {

    var sms = iCDAlarmNotificationDeliveryRules.messageTemplates.smsText replaceAllLiterally(TemplateKeywords.ALERT_FRIENDLY_NAME, iCDAlarmNotificationDeliveryRules.messageTemplates.friendlyName)
    sms = sms.replaceAllLiterally(TemplateKeywords.FLO_APP_LINK, "floapp://home")
    if (postAutoResolutionInfo.isDefined && postAutoResolutionInfo.nonEmpty) {
      sms = deconstructAlarmNameForAutoResolution(sms, postAutoResolutionInfo.get.alarmFriendlyName)
    }
    sms

  }

  def deconstructPushNotificationTitle(iCDAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules, severity: String): String = {

    val alarmFriendlyName = iCDAlarmNotificationDeliveryRules.messageTemplates.friendlyName
    var title = iCDAlarmNotificationDeliveryRules.messageTemplates.pushNotificationMessage.title

    title = title replaceAllLiterally(TemplateKeywords.ALERT_FRIENDLY_NAME, alarmFriendlyName)
    title = title replaceAllLiterally(TemplateKeywords.ALERT_SEVERITY, severity)
    title

  }

  /**
    * This method will replaces all the template place holder for the friendly description.
    * 1) convert incident time from UTC to icd's  location local time
    * 2) replace telemetry template with snapshot values
    **/
  def deconstructIncidentRegistryFriendlyDescription(friendlyDescription: String, dtz: String, incidentTimeUTC: String, timeDateFormat: String, snapshot: ICDAlarmIncidentDataSnapshot, postAutoResolutionInfo: Option[PostAutoResolutionInfo] = None, userActivityEvent: Option[UserActivityEvent] = None, userName: String = "N/A", alarmId: Option[Int] = None, unitSystem: MeasurementUnitSystem): String = {

    val incidentTimeInLocalTime = timeService.ConvertUTCToLocalTImeZone(incidentTimeUTC, dtz, timeDateFormat)
    var deconstructedText = friendlyDescription
    if (postAutoResolutionInfo.isDefined && postAutoResolutionInfo.nonEmpty && alarmId.getOrElse(0) == 45) {
      deconstructedText = populateAutoResolutionAlarmDescription(deconstructedText, postAutoResolutionInfo.get, dtz, timeDateFormat)
    }
    else if (userActivityEvent.isDefined && userActivityEvent.nonEmpty) {
      deconstructedText = populateIncidentTime(deconstructedText, incidentTimeInLocalTime)
      deconstructedText = deconstructAppName(deconstructedText, userActivityEvent.get.appType)
      deconstructedText = deconstructedText.replaceAllLiterally(TemplateKeywords.USER_SMALL_NAME, userName)
      deconstructedText = deconstructNewSystemMode(snapshot.systemMode, deconstructedText)
    }
    else {
      deconstructedText = populateIncidentTime(deconstructedText, incidentTimeInLocalTime)
      deconstructedText = deconstructSnapshotParameters(
        parametersToDeconstruct = Set(
          TemplateKeywords.REAL_PRESSURE,
          TemplateKeywords.REAL_FLOW_RATE,
          TemplateKeywords.REAL_FLOW_EVENT,
          TemplateKeywords.REAL_FLOW_DURATION,
          TemplateKeywords.MIN_PRESSURE,
          TemplateKeywords.MAX_TEMPERATURE,
          TemplateKeywords.MAX_PRESSURE,
          TemplateKeywords.FLOW_RATE,
          TemplateKeywords.FLOW_EVENT,
          TemplateKeywords.FLOW_DURATION,
          TemplateKeywords.PRESSURE_UNITS,
          TemplateKeywords.PRESSURE_UNITS_ABBREV,
          TemplateKeywords.VOLUME_UNITS,
          TemplateKeywords.VOLUME_UNITS_ABBREV,
          TemplateKeywords.TEMPERATURE_UNITS,
          TemplateKeywords.TEMPERATURE_UNITS_ABBREV
        ),
        snapshot,
        deconstructedText,
        unitSystem
      )

    }

    WaterLostByLeak.getByAlertId(alarmId.getOrElse(0), unitSystem) match {
      case Some(waterLostVolume) => {
        deconstructedText
          .replaceAllLiterally(TemplateKeywords.LOST_WATER_VOLUME, waterLostVolume.toString)
          .replaceAllLiterally(TemplateKeywords.LOST_WATER_UNIT, unitSystem.units.volume.abbrev)
      }
      case None => deconstructedText
    }
  }

  private def deconstructNewSystemMode(systemMode: Option[Int], templateText: String): String = systemMode match {
    case Some(sm) =>
      templateText.replaceAllLiterally(TemplateKeywords.NEW_SYSTEM_MODE, enumService.systemModeToString(sm))
    case _ =>
      "unknown"
  }

  private def deconstructAppName(templateText: String, appType: Option[Int]): String = appType match {
    case None =>
      "N/A"
    case Some(ClientApps.ADMIN_SITE) =>

      templateText.replaceAllLiterally(TemplateKeywords.APP_TYPE, "Admin Site")

    case Some(ClientApps.ALEXA_VOICE_COMMAND) =>

      templateText.replaceAllLiterally(TemplateKeywords.APP_TYPE, "Alexa")

    case Some(ClientApps.ANDROID_PHONE) =>

      templateText.replaceAllLiterally(TemplateKeywords.APP_TYPE, "Android phone app")

    case Some(ClientApps.ANDROID_TABLET) =>

      templateText.replaceAllLiterally(TemplateKeywords.APP_TYPE, "Android tablet app")

    case Some(ClientApps.GOOGLE_NEST_VOICE) =>

      templateText.replaceAllLiterally(TemplateKeywords.APP_TYPE, "Google Nest")

    case Some(ClientApps.I_PAD) =>

      templateText.replaceAllLiterally(TemplateKeywords.APP_TYPE, "iPad app")

    case Some(ClientApps.I_PHONE) =>

      templateText.replaceAllLiterally(TemplateKeywords.APP_TYPE, "iPhone app")

    case Some(ClientApps.USER_PORTAL) =>

      templateText.replaceAllLiterally(TemplateKeywords.APP_TYPE, "Flo user portal")

    case _ =>

      "N/A"

  }

  private def populateAutoResolutionAlarmDescription(templateText: String, postAutoResolutionInfo: PostAutoResolutionInfo, dtz: String, tFormat: String): String = {
    var deconstructedText = templateText

    deconstructedText = populateIncidentTimeForAutoResolution(deconstructedText, postAutoResolutionInfo.previousIncidentTimeUTC, dtz: String, tFormat: String)

    deconstructedText = deconstructAlarmNameForAutoResolution(deconstructedText, postAutoResolutionInfo.alarmFriendlyName)

    deconstructedText
  }

  private def deconstructAlarmNameForAutoResolution(templateText: String, alarmName: String) = templateText.replaceAllLiterally(TemplateKeywords.PREVIOUS_ALERT_FRIENDLY_NAME, alarmName)

  private def populateIncidentTimeForAutoResolution(templateText: String, incidentTime: String, dtz: String, tFormat: String) = templateText.replaceAllLiterally(TemplateKeywords.PREVIOUS_INCIDENT_DATE_TIME, timeService.ConvertUTCToLocalTImeZone(incidentTime, dtz, tFormat))

  private def populateIncidentTime(templateText: String, incidentTime: String) = templateText.replaceAllLiterally(TemplateKeywords.INCIDENT_DATE_TIME, incidentTime)

  private def deconstructSnapshotParameters(parametersToDeconstruct: Set[String], snapshotRaw: ICDAlarmIncidentDataSnapshot, templateText: String, unitSystem: MeasurementUnitSystem): String = {
    val snapshot = if (unitSystem.id == SystemsIds.IMPERIAL_USA) snapshotRaw else snapshotRaw.unitSystemConversion(unitSystem)


    var deconstructedText = templateText
    parametersToDeconstruct.foreach {
      case TemplateKeywords.FLOW_RATE =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.FLOW_RATE, roundDouble(snapshot.flowRateLimit.getOrElse(0.0)).toString)
      case TemplateKeywords.MAX_PRESSURE =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.MAX_PRESSURE, roundDouble(snapshot.pressureMaximus.getOrElse(0.0)).toString)
      case TemplateKeywords.MAX_TEMPERATURE =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.MAX_TEMPERATURE, roundDouble(snapshot.temperatureMaximum.getOrElse(0.0)).toString)
      case TemplateKeywords.MIN_PRESSURE =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.MIN_PRESSURE, roundDouble(snapshot.pressureMinimum.getOrElse(0.0)).toString)
      case TemplateKeywords.REAL_FLOW_DURATION =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.REAL_FLOW_DURATION, snapshot.eventFlowDurationInSeconds.getOrElse(0).toString)
      case TemplateKeywords.REAL_FLOW_EVENT =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.REAL_FLOW_EVENT, roundDouble(snapshot.eventFlow.getOrElse(0.0)).toString)
      case TemplateKeywords.REAL_FLOW_RATE =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.REAL_FLOW_RATE, roundDouble(snapshot.flowRate.getOrElse(0.0)).toString)
      case TemplateKeywords.REAL_PRESSURE =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.REAL_PRESSURE, roundDouble(snapshot.pressure.getOrElse(0.0)).toString)
      case TemplateKeywords.FLOW_EVENT =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.FLOW_EVENT, roundDouble(snapshot.eventFlowLimit.getOrElse(0.0)).toString)
      case TemplateKeywords.FLOW_DURATION =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.FLOW_DURATION, timeService.convertSecondsToMinutesAsString(snapshot.eventFlowDurationLimitInSeconds))
      case TemplateKeywords.TEMPERATURE_UNITS_ABBREV =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.TEMPERATURE_UNITS_ABBREV, unitSystem.units.temperature.abbrev)
      case TemplateKeywords.TEMPERATURE_UNITS =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.TEMPERATURE_UNITS, unitSystem.units.temperature.name)
      case TemplateKeywords.VOLUME_UNITS_ABBREV =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.VOLUME_UNITS_ABBREV, unitSystem.units.volume.abbrev)
      case TemplateKeywords.VOLUME_UNITS =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.VOLUME_UNITS, unitSystem.units.volume.name.toLowerCase)
      case TemplateKeywords.PRESSURE_UNITS_ABBREV =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.PRESSURE_UNITS_ABBREV, unitSystem.units.pressure.abbrev)
      case TemplateKeywords.PRESSURE_UNITS =>
        deconstructedText = deconstructedText replaceAllLiterally(TemplateKeywords.PRESSURE_UNITS, unitSystem.units.pressure.name.toLowerCase)
    }
    deconstructedText
  }

  def roundDouble(v: Double): Double = if (v != 0) Math.round(v * 100.0) / 100.0 else v


  def deconstructShortAddress(templateText: String, shortAddress: String): String = templateText.replaceAllLiterally(TemplateKeywords.SHORT_ADDRESS, shortAddress)


  def deconstructAlarmName(templateText: String, templateKeyword: String, alarmName: String): String = templateText.replaceAllLiterally(templateKeyword, alarmName)

  /** ############ Template for floice ####################### **/

  //machine FOR FAST WATER FLOW (1010, 1011)
  //FOR EXTENDED WATER USE (1013, 1014)
  //FOR HIGH WATER USAGE (1016, 1017)
  def getVoiceMachineMessage(templateText: String, userTz: String, incidentTime: String, dateFormat: String, snapshot: ICDAlarmIncidentDataSnapshot, alarmName: String, shortAddress: String, unitSystem: MeasurementUnitSystem): String = {
    val localIncidentTime = timeService.ConvertUTCToLocalTImeZone(incidentTime, userTz, dateFormat)
    var txt = templateText
    txt = deconstructAlarmName(txt, TemplateKeywords.ALERT_FRIENDLY_NAME, alarmName)
    txt = deconstructShortAddress(txt, shortAddress)
    txt = populateIncidentTime(txt, localIncidentTime)
    txt = deconstructSnapshotParameters(parametersToDeconstruct = Set[String](TemplateKeywords.FLOW_RATE, TemplateKeywords.FLOW_DURATION, TemplateKeywords.FLOW_EVENT, TemplateKeywords.VOLUME_UNITS, TemplateKeywords.VOLUME_UNITS_ABBREV), snapshot, txt, unitSystem)
    txt
  }
}



