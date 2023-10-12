package com.flo.telemetry.collector.utils

import java.io.ByteArrayOutputStream
import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.communication.avro.{AvroKafkaProducer, AvroSerializer, StandardAvroKafkaConsumer}
import com.flo.communication.utils.KafkaConsumerMetrics
import com.flo.telemetry.collector.domain.{Telemetry, TelemetryBatch}
import com.sksamuel.avro4s.{AvroSchema, SchemaFor}
import kamon.Kamon
import scala.util.Random

class AvroBatchingProofOfConcept {

  def generateRandomTelemetry(deviceId: Option[String] = None): Telemetry = {
    val r = scala.util.Random

    Telemetry(
      did = deviceId.getOrElse(Random.alphanumeric.take(12).mkString),
      fv = Some(r.nextDouble),
      fr = Some(r.nextDouble),
      p = Some(r.nextFloat),
      t = Some(r.nextFloat),
      v = Some(r.nextInt),
      rssi = Some(r.nextFloat),
      sm = Some(r.nextInt),
      ts = Some(r.nextLong)
    )
  }

  def produceBatchedTelemetryMessages(): Unit = {

    def generateRandomTelemetryBatch(batchSize: Int): TelemetryBatch = {
      val deviceId = Random.alphanumeric.take(12).mkString
      val telemetryData = (1 to 10).map(_ => generateRandomTelemetry(Some(deviceId))).toList

      TelemetryBatch(
        did = deviceId,
        TelemetryBatch = telemetryData.map(x => x.toSimple())
      )
    }

    def sendTelemetryBatch(batch: TelemetryBatch): Unit = {
      implicit val schema = SchemaFor[TelemetryBatch]

      val avroSerializer = new AvroSerializer
      val serializedData = avroSerializer.serialize[TelemetryBatch](batch)
      val producer = new AvroKafkaProducer(ConfigUtils.kafka.host, ConfigUtils.kafka.sourceTopic)

      producer.send(serializedData)
    }

    sendTelemetryBatch(generateRandomTelemetryBatch(5));
    sendTelemetryBatch(generateRandomTelemetryBatch(10));
  }

  def run(): Unit = {
    //DO NOT CHANGE THE NAME OF ACTOR SYSTEM, IS USED TO CONFIGURE MONITORING TOOL
    implicit val system = ActorSystem("telemetry-collector")
    implicit val materializer = ActorMaterializer()
    implicit val executionContext = system.dispatcher
    implicit val schema = SchemaFor[Telemetry]

    val telemetrySchema = AvroSchema[Telemetry]

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

    def sendTelemetryData(telemetryData: List[Telemetry]): Unit = {
      implicit val schema = SchemaFor[Telemetry]

      val avroSerializer = new AvroSerializer
      val serializedData = avroSerializer.serialize[Telemetry](telemetryData)
      val producer = new AvroKafkaProducer(ConfigUtils.kafka.host, ConfigUtils.kafka.sourceTopic)

      producer.send(serializedData)
    }

    println("######## TELEMETRY SCHEMA")
    println(telemetrySchema)

    val bytesSerializedByGo = List(
      24, 74, 71, 83, 65, 80, 71, 65, 84, 76, 77, 79, 68, 192, 255, 220, 227, 195, 89, 43, 19, 82, 141, 74, 2, 222,
      63, 6, 39, 190, 69, 59, 29, 210, 63, 114, 17, 150, 62, 126, 216, 45, 63, 12, 56, 16, 80, 62, 132, 1)
      .map(x => x.toByte).toArray

    println(s"a size: ${bytesSerializedByGo.length}")

    val telemetry = Telemetry(
      p = Some(0.29310184717178345F), v = Some(6), fr = Some(0.4688898449024232),  fv = Some(0.28303415118044517),
      t = Some(0.6790846586227417F), rssi = Some(0.6790846586227417F), did = "JGSAPGATLMOD", ts = Some(1538105516317L),
      sm = Some(66)
    )

    val s = new AvroSerializer()

    println(s.serialize[Telemetry](telemetry).toList)
    println(s"telemetry size: ${s.serialize[Telemetry](telemetry).toList.length}")


    //val d = s.deserialize[Telemetry](a)

    //println(d)


    import org.apache.avro.Schema

    val schema2 = new Schema.Parser().parse(
      """
  {
    "type":"record",
    "name":"Telemetry",
    "namespace":"com.flotechnologies",
    "fields":[
    {"name": "did", "type": "string"},
    {"name": "ts", "type": "long"},
    {"name": "fr", "type": "double"},
    {"name": "fv", "type": "double" },
    {"name": "p", "type": "float" },
    {"name": "t", "type": "float"},
    {"name": "v", "type": "int"},
    {"name": "rssi", "type": "float"},
    {"name": "sm", "type": "int"}
    ]
  }"""
    )

    import org.apache.avro.generic.{GenericDatumReader, GenericRecord}
    import org.apache.avro.io.DecoderFactory

    val out = new ByteArrayOutputStream()

    // Deserialize it.
    val reader = new GenericDatumReader[GenericRecord](schema2)
    val decoder = DecoderFactory.get.binaryDecoder(bytesSerializedByGo, null)
    val result = reader.read(null, decoder)

    println(s"fv: ${result.get("fv")}")



    var messageIndex = 1

    println("####### CONSUMING MESSAGES")

    //sendTelemetryData((1 to 5).map(_ => generateRandomTelemetry()).toList)
    //sendTelemetryData((1 to 10).map(_ => generateRandomTelemetry()).toList)

    kafkaAvroConsumer.consume[Telemetry](ConfigUtils.kafka.sourceTopic, record => {
      println(s"Message $messageIndex:")
      println(record.data)

      messageIndex = messageIndex + 1
    })
  }
}
