package com.flo.notification.kafka

import java.util.concurrent.atomic.AtomicReference

import akka.kafka.ConsumerMessage.CommittableOffsetBatch
import akka.kafka.scaladsl.Consumer
import akka.kafka.{ConsumerSettings, Subscription}
import akka.stream.scaladsl.{RestartSource, Sink}
import akka.stream.{ActorAttributes, ActorMaterializer, Attributes, Supervision}
import com.flo.logging.logbookFor
import com.flo.notification.router.core.api.{Consumer, EntityActivityProcessor, ResumeOnExceptions}
import com.flo.notification.router.core.api.activity.EntityActivity
import perfolation._

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

class EntityActivityKafkaConsumer(
    consumerSettings: ConsumerSettings[String, String],
    subscription: Subscription,
    parallelism: Int,
    deserializeEntityActivity: String => EntityActivity
)(implicit ec: ExecutionContext, am: ActorMaterializer)
    extends Consumer[EntityActivityProcessor] {

  import EntityActivityKafkaConsumer.log

  private val control = new AtomicReference[Consumer.Control](Consumer.NoopControl)

  override def start(processEntityActivity: EntityActivityProcessor, r: Option[ResumeOnExceptions]): Unit =
    RestartSource
      .onFailuresWithBackoff(
        minBackoff = 3.seconds,
        maxBackoff = 5.minutes,
        randomFactor = 0.2
      ) { () =>
        Consumer
          .committableSource[String, String](consumerSettings, subscription)
          .mapAsyncUnordered(parallelism) { msg =>
            log.debug(p"Received Entity Activity message: $msg")
            val entityActivity = deserializeEntityActivity(msg.record.value)

            val eventualProcess = processEntityActivity(entityActivity)

            eventualProcess.failed.foreach { e =>
              log.error("Error processing Entity Activity message. Resuming...", e)
            }

            eventualProcess.transformWith { _ =>
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

object EntityActivityKafkaConsumer {
  private val log = logbookFor(getClass)
}
