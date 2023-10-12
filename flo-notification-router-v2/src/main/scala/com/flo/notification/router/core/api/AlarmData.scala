package com.flo.notification.router.core.api

case class AlarmData(
    id: Int,
    happenedAt: Long,
    defer: Long,
    acts: Option[String]
)
