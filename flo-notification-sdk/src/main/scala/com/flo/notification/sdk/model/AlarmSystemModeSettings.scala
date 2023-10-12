package com.flo.notification.sdk.model

case class AlarmSystemModeSettings(
  id: Int,
  alarmId: Int,
  systemMode: Int,
  accountType: String,
  smsEnabled: Option[Boolean],
  emailEnabled: Option[Boolean],
  pushEnabled: Option[Boolean],
  callEnabled: Option[Boolean]
)
