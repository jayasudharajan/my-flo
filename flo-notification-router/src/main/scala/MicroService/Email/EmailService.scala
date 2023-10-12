package MicroService.Email

import MicroService.{TimeFormat, TimeService}
import com.flo.Enums.Apps.FloAppsNames
import com.flo.Enums.Email.SendWithUs._
import com.flo.Models.KafkaMessages.{EmailFeatherMessage, EmailRecipient, EmailSender, SendWithUsData}
import com.flo.Models.{ICD, ICDAlarmNotificationDeliveryRules, Location, Telemetry}
import com.flo.Models.Users.UserContactInformation
import org.joda.time.{DateTime, DateTimeZone}


class EmailService {
	lazy private val userMapService = new UserMapService()
	lazy private val alarmMapService = new AlarmMapService()
	lazy private val dataMapService = new DataMapService()
	lazy private val iCDMapService = new ICDMapService()
	lazy private val timeService = new TimeService()
	lazy private val csEmail = "cs@meetflo.com"
	lazy private val sendDeskEmail = "support@meetflo.zendesk.com"


	def CS5000Email(contactInfo: Option[UserContactInformation], location: Option[Location], telemetry: Option[Telemetry], alarm: Option[ICDAlarmNotificationDeliveryRules], userTimeZone: String, incidentTimeInUTC: String, systemMode: Int, icd: Option[ICD]): EmailFeatherMessage = {
		val userM = getUserMap(contactInfo, location)
		val alarmM = getAlarmMap(telemetry, alarm, userTimeZone, incidentTimeInUTC, systemMode, icd.map(x => x.deviceId.getOrElse("N/A")).getOrElse("N/A"))
		val dataM = getDataMap(telemetry)
		val icdM = getICDMap(icd, systemMode)
		val timeM = getTimeMap(incidentTimeInUTC, userTimeZone)
		EmailFeatherMessage(
			id = java.util.UUID.randomUUID().toString,
			emailMetaData = Some(Map[String, String](
				"alarm_id" -> alarm.get.alarmId.toString,
				"user_id" -> contactInfo.get.userId.get
			)),
			clientAppName = FloAppsNames.NOTIFICATION_ROUTER,
			sender = Some(EmailSender(
				name = Some("notification router"),
				emailAddress = csEmail,
				replyToAddress = Some(csEmail)
			)),
			recipients = Set[EmailRecipient](EmailRecipient(
				name = Some("Flo-Support"),
				emailAddress = sendDeskEmail,
				sendWithUsData = SendWithUsData(
					templateId = alarm.get.messageTemplates.emailProperties.templateId,
					espAccount = None,
					emailTemplateData = Map[String, Map[String, String]](
						userM._1 -> userM._2,
						alarmM._1 -> alarmM._2,
						dataM._1 -> dataM._2,
						icdM._1 -> icdM._2,
						timeM._1 -> timeM._2
					)
				)
			)),
			webHook = None,
			timeStamp = DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString
		)
	}

	def getUserMap(contactInfo: Option[UserContactInformation], location: Option[Location]): (String, Map[String, String]) = {
		val userMapContent = Map[String, String](
			UserMapKeys.FIRST_NAME -> userMapService.getFirstName(contactInfo),
			UserMapKeys.LAST_NAME -> userMapService.getLastName(contactInfo),
			UserMapKeys.ADDRESS -> userMapService.getAddress(location),
			UserMapKeys.ADDRESS_2 -> userMapService.getAddress2(location),
			UserMapKeys.CITY -> userMapService.getCity(location),
			UserMapKeys.FULL_ADDRESS -> userMapService.getFullAddress(location),
			UserMapKeys.STATE -> userMapService.getState(location),
			UserMapKeys.ZIP -> userMapService.getZip(location)
		)
		(MapNames.USER, userMapContent)
	}

