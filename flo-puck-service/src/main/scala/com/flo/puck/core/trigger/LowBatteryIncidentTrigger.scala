package com.flo.puck.core.trigger
import com.flo.puck.core.api.{Device, PuckIncidentSender, PuckTelemetryProperties}

import scala.concurrent.Future

final private class LowBatteryIncidentTrigger(sendIncident: PuckIncidentSender) extends ActionTrigger {
  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): Future[Unit] = {

    val lowBattery = puckTelemetryProperties.alertBatteryActive.contains(true)
    val batteryAlertEnabled = device.fwProperties.exists(_.batteryEnabled.contains(true))

    if (lowBattery && batteryAlertEnabled)
      sendIncident(puckTelemetryProperties, device)
    else
      Future.unit
  }
}
