package com.flo.puck.kafka

import java.util.concurrent.atomic.AtomicReference

import akka.actor.ActorSystem
import akka.kafka.ConsumerMessage.CommittableOffsetBatch
import akka.kafka.scaladsl.Consumer
import akka.kafka.{ConsumerSettings, Subscription}
import akka.stream.scaladsl.{RestartSource, Sink}
import akka.stream.{ActorAttributes, Attributes, Supervision}
import com.flo.logging.logbookFor
import com.flo.puck.core.api.{Consumer, PuckTelemetry, PuckTelemetryProcessor, ResumeOnExceptions}
import io.circe.DecodingFailure
import perfolation._

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

final private class PuckTelemetryKafkaConsumer(
    consumerSettings: ConsumerSettings[String, String],
    subscription: Subscription,
    parallelism: Int,
    deserializePuckTelemetry: String => PuckTelemetry
)(implicit ec: ExecutionContext, as: ActorSystem)
  extends Consumer[PuckTelemetryProcessor] {

  import PuckTelemetryKafkaConsumer.log

  private val control = new AtomicReference[Consumer.Control](Consumer.NoopControl)

  override def start(processPuckTelemetry: PuckTelemetryProcessor, r: Option[ResumeOnExceptions]): Unit =
    RestartSource
      .onFailuresWithBackoff(
        minBackoff = 3.seconds,
        maxBackoff = 5.minutes,
        randomFactor = 0.2
      ) { () =>
        Consumer
          .committableSource[String, String](consumerSettings, subscription)
          .mapAsyncUnordered(parallelism) { msg =>
            log.debug(p"Received Puck Telemetry message: $msg")

            val puckTelemetry = try {
              deserializePuckTelemetry(msg.record.value)
            } catch {
              case e: DecodingFailure =>
                log.warn("Error while deserializing Puck Telemetry. Resuming...", e)
                msg.committableOffset.commitScaladsl()
                throw e
            }

            val eventualProcess = processPuckTelemetry(puckTelemetry)

            eventualProcess.failed.foreach { e =>
              log.error("Error processing Puck Telemetry message. Resuming...", e)
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

object PuckTelemetryKafkaConsumer {
  private val log = logbookFor(getClass)
}
