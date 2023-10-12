package com.flo.push.sdk

import com.flo.Enums.Apps.ClientApps
import com.flo.push.core.api.{NotificationTokenRetriever, UserId, UserNotificationTokens}
import com.flo.FloApi.v2.{NotificationTokenEndpoints => NotificationTokenEndpointsV2}
import com.flo.FloApi.v3.{NotificationTokenEndpoints => NotificationTokenEndpointsV3}
import com.flo.Models.v2.NotificationToken

import scala.annotation.tailrec
import scala.concurrent.{ExecutionContext, Future}

private[sdk] class RetrieveNotificationTokens(notificationTokenEndpointsV2: NotificationTokenEndpointsV2,
                                              notificationTokenEndpointsV3: NotificationTokenEndpointsV3)
                                             (implicit ec: ExecutionContext)
  extends NotificationTokenRetriever {

  override def apply(userId: UserId): Future[UserNotificationTokens] = {
    notificationTokenEndpointsV3.GetTokens(userId).flatMap {
      case None =>
        notificationTokenEndpointsV2.Get(userId).map { maybeNotificationTokensV2 =>
          maybeNotificationTokensV2.fold(UserNotificationTokens(userId, Set(), Set())) { tokens =>
            UserNotificationTokens(userId, tokens.androidToken.getOrElse(Set()), tokens.iosToken.getOrElse(Set()))
          }
        }

      case Some(notificationTokensV3) => Future.successful(getNotificationTokensFromV3(userId, notificationTokensV3))
    }
  }

  private def getNotificationTokensFromV3(userId: String, tokens: Set[NotificationToken]): UserNotificationTokens =
    processTokens(tokens, UserNotificationTokens(userId, Set(), Set()))

  private def processToken(token: NotificationToken, userTokens: UserNotificationTokens): UserNotificationTokens = {
    val isTokenDisabled = token.isDisabled.contains(1)
    if (isTokenDisabled) userTokens
    else {
      token.clientType match {
        case ClientApps.I_PHONE       => userTokens.copy(iosTokens = userTokens.iosTokens + token.token)
        case ClientApps.ANDROID_PHONE => userTokens.copy(androidTokens = userTokens.androidTokens + token.token)
      }
    }
  }

  @tailrec
  private def processTokens(tokens: Set[NotificationToken],
                            userNotificationTokens: UserNotificationTokens): UserNotificationTokens =
    if (tokens.isEmpty) userNotificationTokens
    else processTokens(tokens.tail, processToken(tokens.head, userNotificationTokens))
}
