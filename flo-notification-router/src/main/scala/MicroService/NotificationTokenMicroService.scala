package MicroService

import com.flo.Enums.Apps.ClientApps
import com.flo.Models.NotificationToken

class NotificationTokenMicroService {
  def getNotificationTokensFromV2ToV1(tokens: Set[com.flo.Models.v2.NotificationToken]): Option[NotificationToken] = {
    var androidTokens, iosTokens = Set[String]()

    tokens.foreach(t => {
      val disabled = {
        if (t.isDisabled.isDefined && t.isDisabled.nonEmpty)
          t.isDisabled.get
        else 0
      }

      if (disabled == 0) {
        t.clientType match {
          case ClientApps.I_PHONE =>
            iosTokens += t.token
          case ClientApps.ANDROID_PHONE =>
            androidTokens += t.token
        }
      }

    })

    Some(NotificationToken(
      userId = Some(tokens.head.userId),
      iosToken = Some(iosTokens),
      androidToken = Some(androidTokens)
    ))

  }

}
