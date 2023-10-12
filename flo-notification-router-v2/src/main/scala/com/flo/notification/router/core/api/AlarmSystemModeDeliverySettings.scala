package com.flo.notification.router.core.api

case class AlarmSystemModeDeliverySettings(
    alarmId: AlarmId,
    systemMode: SystemMode,
    sms: Boolean,
    email: Boolean,
    pushNotification: Boolean,
    voiceCall: Boolean,
    isMuted: Boolean
) {
  val deliverySettings: DeliverySettings = DeliverySettings(
    sms,
    email,
    pushNotification,
    voiceCall,
    isMuted
  )
}
