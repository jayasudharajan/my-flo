package flo.models.http

import com.twitter.finatra.request.RouteParam
import com.twitter.finatra.validation.UUID

case class SmsStatusEventRequest(
    @RouteParam @UUID incidentId: String,
    @RouteParam @UUID userId: String,
    messageStatus: String,
    messageSid: String,
    accountSid: String,
    from: String,
    apiVersion: String,
    to: String,
    smsStatus: String,
    smsSid: String,
)