	def getAlarmMap(telemetry: Option[Telemetry], alarm: Option[ICDAlarmNotificationDeliveryRules], userTimeZone: String, incidentTimeInUTC: String, systemMode: Int, deviceId: String): (String, Map[String, String]) = {
		val alarmMap = Map[String, String](
			AlarmMapKeys.NAME -> alarmMapService.getAlarmName(alarm, deviceId),
			AlarmMapKeys.ID -> alarmMapService.getAlarmInternalId(alarm),
			AlarmMapKeys.PRESSURE -> alarmMapService.getPressure(telemetry),
			AlarmMapKeys.SYSTEM_MODE -> systemMode.toString,
			AlarmMapKeys.TEMPERATURE -> alarmMapService.getTemperature(telemetry),
			AlarmMapKeys.TIME -> alarmMapService.getTime(incidentTimeInUTC, userTimeZone),
			AlarmMapKeys.TYPE -> alarmMapService.getType(alarm),
			AlarmMapKeys.VALVE_STATE -> alarmMapService.getValveState(telemetry),
			AlarmMapKeys.WATER_FLOW_RATE -> alarmMapService.getWaterFlowRate(telemetry)
		)
		(MapNames.ALARM, alarmMap)
	}

	def getDataMap(telemetry: Option[Telemetry]): (String, Map[String, String]) = {
		val dataMap = Map[String, String](
			DataMapKeys.TEMPERATURE_MINIMUM -> dataMapService.getTemperatureMinimum(telemetry),
			DataMapKeys.TEMPERATURE_MAXIMUM -> dataMapService.getTemperatureMaximum(telemetry),
			DataMapKeys.PRESSURE_MAXIMUM -> dataMapService.getPressureMax(telemetry),
			DataMapKeys.PRESSURE_MINIMUM -> dataMapService.getPressureMinimum(telemetry),
			DataMapKeys.FLOW_TOTALIZATION_LIMIT -> dataMapService.getFlowTotalizationLimit(telemetry),
			DataMapKeys.FLOW_DURATION_LIMIT -> dataMapService.getFlowDurationLimit(telemetry),
			DataMapKeys.PER_EVENT_FLOW_LIMIT -> dataMapService.getPerEventFlowLimit(telemetry),
			DataMapKeys.MAXIMUM_ALLOWABLE_FLOW_RATE -> dataMapService.getMaximumAllowableFlowRate(telemetry),
			DataMapKeys.EVENT_FLOW_DURATION -> dataMapService.getEventFlowDuration(telemetry),
			DataMapKeys.FLOW_TOTALIZATION -> dataMapService.getFlowTotalization(telemetry),
			DataMapKeys.TELEMETRY -> dataMapService.getTelemetry(telemetry)
		)
		(MapNames.DATA, dataMap)
	}

	def getICDMap(icd: Option[ICD], sm: Int): (String, Map[String, String]) = {
		val icdMap = Map[String, String](
			ICDMapKeys.DEVICE_ID -> iCDMapService.getDeviceId(icd),
			ICDMapKeys.ID -> iCDMapService.getICDId(icd),
			ICDMapKeys.SYSTEM_MODE -> iCDMapService.getSystemMode(sm)
		)
		(MapNames.ICD, icdMap)
	}

	def getTimeMap(incidentTimeUTC: String, userTZ: String): (String, Map[String, String]) = {
		val timeMap = Map[String, String](
			TimeMapKeys.INCIDENT_TIME_LOS_ANGELES -> timeService.convertUTCtoLosAngeles(incidentTimeUTC),
			TimeMapKeys.INCIDENT_TIME_USERS_LOCATION_TIME_ZONE -> timeService.ConvertUTCToLocalTImeZone(incidentTimeUTC, userTZ, TimeFormat.MM_DD_HH_MM_A),
			TimeMapKeys.INCIDENT_TIME_UTC -> incidentTimeUTC
		)
		(MapNames.TIME, timeMap)
	}

}
