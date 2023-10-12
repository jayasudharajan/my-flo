package com.flo.push.aws.sns

import com.amazonaws.services.sns.AmazonSNS
import com.amazonaws.services.sns.model.PublishRequest
import com.flo.logging.logbookFor
import com.flo.push.aws.sns.circe._
import com.flo.push.core.api._
import io.circe.syntax._
import perfolation._

import scala.concurrent.{ExecutionContext, Future, blocking}

class SendAndroidPushNotification(snsClient: AmazonSNS)(implicit ec: ExecutionContext) extends PushNotificationSender {

  import SendAndroidPushNotification.log

  override def apply(pushNotification: PushNotification, resourceName: ResourceName): Future[Unit] = {
    val notification = Notification(pushNotification.title, pushNotification.body, pushNotification.tag, pushNotification.color, pushNotification.clickAction)
    val data = Data(pushNotification.metadata)
    val androidNotificationStr = AndroidNotification(notification, data).asJson.noSpaces
    val androidPushNotification = AndroidPushNotification(androidNotificationStr)
    val message = AwsPushMessageConfig(androidPushNotification.asJson).asJson.noSpaces

    val publishRequest: PublishRequest = new PublishRequest()
      .withTargetArn(resourceName)
      .withMessage(message)
      .withMessageStructure("json")

    log.debug(p"Sending android push notification. Message = $message. Resource Name = $resourceName")

    Future {
      blocking {
        snsClient.publish(publishRequest)
      }
    }
  }
}

object SendAndroidPushNotification {
  private val log = logbookFor(getClass)
}
