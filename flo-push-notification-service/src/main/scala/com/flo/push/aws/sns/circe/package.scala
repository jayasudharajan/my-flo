package com.flo.push.aws.sns

import io.circe.Encoder
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.deriveConfiguredEncoder

package object circe {

  private val customConfig: Configuration = Configuration.default.withDefaults

  implicit val awsPushMessageConfigEncoder: Encoder[AwsPushMessageConfig] = {
    implicit val _ = customConfig.copy(
      transformMemberNames = {
        case "message" => "Message"
        case other => other
      }
    )
    deriveConfiguredEncoder
  }

  implicit val androidPushNotificationEncoder: Encoder[AndroidPushNotification] = {
    implicit val _ = customConfig.copy(transformMemberNames = _.toUpperCase)
    deriveConfiguredEncoder
  }

  implicit val notificationEncoder: Encoder[Notification] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredEncoder
  }

  implicit val dataEncoder: Encoder[Data] = {
    implicit val _ = customConfig.copy(
      transformMemberNames = {
        case "floAlarmNotification" => "FloAlarmNotification"
        case other => Configuration.snakeCaseTransformation(other)
      }
    )
    deriveConfiguredEncoder
  }

  implicit val androidNotificationEncoder: Encoder[AndroidNotification] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredEncoder
  }

  implicit val categoryEncoder: Encoder[Category] = {
    implicit val _ = customConfig.copy(
      transformMemberNames = {
        case "floAlarmNotification" => "FloAlarmNotification"
        case other => Configuration.snakeCaseTransformation(other)
      }
    )
    deriveConfiguredEncoder
  }

  implicit val iosNotificationEncoder: Encoder[IosNotification] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredEncoder
  }

  implicit val iosNotificationContainerEncoder: Encoder[IosNotificationContainer] = {
    implicit val _ = customConfig.withSnakeCaseMemberNames
    deriveConfiguredEncoder
  }

  implicit val iosPushNotificationEncoder: Encoder[IosPushNotification] = {
    implicit val _ = customConfig.copy(transformMemberNames = _.toUpperCase)
    deriveConfiguredEncoder
  }

  implicit val iosSandboxPushNotificationEncoder: Encoder[IosSandboxPushNotification] =  {
    implicit val _ = customConfig.copy(
      transformMemberNames = Configuration.snakeCaseTransformation.andThen(_.toUpperCase)
    )
    deriveConfiguredEncoder
  }
}
