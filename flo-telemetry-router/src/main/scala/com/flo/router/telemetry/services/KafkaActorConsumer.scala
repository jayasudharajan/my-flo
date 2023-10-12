package com.flo.router.telemetry.services

import akka.actor.{Actor, ActorLogging}
import com.flo.communication.avro.IAvroWithSchemaRegistryKafkaConsumer
import com.flo.communication.{IKafkaConsumer, TopicRecord}
import com.flo.router.telemetry.domain.{AvroTelemetry, Telemetry}
import com.flo.router.telemetry.services.KafkaActorConsumer.Consume
import com.flo.utils.ResourcePuller
import com.sksamuel.avro4s.FromRecord
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.duration._

abstract class KafkaActorConsumer[KafkaMessage <: AnyRef : Manifest](
                                                                      kafkaConsumer: IKafkaConsumer,
                                                                      //avroKafkaConsumer: IAvroWithSchemaRegistryKafkaConsumer,
                                                                      avroTelemetryTopic: String,
                                                                      deserializer: String => KafkaMessage,
                                                                      filterTimeInSeconds: Int
                                                                    )
  extends Actor
    with ActorLogging {

  var isPaused = false
  var killSwitchHasChanged = true

  val puller = new ResourcePuller[Boolean](
    context.system,
    () => {
      val result = sys.env.get("KILL_SWITCH_ENABLED") match {
        case Some(isKillSwitchEnabled) =>
          if(killSwitchHasChanged) log.info(s"KILL_SWITCH_ENABLED: $isKillSwitchEnabled")
          isKillSwitchEnabled.toBoolean
        case None =>
          if(killSwitchHasChanged) log.info("KILL_SWITCH_ENABLED is set to default value: false")
          false
      }
      killSwitchHasChanged = result != isPaused
      result
    }
  )

  puller.pullEvery(2.seconds, paused => {
    isPaused = paused

    if(paused) {
      kafkaConsumer.pause()
    }

    if(!paused && kafkaConsumer.isPaused()) {
      kafkaConsumer.resume()
    }
  })

  override def preStart(): Unit = {
    self ! Consume
  }

  def receive: Receive = {
    case Consume => {
      /*
      if(!isPaused) {
        implicit val fromRecord = FromRecord[AvroTelemetry]

        avroKafkaConsumer.consume[AvroTelemetry](
          avroTelemetryTopic,
          record => handle(TopicRecord[Telemetry](record.data.toTelemetry(), record.createdAt))
        )
      }
      */

      kafkaConsumer.consume[Telemetry](deserializer.asInstanceOf[String => Telemetry], record => {
        handle(record)
      })
    }
  }

  private def handle(record: TopicRecord[Telemetry]): Unit = {
    val shouldBeProcessed = record.createdAt.isAfter(
      DateTime.now(DateTimeZone.UTC).minusSeconds(filterTimeInSeconds)
    )

    if(shouldBeProcessed) {
      consume(record.data.asInstanceOf[KafkaMessage])
    }
  }

  def consume(kafkaMessage: KafkaMessage): Unit
}

object KafkaActorConsumer {
  object Consume
}