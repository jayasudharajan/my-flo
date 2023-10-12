package com.flo.notification.sdk.model

import java.util.UUID

case class UserGraveyardTime (
    id: UUID,
    accountId: UUID,
    userId: UUID,
    startsAt: String,
    endsAt: String,
    allowEmail: Boolean,
    allowSms: Boolean,
    allowPush: Boolean,
    allowCall: Boolean,
    whenSeverityIs: String
)