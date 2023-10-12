package com.flo.notification.router.core.delivery

import perfolation._

private[core] object GeneratePushNotificationToTag {
  def apply(alarmId: Int, systemMode: Int): String =
    p"$alarmId$systemMode"
}
