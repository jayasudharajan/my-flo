package MicroService.Email

import MicroService.{EnumsToStringService, TimeFormat, TimeService}
import com.flo.Models.{ICDAlarmNotificationDeliveryRules, Telemetry}

import scala.math.BigDecimal.RoundingMode

class AlarmMapService {
  lazy val timeService = new TimeService()
  lazy val enumService = new EnumsToStringService()

  def getAlarmName(alarm: Option[ICDAlarmNotificationDeliveryRules], deviceId: String): String = alarm match {
    case Some(alarmDeliveryRule) =>
      s"${alarmDeliveryRule.messageTemplates.friendlyName} ($deviceId)"
    case _ => "N/A"
  }

  def getAlarmInternalId(alarm: Option[ICDAlarmNotificationDeliveryRules]): String = alarm match {
    case Some(alarmDeliveryRule) =>
      alarmDeliveryRule.internalId.toString
    case _ => "N/A"
  }

  def getPressure(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      toString(telemetry.p)
    case _ => "N/A"
  }

  def getTemperature(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      toString(telemetry.t)
    case _ => "N/A"
  }

  def getTime(timeUtc: String, userTimeZone: String): String = {
    timeService.ConvertUTCToLocalTImeZone(timeUtc, userTimeZone, TimeFormat.MM_DD_HH_MM_A)
  }

  def getType(alarmDeliveryRule: Option[ICDAlarmNotificationDeliveryRules]): String = alarmDeliveryRule match {
    case Some(alarm) =>
      enumService.alarmSeverityToString(alarm.severity)
    case _ => ""


  }


  def getValveState(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if ((telemetry.sw1.isDefined && telemetry.sw1.nonEmpty) && (telemetry.sw2.isDefined && telemetry.sw2.nonEmpty))
        enumService.sw1Sw2ValuesToValveState(telemetry.sw1.get, telemetry.sw2.get)
      else ""
    case _ => ""
  }

  def getWaterFlowRate(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      toString(telemetry.wf)
    case _ => "N/A"
  }

  private def toString(value: Option[Double]): String = {
    value.map(x => x.toString).getOrElse("")
  }

}
