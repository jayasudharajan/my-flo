package com.flo.notification.sdk.model

import java.time.LocalDateTime
import java.util.UUID

import io.getquill.Embedded

case class JsonString(value: String)

case class IncidentSource(id: UUID,
                          deviceId: UUID,
                          data: JsonString,
                          createdAt: LocalDateTime) extends Embedded
