package com.flo.notification.kafka

import java.util.concurrent.atomic.AtomicReference

import akka.kafka.ConsumerMessage.CommittableOffsetBatch
import akka.kafka.scaladsl.Consumer
import akka.kafka.{ConsumerSettings, Subscription}
import akka.stream.scaladsl.{RestartSource, Sink}
import akka.stream.{ActorAttributes, ActorMaterializer, Attributes, Supervision}
import com.flo.logging.logbookFor
import com.flo.notification.router.core.api.{Alert, AlertStatusProcessor, Consumer, ResumeOnExceptions}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}
import scala.concurrent.duration._

final private class AlertStatusKafkaConsumer(
    consumerSettings: ConsumerSettings[String, String],
    subscription: Subscription,
    parallelism: Int,
    deserializeAlert: String => Alert
)(implicit ec: ExecutionContext, am: ActorMaterializer)
    extends Consumer[AlertStatusProcessor] {

  import AlertStatusKafkaConsumer.log

  private val control = new AtomicReference[Consumer.Control](Consumer.NoopControl)

  override def start(process: AlertStatusProcessor, resumeOnExceptions: Option[ResumeOnExceptions]): Unit =
    RestartSource
      .onFailuresWithBackoff(
        minBackoff = 3.seconds,
        maxBackoff = 5.minutes,
        randomFactor = 0.2
      ) { () =>
        Consumer
          .committableSource[String, String](consumerSettings, subscription)
          .mapAsyncUnordered(parallelism) { msg =>
            log.debug(p"Consuming Alert Statust: $msg")

            val alert = try {
              deserializeAlert(msg.record.value)
            } catch {
              // TODO: Check better way of handling this.
              case e if resumeOnExceptions.exists(_.exists(_.isInstance(e))) =>
                log.warn("Error while deserializing Alert. Resuming...", e)
                msg.committableOffset.commitScaladsl()
                throw e
            }

            log.debug(p"Successfully deserialized Alert Status: $alert")

            val eventualProcess = process(alert)

            eventualProcess.failed.foreach { e =>
              log.error("Error processing Alert Status. Resuming...", e)
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

private object AlertStatusKafkaConsumer {
  private val log = logbookFor(getClass)
}
