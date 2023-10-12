package com.flo.router.telemetry.services

import akka.actor.Props
import com.flo.communication.IKafkaConsumer
import com.flo.communication.avro.IAvroWithSchemaRegistryKafkaConsumer
import com.flo.router.telemetry.domain.Telemetry
import com.flo.router.telemetry.services.TelemetryKafkaConsumer.TelemetryKafkaConsumerSettings
import com.flo.router.telemetry.utils.{ITelemetryRepository, TelemetryValidator}

class TelemetryKafkaConsumer(settings: TelemetryKafkaConsumerSettings)
  extends KafkaActorConsumer[Telemetry](
    settings.kafkaConsumer,
    //settings.avroKafkaConsumer,
    settings.avroTelemetryTopic,
    settings.deserializer,
    settings.filterTimeInSeconds
  ) {

  log.info("TelemetryKafkaConsumer started!")

  val telemetryDumperSupervisor = context.actorOf(
    TelemetryDumperSupervisor.props(settings.goodDataTelemetryRepository, settings.badDataTelemetryRepository),
    "telemetry-dumper-supervisor"
  )

  override def consume(kafkaMessage: Telemetry): Unit = {
    if(!TelemetryValidator.shouldBeDropped(kafkaMessage)) {
      telemetryDumperSupervisor ! kafkaMessage
    }
  }
}

object TelemetryKafkaConsumer {
  case class TelemetryKafkaConsumerSettings(
                                             kafkaConsumer: IKafkaConsumer,
                                             //avroKafkaConsumer: IAvroWithSchemaRegistryKafkaConsumer,
                                             avroTelemetryTopic: String,
                                             deserializer: String => Telemetry,
                                             goodDataTelemetryRepository: ITelemetryRepository,
                                             badDataTelemetryRepository: ITelemetryRepository,
                                             filterTimeInSeconds: Int
                                           )

  def props(settings: TelemetryKafkaConsumerSettings): Props = Props(classOf[TelemetryKafkaConsumer], settings)
}