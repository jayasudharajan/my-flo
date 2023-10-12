package com.flo.notification.sdk.service

case class NotificationResponseAction(
                                       actionId: Int,
                                       ts: Long
                                     )

object NotificationResponseAction {
  val NONE = -1
  val ACCEPT_AS_NORMAL = 0
  val SNOOZE = 1
  val CLOSE_VALVE = 2
  val OPEN_VALVE = 3
  val SWITCH_TO_HOME_MODE = 4
}