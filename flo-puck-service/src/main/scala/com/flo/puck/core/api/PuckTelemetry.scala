package com.flo.puck.core.api

case class PuckTelemetryProperties(alertBatteryActive: Option[Boolean],
                                   alertHumidityLowActive: Option[Boolean],
                                   alertHumidityHighActive: Option[Boolean],
                                   alertTemperatureLowActive: Option[Boolean],
                                   alertTemperatureHighActive: Option[Boolean],
                                   alertWaterActive: Option[Boolean],
                                   deviceId: Option[String],
                                   fwVersion: Option[Int],
                                   macAddress: String,
                                   telemetryBatteryPercent: Option[Int],
                                   telemetryBatteryVoltage: Option[Double],
                                   telemetryHumidity: Option[Double],
                                   telemetryTemperature: Option[Double],
                                   limitBatteryMin: Option[Int],
                                   limitTemperatureMin: Option[Double],
                                   limitTemperatureMax: Option[Double],
                                   limitHumidityMin: Option[Double],
                                   limitHumidityMax: Option[Double],
                                   alertState: Option[AlertState]
                                  )

case class PuckTelemetry(properties: PuckTelemetryProperties, raw: Json)