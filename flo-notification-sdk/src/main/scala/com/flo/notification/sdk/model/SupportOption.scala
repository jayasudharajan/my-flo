package com.flo.notification.sdk.model

case class SupportOption (
    id: Int,
    alarmId: Int,
    actionPath: String,
    actionType: Int,
    sort: Int,
    text: String
)
