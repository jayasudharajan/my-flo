package com.flo.router.telemetry.services

import akka.actor.ActorSystem
import akka.testkit.{ImplicitSender, TestKit}
import com.flo.communication.avro.{IAvroWithSchemaRegistryKafkaConsumer, IStandardAvroKafkaConsumer}
import com.flo.router.telemetry.domain.Telemetry
import com.flo.router.telemetry.utils.ITelemetryRepository
import org.scalamock.scalatest.MockFactory
import org.scalatest.{BeforeAndAfterAll, Matchers, WordSpecLike}

import scala.util.Try

abstract class BaseTelemetryActorsSpec extends TestKit(ActorSystem("MySpec"))
  with ImplicitSender
  with WordSpecLike with Matchers with BeforeAndAfterAll with MockFactory {

  val timestamp = System.currentTimeMillis()

  val telemetry1 = Telemetry(
    Some(1.0), None, None, None, None, None, Some(timestamp), None, None, None
  )

  val telemetry2 = Telemetry(
    Some(2.0), None, None, None, None, None, Some(timestamp), None, None, None
  )

  /*
  val kafkaConsumer = stub[IKafkaConsumer]

  (kafkaConsumer.consume[Telemetry](_ : String => Telemetry, _ : TopicRecord[Telemetry] => Unit)(_ : Manifest[Telemetry]) )
    .expects(*, *, *)
    .onCall((_, processor, _) => {
      List(
        TopicRecord(telemetry1, DateTime.now()),
        TopicRecord(telemetry2, DateTime.now())
      ) foreach { x =>
        processor(x)
      }
    })
    .anyNumberOfTimes
    */

  val avroKafkaConsumer = stub[IAvroWithSchemaRegistryKafkaConsumer]

  override def afterAll(): Unit = {
    TestKit.shutdownActorSystem(system)
  }

  def repositoryThatSuccess = new ITelemetryRepository {
    private var data: List[Telemetry] = Nil

    def getSavedData = data

    override def save(telemetry: Telemetry): Try[Unit] = {
      data = telemetry :: data
      Try(Unit)
    }
  }
  def repositoryThatFailFirstTime = new ITelemetryRepository {
    private var data: List[Telemetry] = Nil

    private var attempts = 0

    def getAttempts = attempts
    def getSavedData = data.reverse

    override def save(telemetry: Telemetry): Try[Unit] = {
      attempts = attempts + 1

      if(attempts <= 1) {
        throw new Exception("ShouldFail error.")
      }

      data = telemetry::data
      Try(Unit)
    }
  }
}
