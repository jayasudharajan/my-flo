package com.flo.notification.router.core.api

// This contract can not be changed because there is a service that implements the voice logic
case class VoiceCall(
    id: RequestId,
    message: String,
    requestInfo: VoiceCallData
)
