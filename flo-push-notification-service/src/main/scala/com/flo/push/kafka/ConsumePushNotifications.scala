package com.flo.push.kafka

import java.util.concurrent.atomic.AtomicReference

import akka.kafka.ConsumerMessage.CommittableOffsetBatch
import akka.kafka.scaladsl.Consumer
import akka.kafka.{CommitterSettings, ConsumerSettings, Subscription}
import akka.stream.{ActorAttributes, ActorMaterializer, Attributes, Supervision}
import akka.stream.scaladsl.{RestartSource, Sink}
import com.flo.logging.logbookFor
import com.flo.push.core.api.{Consumer, PushNotification, PushNotificationProcessor}
import io.circe.DecodingFailure
import perfolation._

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

class ConsumePushNotifications(
                                consumerSettings: ConsumerSettings[String, String],
                                committerSettings: CommitterSettings,
                                subscription: Subscription,
                                deserializePushNotification: String => PushNotification,
                                parallelism: Int
                              )(implicit ec: ExecutionContext, am: ActorMaterializer) extends Consumer[PushNotificationProcessor] {

  import ConsumePushNotifications.log

  private val control = new AtomicReference[Consumer.Control](Consumer.NoopControl)

  override def start(processPushNotification: PushNotificationProcessor): Unit =
    RestartSource
      .onFailuresWithBackoff(
        minBackoff = 3.seconds,
        maxBackoff = 5.minutes,
        randomFactor = 0.2
      ) { () =>
        Consumer
          .committableSource[String, String](consumerSettings, subscription)
          .mapAsyncUnordered(parallelism) { msg =>
            log.debug(p"Received Push Notification message: $msg")

            val pushNotification = try {
              deserializePushNotification(msg.record.value)
            } catch {
              case e: DecodingFailure =>
                log.warn("Error while deserializing Push Notification. Resuming...", e)
                msg.committableOffset.commitScaladsl()
                throw e
            }

            log.info(p"Processing Push Notification: $pushNotification")

            val eventualResult = processPushNotification(pushNotification)

            eventualResult.failed.foreach { e =>
              log.error("Error processing Push Notification message. Resuming...", e)
            }

            eventualResult.transformWith { _ =>
              Future.successful(msg.committableOffset)
            }
          }
          .withAttributes(alwaysResumeStrategy)
          .batch(max = parallelism.toLong, CommittableOffsetBatch.apply)(_.updated(_))
          .mapAsync(parallelism)(_.commitScaladsl())
          .mapMaterializedValue(c => control.set(c))
      }
      .runWith(Sink.ignore)

  override def stop(): Unit = control.get().shutdown()

  private def alwaysResumeStrategy: Attributes = ActorAttributes.supervisionStrategy { e =>
    Supervision.Resume
  }
}

object ConsumePushNotifications {
  private val log = logbookFor(getClass)
}
