package com.flo.notification.router.core.api

case class CallMessage(
    from: Option[String],
    to: String,
    scriptUrl: String,
    statusCallbackUrl: String,
    callMetaData: Option[MetaData]
)
