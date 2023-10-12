package com.flo.notification.sdk.model

import java.time.LocalDateTime
import java.util.UUID

case class FeedbackIdValue(id: String, value: String)

case class UserFeedback(incidentId: UUID, userId: UUID, feedback: Seq[FeedbackIdValue], createdAt: LocalDateTime, updatedAt: LocalDateTime)
