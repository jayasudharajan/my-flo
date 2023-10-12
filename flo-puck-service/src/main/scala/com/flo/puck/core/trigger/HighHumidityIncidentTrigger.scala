package com.flo.puck.core.trigger

import com.flo.puck.core.api.{Device, PuckIncidentSender, PuckTelemetryProperties}

import scala.concurrent.Future

final private class HighHumidityIncidentTrigger(sendIncident: PuckIncidentSender) extends ActionTrigger {
  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): Future[Unit] = {

    val highHumidity = puckTelemetryProperties.alertHumidityHighActive.contains(true)
    val humidityAlertEnabled = device.fwProperties.exists(_.humidityEnabled.contains(true))

    if (highHumidity && humidityAlertEnabled)
      sendIncident(puckTelemetryProperties, device)
    else
      Future.unit
  }
}
