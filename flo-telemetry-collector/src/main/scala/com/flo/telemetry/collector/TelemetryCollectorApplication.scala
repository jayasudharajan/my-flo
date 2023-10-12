package com.flo.telemetry.collector

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.http.scaladsl.model.{ContentTypes, HttpEntity}
import akka.http.scaladsl.server.Directives._
import akka.stream.ActorMaterializer
import com.flo.communication.avro.{DeserializedMessage, StandardAvroKafkaConsumer}
import com.flo.communication.utils.KafkaConsumerMetrics
import com.flo.telemetry.collector.domain.{Telemetry, TelemetryBatch}
import com.flo.telemetry.collector.utils.ConfigUtils
import com.sksamuel.avro4s.{AvroSchema, SchemaFor}
import com.typesafe.scalalogging.LazyLogging
import kamon.Kamon

object TelemetryCollectorApplication extends App with LazyLogging {
  //DO NOT CHANGE THE NAME OF ACTOR SYSTEM, IS USED TO CONFIGURE MONITORING TOOL
  implicit val system = ActorSystem("telemetry-collector-system")
  implicit val materializer = ActorMaterializer()
  implicit val executionContext = system.dispatcher
  implicit val schema = SchemaFor[Telemetry]

  val telemetrySchema = AvroSchema[Telemetry]

  logger.info("Actor system was created for Telemetry Collector")

  implicit val kafkaConsumerMetrics = Kamon.metrics.entity(
    KafkaConsumerMetrics,
    ConfigUtils.kafka.sourceTopic,
    tags = Map("service-name" -> ConfigUtils.kafka.groupId)
  )

  val kafkaAvroConsumer = new StandardAvroKafkaConsumer(
    "telemetry-collector",
    ConfigUtils.kafka.host,
    ConfigUtils.kafka.groupId
  )

  kafkaAvroConsumer.forwardTo[TelemetryBatch, Telemetry](
    ConfigUtils.kafka.sourceTopic,
    ConfigUtils.kafka.destinationTopic,
    source => {
      source.map(x => x.item.toList().map(y => DeserializedMessage(y, x.timestamp, x.offset))).mapConcat(identity)
    }
  )

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
