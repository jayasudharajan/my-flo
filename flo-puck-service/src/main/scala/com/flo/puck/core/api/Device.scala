package com.flo.puck.core.api

case class FwProperties(
  gpm: Option[Double],
  psi: Option[Double],
  tempF: Option[Double],
  systemMode: Option[SystemMode],
  tempEnabled: Option[Boolean],
  humidityEnabled: Option[Boolean],
  batteryEnabled: Option[Boolean],
  limitTemperatureMin: Option[Double],
  limitTemperatureMax: Option[Double],
  limitHumidityMin: Option[Double],
  limitHumidityMax: Option[Double],
  limitBatteryMin: Option[Double]
)

case class Device(
  id: DeviceId,
  macAddress: MacAddress,
  deviceType: Option[String],
  deviceModel: Option[String],
  fwProperties: Option[FwProperties],
  isConnected: Boolean,
  isValveOpen: Boolean
)