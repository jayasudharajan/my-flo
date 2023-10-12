package com.flo.notification.router.core.delivery

import com.flo.Enums.Notifications.AlarmSeverity

private[core] object GeneratePushNotificationColor {
  def apply(severity: Int): String = severity match {
    case AlarmSeverity.HIGH =>
      "#D7342F"
    case AlarmSeverity.MEDIUM =>
      "#ED7B15"
    case AlarmSeverity.LOW =>
      "#1A77AC"
    case _ =>
      "#1A77AC"
  }
}
