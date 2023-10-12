package com.flo.push.core

import com.flo.logging.logbookFor
import com.flo.push.core.api.{PushNotification, PushNotificationPlatformProcessor, PushNotificationSender, ResourceNameRegistrator, Token}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class ProcessPlatformNotification(registerResourceName: ResourceNameRegistrator,
                                  resourceName: String,
                                  sendPushNotification: PushNotificationSender)
                                 (implicit ec: ExecutionContext) extends PushNotificationPlatformProcessor {

  import ProcessPlatformNotification.log

  override def apply(pushNotification: PushNotification, token: Token): Future[Unit] = {
    log.debug(p"Registering resource name for user ${pushNotification.userId} and device ${pushNotification.deviceId}")
    registerResourceName(pushNotification.userId, pushNotification.deviceId, resourceName, token).flatMap { resourceName =>
      log.info(p"Sending push notification to user ${pushNotification.userId} and device ${pushNotification.deviceId}")
      sendPushNotification(pushNotification, resourceName)
    }
  }
}

object ProcessPlatformNotification {
  private val log = logbookFor(getClass)
}
