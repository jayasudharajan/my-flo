package com.flo.push.aws.sns

import com.amazonaws.services.sns.AmazonSNS
import com.amazonaws.services.sns.model.PublishRequest
import com.flo.logging.logbookFor
import com.flo.push.aws.sns.circe._
import com.flo.push.core.api.{PushNotification, PushNotificationSender, ResourceName}
import io.circe.syntax._
import perfolation._

import scala.concurrent.{ExecutionContext, Future, blocking}

class SendIosPushNotification(snsClient: AmazonSNS)(implicit ec: ExecutionContext) extends PushNotificationSender {

  import SendIosPushNotification.log

  override def apply(pushNotification: PushNotification, resourceName: ResourceName): Future[Unit] = {
    val useSandbox = resourceName.toLowerCase.contains("sandbox")

    val iosNotification = IosNotification(pushNotification.body, Category(pushNotification.metadata))
    val iosNotificationContainer = IosNotificationContainer(iosNotification)
    val iosNotificationContainerStr = iosNotificationContainer.asJson.noSpaces

    val iosNotificationJson = {
      if (useSandbox) IosSandboxPushNotification(iosNotificationContainerStr).asJson
      else IosPushNotification(iosNotificationContainerStr).asJson
    }

    val message = AwsPushMessageConfig(iosNotificationJson).asJson.noSpaces

    log.debug(p"Sending ios push notification. Message = $message. Resource Name = $resourceName")

    val publishRequest: PublishRequest = new PublishRequest()
      .withTargetArn(resourceName)
      .withMessage(message)
      .withMessageStructure("json")

    Future {
      blocking {
        snsClient.publish(publishRequest)
      }
    }
  }
}

object SendIosPushNotification {
  private val log = logbookFor(getClass)
}
