package com.flo.notification.sdk.model

import java.time.LocalDateTime
import java.util.UUID

case class LocalizedText(value: String, lang: Set[String], unitSystems: Set[String])

case class IncidentText(incidentId: UUID, deviceId: UUID, text: Map[String, Set[LocalizedText]], createdAt: LocalDateTime)
