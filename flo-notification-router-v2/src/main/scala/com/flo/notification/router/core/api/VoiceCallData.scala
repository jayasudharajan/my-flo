package com.flo.notification.router.core.api

import org.joda.time.DateTime

case class VoiceCallData(
    appName: String,
    category: Int,
    time: String = DateTime.now().toDateTimeISO.toString(),
    version: Int = 1
)
