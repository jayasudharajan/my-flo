package com.flo.router.telemetry

import akka.actor.{ActorSystem, OneForOneStrategy, SupervisorStrategy}
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{ContentTypes, HttpEntity}
import akka.http.scaladsl.server.Directives._
import akka.pattern.{Backoff, BackoffSupervisor}
import akka.stream.ActorMaterializer
import com.flo.communication.utils.KafkaConsumerMetrics
import com.flo.communication.KafkaConsumer
import com.flo.router.telemetry.domain.{AvroTelemetry, Telemetry}
import com.flo.router.telemetry.services.TelemetryKafkaConsumer
import com.flo.router.telemetry.utils.{ConfigUtils, TelemetryRepository}
import com.flo.utils.FromSneakToCamelCaseDeserializer
import com.typesafe.scalalogging.LazyLogging
import kamon.Kamon

import scala.concurrent.duration._
import com.flo.communication.avro.{AvroWithSchemaRegistryKafkaConsumer, ConsumerWithSchemaRegistryHelper, StandardAvroKafkaConsumer}
import com.sksamuel.avro4s.{AvroSchema, FromRecord}

object TelemetryRouterApplication extends App with LazyLogging {
  //DO NOT CHANGE THE NAME OF ACTOR SYSTEM, IS USED TO CONFIGURE MONITORING TOOL
  implicit val system = ActorSystem("telemetry-router-system")
  implicit val materializer = ActorMaterializer()
  implicit val executionContext = system.dispatcher

  logger.info("Actor system was created for Telemetry Router")

  implicit val kafkaConsumerMetrics = Kamon.metrics.entity(
    KafkaConsumerMetrics,
    ConfigUtils.kafka.topic,
    tags = Map("service-name" -> ConfigUtils.kafka.groupId)
  )

  val kafkaConsumer = new KafkaConsumer(
    ConfigUtils.kafka.host,
    ConfigUtils.kafka.groupId,
    ConfigUtils.kafka.topic,
    kafkaConsumerMetrics,
    messageDecoder = None,
    clientName = Some("telemetry-router-1"),
    maxPollRecords = ConfigUtils.kafka.maxPollRecords,
    pollTimeout = ConfigUtils.kafka.pollTimeout
  )

  val goodDataTelemetryRepository = new TelemetryRepository(
    ConfigUtils.influx.logLevel, ConfigUtils.influx.databases
  )
  val badDataTelemetryRepository = new TelemetryRepository(
    ConfigUtils.influx.logLevel, ConfigUtils.influx.badDataDatabases
  )
  val deserializer = new FromSneakToCamelCaseDeserializer

  /*
  val kafkaAvroConsumer = new AvroWithSchemaRegistryKafkaConsumer(
    "telemetry-router-avro",
    ConfigUtils.kafka.host,
    ConfigUtils.kafka.groupId,
    ConfigUtils.kafka.schemaRegistry
  )
  */

  val telemetryKafkaConsumerProps = TelemetryKafkaConsumer.props(
    TelemetryKafkaConsumer.TelemetryKafkaConsumerSettings(
      kafkaConsumer,
      //kafkaAvroConsumer,
      ConfigUtils.kafka.avroTopic,
      x => deserializer.deserialize[Telemetry](x),
      goodDataTelemetryRepository,
      badDataTelemetryRepository,
      ConfigUtils.kafka.filterTimeInSeconds
    )
  )

  val supervisor = BackoffSupervisor.props(
    Backoff.onStop(
      telemetryKafkaConsumerProps,
      childName = "telemetry-consumer",
      minBackoff = 3.seconds,
      maxBackoff = 30.seconds,
      randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
    ).withSupervisorStrategy(
      OneForOneStrategy() {
        case ex =>
          system.log.error(ex, "There was an error in KafkaActor")
          SupervisorStrategy.Restart //Here we can add some log or send a notification
      })
  )

  system.actorOf(supervisor)

  val route =
    path("") {
      get {
        // TODO: Try to connect to real KAFKA
        // TODO: Try to authenticate with InfluxDb with real credentials (from env), but don't error if it's down
        complete(HttpEntity(contentType = ContentTypes.`text/html(UTF-8)`, "<h1>OK</h1>"))
      }
    }

  val bindingFuture = Http().bindAndHandle(route, "0.0.0.0", ConfigUtils.pingPort)
}
