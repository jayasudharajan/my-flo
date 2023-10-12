package MicroService.Email

import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.Telemetry
import argonaut.Argonaut._
import scala.math.BigDecimal.RoundingMode

class DataMapService {

  def getTemperatureMinimum(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.tmin.isDefined && telemetry.tmin.nonEmpty)
        toString(telemetry.tmin)
      else ""
    case _ => ""
  }

  def getTemperatureMaximum(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.tmax.isDefined && telemetry.tmax.nonEmpty)
        toString(telemetry.tmax)
      else ""
    case _ => ""
  }

  def getPressureMax(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.pmax.isDefined && telemetry.pmax.nonEmpty)
        toString(telemetry.pmax)
      else ""
    case _ => ""
  }

  def getPressureMinimum(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.pmin.isDefined && telemetry.pmin.nonEmpty)
        toString(telemetry.pmin)
      else ""
    case _ => ""
  }

  def getFlowTotalizationLimit(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.ftl.isDefined && telemetry.ftl.nonEmpty)
        toString(telemetry.ftl)
      else ""
    case _ => ""
  }

  def getFlowDurationLimit(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.fdl.isDefined && telemetry.fdl.nonEmpty)
        telemetry.fdl.getOrElse("") toString
      else ""
    case _ => ""
  }

  def getPerEventFlowLimit(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.pefl.isDefined && telemetry.pefl.nonEmpty)
        toString(telemetry.pefl)
      else ""
    case _ => ""
  }

  def getMaximumAllowableFlowRate(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.mafr.isDefined && telemetry.mafr.nonEmpty)
        toString(telemetry.mafr)
      else ""
    case _ => ""
  }

  def getEventFlow(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.pef.isDefined && telemetry.pef.nonEmpty)
        toString(telemetry.pef)
      else ""
    case _ => ""
  }

  def getEventFlowDuration(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.fd.isDefined && telemetry.fd.nonEmpty)
        telemetry.fd.getOrElse("Unknown") toString
      else "Unknown"
    case _ => "Unknown"
  }

  def getFlowTotalization(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      if (telemetry.ft.isDefined && telemetry.ft.nonEmpty)
        toString(telemetry.ft)
      else ""
    case _ => ""
  }

  def getSnapshotJson(snapshot: Option[ICDAlarmIncidentDataSnapshot]): String = snapshot match {
    case Some(snap) =>
      snap.asJson.nospaces
    case _ => ""
  }

  def getTelemetry(telemetryData: Option[Telemetry]): String = telemetryData match {
    case Some(telemetry) =>
      telemetry.asJson.nospaces
    case _ => ""
  }

  private def toString(value: Option[Double]): String = {
    value.map(x => x.toString).getOrElse("")
  }

}
