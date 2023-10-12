package com.flo.push.core

import com.flo.logging.logbookFor
import com.flo.push.core.api.{MarkAsSent, NotificationTokenRetriever, PushNotification, PushNotificationPlatformProcessor, PushNotificationProcessor}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class ProcessPushNotification(retrieveNotificationTokens: NotificationTokenRetriever,
                              processAndroidNotification: PushNotificationPlatformProcessor,
                              processIosNotification: PushNotificationPlatformProcessor,
                              markNotificationAsSent: MarkAsSent)
                             (implicit ec: ExecutionContext) extends PushNotificationProcessor {

  import ProcessPushNotification.log

  override def apply(pushNotification: PushNotification): Future[Unit] =
    retrieveNotificationTokens(pushNotification.userId).flatMap { tokens =>
      log.debug(p"Processing ${tokens.androidTokens.size} android notifications and ${tokens.iosTokens.size} ios notifications for user ${pushNotification.userId}")

      val eventualAndroidNotifications = tokens.androidTokens.map { androidToken =>
        processAndroidNotification(pushNotification, androidToken)
      }

      val eventualIosNotifications = tokens.iosTokens.map { iosToken =>
        processIosNotification(pushNotification, iosToken)
      }

      val eventualNotifications = Future.sequence(eventualAndroidNotifications.toSeq ++ eventualIosNotifications.toSeq).map(_ => ())

      eventualNotifications.foreach { _ =>
        log.debug(p"Marking notification as sent for incident=${pushNotification.requestId} and user=${pushNotification.userId}")
        markNotificationAsSent(pushNotification.userId, pushNotification.requestId).failed.foreach { t =>
          log.error(p"Error while marking notification as sent for incident=${pushNotification.requestId} and user=${pushNotification.userId}", t)
        }
      }

      eventualNotifications
    }
}

object ProcessPushNotification {
  private val log = logbookFor(getClass)
}

