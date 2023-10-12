package com.flo.notification.router.core.api

case class MetaData(
    deviceId: String,
    icdId: String,
    userId: String,
    alarmId: Int,
    systemMode: Int,
    incidentRegistryId: String
)
