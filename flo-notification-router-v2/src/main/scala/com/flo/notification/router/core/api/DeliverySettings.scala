package com.flo.notification.router.core.api

case class DeliverySettings(sms: Boolean,
                            email: Boolean,
                            pushNotification: Boolean,
                            voiceCall: Boolean,
                            isMuted: Boolean = false)
