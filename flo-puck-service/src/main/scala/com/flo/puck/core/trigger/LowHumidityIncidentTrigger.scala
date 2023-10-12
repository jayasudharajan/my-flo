package com.flo.puck.core.trigger

import com.flo.puck.core.api.{Device, PuckIncidentSender, PuckTelemetryProperties}

import scala.concurrent.Future

final private class LowHumidityIncidentTrigger(sendIncident: PuckIncidentSender) extends ActionTrigger {
  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): Future[Unit] = {

    val lowHumidity = puckTelemetryProperties.alertHumidityLowActive.contains(true)
    val humidityAlertEnabled = device.fwProperties.exists(_.humidityEnabled.contains(true))

    if (lowHumidity && humidityAlertEnabled)
      sendIncident(puckTelemetryProperties, device)
    else
      Future.unit
  }
}
