package com.flo.notification.router.core.api

import java.time.LocalTime

case class DoNotDisturbSettings(startsAt: LocalTime,
                                endsAt: LocalTime,
                                allowEmail: Boolean,
                                allowSms: Boolean,
                                allowPushNotification: Boolean,
                                allowVoiceCall: Boolean,
                                allowedSeverities: Set[SeverityId])
