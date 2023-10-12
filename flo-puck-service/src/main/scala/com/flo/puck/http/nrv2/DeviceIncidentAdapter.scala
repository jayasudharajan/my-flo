package com.flo.puck.http.nrv2

import com.flo.puck.core.api.{Away, Device, FwProperties, Home, Sleep, SystemMode, Unknown}

final private[http] class DeviceIncidentAdapter(alarmId: AlarmId, generateUuid: => String) extends (Device => AlarmIncident) {

  override def apply(device: Device): AlarmIncident = {
    device match {
      case Device(_, macAddress, _, _, Some(FwProperties(gpm, psi, temp, systemMode, _, _, _, _, _, _, _, _)), _, isValveOpen) =>
        AlarmIncident(
          macAddress            = macAddress,
          alarmId               = alarmId,
          telemetry             = TelemetrySnapshot(
            sm                = systemModeToInt(systemMode),
            tz                = None,
            lt                = None,
            f                 = None,
            fr                = gpm,
            t                 = temp,
            p                 = psi,
            sw1               = None,
            sw2               = None,
            ef                = None,
            efd               = None,
            ft                = None,
            pmin              = None,
            pmax              = None,
            tmin              = None,
            tmax              = None,
            frl               = None,
            efl               = None,
            efdl              = None,
            ftl               = None,
            v                 = if (isValveOpen) Some(1) else Some(0),
            humidity          = None,
            limitHumidityMin  = None,
            limitHumidityMax  = None,
            batteryPercent    = None,
            limitBatteryMin   = None,
          ),
        )
      case _ => throw new RuntimeException("Could not convert Device into an Alarm Incident. Missing data.")
    }
  }

  private def systemModeToInt(systemMode: Option[SystemMode]): Int = systemMode match {
    case Some(Home)     => 2
    case Some(Away)     => 3
    case Some(Sleep)    => 5
    case Some(Unknown)  => 0
    case _              => 0
  }
}
