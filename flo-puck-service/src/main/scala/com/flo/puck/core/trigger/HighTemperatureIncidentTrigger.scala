package com.flo.puck.core.trigger

import com.flo.puck.core.api.{Device, PuckIncidentSender, PuckTelemetryProperties}

import scala.concurrent.Future

final private class HighTemperatureIncidentTrigger(sendIncident: PuckIncidentSender) extends ActionTrigger {
  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): Future[Unit] = {

    val highTemperature = puckTelemetryProperties.alertTemperatureHighActive.contains(true)
    val temperatureAlertEnabled = device.fwProperties.exists(_.tempEnabled.contains(true))

    if (highTemperature && temperatureAlertEnabled)
      sendIncident(puckTelemetryProperties, device)
    else
      Future.unit
  }
}
