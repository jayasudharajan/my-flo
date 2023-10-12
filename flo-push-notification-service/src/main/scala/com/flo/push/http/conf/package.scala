package com.flo.push.http

package object conf {
  private[http] case class HttpConfig(notificationApi: NotificationApiConfig)

  private[http] case class NotificationApiConfig(baseUri: String, statusPath: String)
}
