package com.flo.push.core.api

case class PushNotification(requestId: String,
                            userId: String,
                            deviceId: String,
                            title: String,
                            body: String,
                            tag: String,
                            color: String,
                            clickAction: String,
                            metadata: Metadata
                           )
