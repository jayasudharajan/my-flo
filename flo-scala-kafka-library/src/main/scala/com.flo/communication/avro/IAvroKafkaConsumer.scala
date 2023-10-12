package com.flo.communication.avro

import java.util.Date

import akka.actor.{ActorSystem, Props}
import akka.kafka.Subscriptions
import akka.kafka.scaladsl.{Consumer, Producer}
import akka.stream.scaladsl.{RestartSource, Sink, Source}
import akka.stream.{ActorMaterializer, ActorMaterializerSettings, Supervision}
import com.flo.communication.TopicRecord
import com.flo.communication.utils.IKafkaConsumerMetrics
import com.sksamuel.avro4s._
import org.apache.log4j.{Level, Logger}
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.duration._
import scala.util.{Failure, Success, Try}

trait IAvroKafkaConsumer {
  implicit val system: ActorSystem
  implicit val materializer: ActorMaterializer
  implicit val metrics: IKafkaConsumerMetrics

  import system.dispatcher

  val clientName: String
  val bootstrapServers: String
  val groupId: String

  protected val logger = Logger.getLogger(getClass)

  logger.setLevel(Level.ALL)

  val rebalanceListener = system.actorOf(Props[RebalanceListener])

  protected def process[T](item: T, timestamp: Long, processor: TopicRecord[T] => Unit): Unit = {
    Try(
      processor(TopicRecord(item, new DateTime(new Date(timestamp)).toDateTime(DateTimeZone.UTC)))
    ) match {
      case Failure(e) => {
        metrics.newProcessorError()

        logger.error("Error when trying to process message", e)
      }
      case Success(_) => metrics.newSuccess()
    }
  }

  protected def sourceFromTopic[V, Deserialized <: Product : Decoder : SchemaFor](
                                                            topic: String,
                                                            avroConsumerHelper: AvroConsumerHelper[V, Deserialized]
                                                          ): Source[DeserializedMessage[Deserialized], Consumer.Control] = {

    val subscription = Subscriptions
      .topics(Set(topic))
      .withRebalanceListener(rebalanceListener)

    val decider: Supervision.Decider = {
      case _: SerializationException => Supervision.Resume
      case _                         => Supervision.Stop
    }

    implicit val materializer = ActorMaterializer(
      ActorMaterializerSettings(system).withSupervisionStrategy(decider))

    Consumer.committableSource(avroConsumerHelper.consumerSettings, subscription)
      .map { msg =>
        val items = Try {
          avroConsumerHelper
            .deserialize(msg.record.value())
            .map(x => DeserializedMessage[Deserialized](x, msg.record.timestamp(), msg.committableOffset))
        }

        items match {
          case Failure(e) => {
            msg.committableOffset.commitScaladsl()
            metrics.newDeserializationError()

            logger.error("Error when trying to deserialize a batch/message", e)
          }
          case _ =>
        }

        items
      }
      .filter(msg => msg.isSuccess)
      .map(msg => msg.get)
      .mapConcat(identity)
  }

  protected def forwardTo[VConsumer, VProducer, Deserialized <: Product : Decoder : SchemaFor, ToSerialize <: Product : Encoder : SchemaFor](
                                                                                sourceTopic: String,
                                                                                destinationTopic: String,
                                                                                mapper: Source[DeserializedMessage[Deserialized], Consumer.Control] => Source[DeserializedMessage[ToSerialize], Consumer.Control],
                                                                                avroConsumerHelper: AvroConsumerHelper[VConsumer, Deserialized],
                                                                                avroProducerHelper: AvroProducerHelper[ToSerialize, VProducer]
                                                                              ): Unit = {

    logger.info(s"Forwarding to topic $sourceTopic to topic ${destinationTopic} in servers $bootstrapServers")

    val producerSettings = avroProducerHelper.producerSettings

    RestartSource
      .withBackoff(
        minBackoff = 3.seconds,
        maxBackoff = 300.seconds,
        randomFactor = 0.2
      ) { () =>
        Source.fromFuture {
          mapper(sourceFromTopic[VConsumer, Deserialized](sourceTopic, avroConsumerHelper))
            .map { msg =>
              avroProducerHelper.createProducerMessage(destinationTopic, msg)
            }
            .via(Producer.flexiFlow(producerSettings))
            .mapAsync(producerSettings.parallelism) { result =>
              result.passThrough.commitScaladsl()
            }
            .watchTermination() {
              case (consumerControl, futureDone) =>
                futureDone
                  .flatMap { _ =>
                    consumerControl.shutdown()
                  }
                  .recoverWith { case _ => consumerControl.shutdown() }
            }
            .runWith(Sink.ignore)
        }
      }.runWith(Sink.ignore)
  }

  protected def consume[VConsumer, Deserialized <: Product : Decoder : SchemaFor](
                                      topic: String,
                                      processor: TopicRecord[Deserialized] => Unit,
                                      avroConsumerHelper: AvroConsumerHelper[VConsumer, Deserialized]
                                    ): Unit = {

    logger.info(s"Connecting to topic $topic in servers $bootstrapServers")

    RestartSource
      .withBackoff(
        minBackoff = 3.seconds,
        maxBackoff = 300.seconds,
        randomFactor = 0.2
      ) { () =>
        Source.fromFuture {
          sourceFromTopic[VConsumer, Deserialized](topic, avroConsumerHelper)
            .map { msg =>
              process[Deserialized](msg.item, msg.timestamp, processor)

              msg.offset
            }
            /*
            .batch(
              max = 5,
              CommittableOffsetBatch.apply
            )(_.updated(_))
            .map(_.commitScaladsl())
            */
            .map(_.commitScaladsl())
            .watchTermination() {
              case (consumerControl, futureDone) =>
                futureDone
                  .flatMap { _ =>
                    consumerControl.shutdown()
                  }
                  .recoverWith { case _ => consumerControl.shutdown() }
            }
            .runWith(Sink.ignore)
        }
      }.runWith(Sink.ignore)
  }
}
