package com.flo.notification.sdk.model

import java.util.UUID

case class VoiceRequestLog(incidentId: UUID, userId: UUID, requestBody: Map[String, Any])
