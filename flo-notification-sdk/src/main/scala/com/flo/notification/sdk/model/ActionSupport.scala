package com.flo.notification.sdk.model

case class ActionSupport(
  alarmId: Int,
  actions: List[Action],
  supportOptions: List[SupportOption]
)