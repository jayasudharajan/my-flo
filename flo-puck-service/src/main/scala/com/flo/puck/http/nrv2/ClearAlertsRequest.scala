package com.flo.puck.http.nrv2

case class DeviceInfo(
  id: String,
  macAddress: String
)

case class ClearAlertsRequest(
  alarmIds: List[Int],
  devices: List[DeviceInfo],
  snoozeSeconds: Int
)
