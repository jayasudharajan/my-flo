package com.flo.puck.http.gateway

import com.flo.puck.core.api.{Device, FwProperties, Home => DeviceHome, Away => DeviceAway, Sleep => DeviceSleep, Unknown => DeviceUnknown}

case class CurrentTelemetry(
  gpm: Option[Double],
  psi: Option[Double],
  tempF: Option[Double]
)

case class DeviceTelemetry(
  current: Option[CurrentTelemetry]
)

sealed trait SystemModeType
case object Home extends SystemModeType
case object Away extends SystemModeType
case object Sleep extends SystemModeType
case object Unknown extends SystemModeType

case class SystemMode(
  lastKnown: Option[SystemModeType]
)

case class ThresholdValues(
  okMin: Option[Double],
  okMax: Option[Double],
  minValue: Option[Double],
  maxValue: Option[Double],
)

case class HardwareThresholds(
  tempEnabled: Option[Boolean],
  humidityEnabled: Option[Boolean],
  batteryEnabled: Option[Boolean],
  tempF: Option[ThresholdValues],
  tempC: Option[ThresholdValues],
  humidity: Option[ThresholdValues],
  battery: Option[ThresholdValues]
)

case class DeviceResponse(
  id: String,
  macAddress: String,
  deviceType: Option[String],
  deviceModel: Option[String],
  telemetry: Option[DeviceTelemetry],
  systemMode: Option[SystemMode],
  hardwareThresholds: Option[HardwareThresholds],
  valve: Option[Valve],
  isConnected: Boolean
) {

  def toModel(): Device = {
    Device(
      id,
      macAddress,
      deviceType,
      deviceModel,
      Some(FwProperties(
        telemetry.flatMap(_.current.flatMap(_.gpm)),
        telemetry.flatMap(_.current.flatMap(_.psi)),
        telemetry.flatMap(_.current.flatMap(_.tempF)),
        systemMode.map { sm =>
          sm.lastKnown match {
            case Some(Home)     => DeviceHome
            case Some(Away)     => DeviceAway
            case Some(Sleep)    => DeviceSleep
            case Some(Unknown)  => DeviceUnknown
            case None           => DeviceUnknown
          }
        },
        hardwareThresholds.flatMap(_.tempEnabled),
        hardwareThresholds.flatMap(_.humidityEnabled),
        hardwareThresholds.flatMap(_.batteryEnabled),
        hardwareThresholds.flatMap(_.tempF.flatMap(_.okMin)),
        hardwareThresholds.flatMap(_.tempF.flatMap(_.okMax)),
        hardwareThresholds.flatMap(_.humidity.flatMap(_.okMin)),
        hardwareThresholds.flatMap(_.humidity.flatMap(_.okMax)),
        hardwareThresholds.flatMap(_.battery.flatMap(_.okMin)),
      )),
      isConnected,
      valve.exists(_.lastKnown.contains(Open))
    )
  }
}
