package com.flo.puck.core.trigger

import com.flo.puck.core.api.{Device, PuckIncidentSender, PuckTelemetryProperties}

import scala.concurrent.Future

final private class LowTemperatureIncidentTrigger(sendIncident: PuckIncidentSender) extends ActionTrigger {
  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): Future[Unit] = {

    val lowTemperature = puckTelemetryProperties.alertTemperatureLowActive.contains(true)
    val temperatureAlertEnabled = device.fwProperties.exists(_.tempEnabled.contains(true))

    if (lowTemperature && temperatureAlertEnabled)
      sendIncident(puckTelemetryProperties, device)
    else
      Future.unit
  }
}
