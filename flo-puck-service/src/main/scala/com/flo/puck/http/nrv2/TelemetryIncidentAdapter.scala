package com.flo.puck.http.nrv2

import com.flo.puck.core.api.{Device, PuckTelemetryProperties}

final private[http] class TelemetryIncidentAdapter(alarmId: AlarmId, generateUuid: => String) extends ((PuckTelemetryProperties, Device) => AlarmIncident) {
  private val homeMode = 2

  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): AlarmIncident = {
    AlarmIncident(
      macAddress            = puckTelemetryProperties.macAddress,
      alarmId               = alarmId,
      telemetry             = TelemetrySnapshot(
        sm                = homeMode,
        tz                = None,
        lt                = None,
        f                 = None,
        fr                = None,
        t                 = puckTelemetryProperties.telemetryTemperature,
        p                 = None,
        sw1               = None,
        sw2               = None,
        ef                = None,
        efd               = None,
        ft                = None,
        pmin              = None,
        pmax              = None,
        tmin              = device.fwProperties.flatMap(_.limitTemperatureMin),
        tmax              = device.fwProperties.flatMap(_.limitTemperatureMax),
        frl               = None,
        efl               = None,
        efdl              = None,
        ftl               = None,
        v                 = None,
        humidity          = puckTelemetryProperties.telemetryHumidity,
        limitHumidityMin  = device.fwProperties.flatMap(_.limitHumidityMin),
        limitHumidityMax  = device.fwProperties.flatMap(_.limitHumidityMax),
        batteryPercent    = puckTelemetryProperties.telemetryBatteryPercent,
        limitBatteryMin   = device.fwProperties.flatMap(_.limitBatteryMin.map(roundUp(_)))
      ),
    )
  }

  private def roundUp(d: Double) = math.ceil(d).toInt
}
