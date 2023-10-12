package com.flo.notification.kafka

import java.util.concurrent.atomic.AtomicReference

import akka.kafka.ConsumerMessage.CommittableOffsetBatch
import akka.kafka.scaladsl.Consumer
import akka.kafka.{ConsumerSettings, Subscription}
import akka.stream.scaladsl.{RestartSource, Sink}
import akka.stream.{ActorAttributes, ActorMaterializer, Attributes, Supervision}
import com.flo.logging.logbookFor
import com.flo.notification.router.core.api.{AlarmIncident, AlarmIncidentProcessor, Consumer, ResumeOnExceptions}
import com.flo.util.Meter
import perfolation._

import scala.concurrent.{ExecutionContext, Future}
import scala.concurrent.duration._

// TODO: Create generic class for consumers.
final private class AlarmIncidentKafkaConsumer(
    consumerSettings: ConsumerSettings[String, String],
    subscription: Subscription,
    parallelism: Int,
    deserializeAlarmIncident: String => AlarmIncident
)(implicit ec: ExecutionContext, am: ActorMaterializer)
    extends Consumer[AlarmIncidentProcessor] {

  import AlarmIncidentKafkaConsumer.log

  private val control = new AtomicReference[Consumer.Control](Consumer.NoopControl)

  override def start(process: AlarmIncidentProcessor, resumeOnExceptions: Option[ResumeOnExceptions]): Unit =
    RestartSource
      .onFailuresWithBackoff(
        minBackoff = 3.seconds,
        maxBackoff = 5.minutes,
        randomFactor = 0.2
      ) { () =>
        Consumer
          .committableSource[String, String](consumerSettings, subscription)
          .mapAsyncUnordered(parallelism) { msg =>
            log.debug(p"Consuming Alarm Incident: $msg")

            val alarmIncident = try {
              deserializeAlarmIncident(msg.record.value)
            } catch {
              // TODO: Check better way of handling this.
              case e if resumeOnExceptions.exists(_.exists(_.isInstance(e))) =>
                log.warn("Error while deserializing Alarm Incident. Resuming...", e)
                msg.committableOffset.commitScaladsl()
                throw e
            }

            log.debug(p"Successfully deserialized Alarm Incident: $alarmIncident")

            val eventualProcess = Meter.time("total-processing-time") {
              process(alarmIncident)
            }

            eventualProcess.failed.foreach { e =>
              log.error("Error processing Alarm Incident message. Resuming...", e)
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

private object AlarmIncidentKafkaConsumer {
  private val log = logbookFor(getClass)
}
