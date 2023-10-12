package MicroService

import java.net.URLEncoder
import java.util.UUID

import Utils.ApplicationSettings
import com.flo.Enums.Apps.FloAppsNames
import com.flo.Enums.Notifications.Floice.CallCategory
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.KafkaMessages.Floice.{DefaultCall, MetaData, RequestData}
import com.flo.Models.Location
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.UserContactInformation
import org.joda.time.DateTime
import argonaut.Argonaut._
import com.flo.Models.Locale.MeasurementUnitSystem

class FloiceService(unitSystem: MeasurementUnitSystem) {
  lazy private val encodeFormat: String = "UTF8"
  lazy private val locationService = new LocationService()
  lazy private val templateService = new TemplateService(unitSystem)
  lazy private val apiUrl = ApplicationSettings.flo.api.url.getOrElse(throw new NoSuchElementException("FLo API URL not found in configuration nor in env vars"))
  lazy private val gatherEnpoint = apiUrl + "/voice/gather/user-action"
  lazy private val awayModeTwimlScript = "https://handler.twilio.com/twiml/EH4009305c824d740f36d9d59aa742d2ba"
  lazy private val homeModeTwimlScript = "https://handler.twilio.com/twiml/EH4009305c824d740f36d9d59aa742d2ba"

  def createId(): String = UUID.randomUUID().toString

  def getRequestInfoForDefaultCall(): RequestData = {
    RequestData(
      time = DateTime.now().toDateTimeISO.toString(),
      appName = FloAppsNames.NOTIFICATION_ROUTER,
      category = CallCategory.CRITICAL_ALERT,
      version = 1
    )
  }

  def defaultCallJsonGenerator(incident: ICDAlarmIncidentRegistry, userContactInformation: UserContactInformation, location: Option[Location], alarmInternalId: Int, alarmFriendlyName: String, snapshot: ICDAlarmIncidentDataSnapshot, isUserTenant: Boolean): String = {
    DefaultCall(
      from = None,
      to = userContactInformation.phoneMobile.get,
      scriptUrl = scriptURLGenerator(userContactInformation.userId.get, incident, alarmInternalId, snapshot, alarmFriendlyName, location, isUserTenant),
      callMetaData = callMetaDataGenerator(incident, userContactInformation.userId, alarmInternalId)
    ).asJson.nospaces
  }

  private def callMetaDataGenerator(incidentRegistry: ICDAlarmIncidentRegistry, userId: Option[String], internalAlarmId: Int): Option[MetaData] = {
    Some(
      MetaData(
        deviceId = incidentRegistry.icdData.deviceId,
        icdId = incidentRegistry.icdData.id,
        alarmId = Some(incidentRegistry.alarmId),
        userId = userId,
        systemMode = incidentRegistry.icdData.systemMode,
        internalAlarmId = Some(internalAlarmId),
        incidentRegistryId = Some(incidentRegistry.id)
      )
    )
  }

  private def scriptURLGenerator(userId: String, incident: ICDAlarmIncidentRegistry, internalId: Int, snapshot: ICDAlarmIncidentDataSnapshot, alarmFriendlyName: String, location: Option[Location], isUserTenant: Boolean): String = {
    val machineMessage = templateService.getVoiceMachineMessage(getMachineMessageByInternalId(internalId), locationService.getTimezone(location), incident.incidentTime, TimeFormat.MM_DD_HH_MM_A, snapshot, alarmFriendlyName, locationService.getShortAddress(location), unitSystem)

    val gatherUrl = s"$gatherEnpoint/$userId/${incident.id}"
    val queryParams = s"?friendly_description=${encodeString(machineMessage)}&gather_action_url=${encodeString(gatherUrl)}"

    s"${getCallScriptByInternalId(internalId, isUserTenant)}$queryParams"
  }

  private def getCallScriptByInternalId(id: Int, isUserTenant: Boolean): String = id match {
    //Home Mode
    case 1010 | 1013 | 1016 =>
      if (isUserTenant) "https://handler.twilio.com/twiml/EH8ab422896b7211b9913e6e0645aa02c5"
      else homeModeTwimlScript
    //Away mode
    case 1011 | 1014 | 1017 | 1200 =>
      if (isUserTenant) "https://handler.twilio.com/twiml/EHe81e7b058fca219741afa484ae206031"
      else "https://handler.twilio.com/twiml/EHe7da25f17b54a7fe5fe97a511f95061e"
  }


  private def encodeShortAddress(location: Option[Location]): String = encodeString(locationService.getShortAddress(location))

  private def encodeString(str: String): String = URLEncoder.encode(str, encodeFormat)

  private def getMachineMessageByInternalId(internalId: Int): String = internalId match {
    case 1010 | 1011 => "Your Flo by Moen Device detected a ##ALERT_FRIENDLY_NAME## issue at ##SHORT_ADDRESS##. On ##INCIDENT_DATE_TIME##, your water flow exceeded ##FLOW_RATE## ##VOLUME_UNITS##s per minute, which is higher than your normal usage."
    case 1013 | 1014 => "Your Flo by Moen Device detected a ##ALERT_FRIENDLY_NAME## issue at ##SHORT_ADDRESS##. On ##INCIDENT_DATE_TIME##, your water was running over ##FLOW_DURATION## minutes, which is higher than your normal usage."
    case 1016 | 1017 => "Your Flo by Moen Device detected a ##ALERT_FRIENDLY_NAME## issue at ##SHORT_ADDRESS##. On ##INCIDENT_DATE_TIME##, your water flow exceeded ##FLOW_EVENT## ##VOLUME_UNITS##s in one sitting, which is higher than your normal usage."
    case 1200 => "Your Flo by Moen Device detected a ##ALERT_FRIENDLY_NAME## issue at ##SHORT_ADDRESS##. On ##INCIDENT_DATE_TIME##, Flo detected non-allowed water usage while in Away Mode."
  }

  private def getTwimlByInternalId(internalId: Int): String = internalId match {
    case 1010 | 1013 | 1016 => homeModeTwimlScript
    case 1011 | 1014 | 1017 | 1200 => awayModeTwimlScript
  }

}
