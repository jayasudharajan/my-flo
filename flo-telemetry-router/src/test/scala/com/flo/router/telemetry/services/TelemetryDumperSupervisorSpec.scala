package com.flo.router.telemetry.services

import akka.testkit.TestProbe
import scala.concurrent.duration._

class TelemetryDumperSupervisorSpec extends BaseTelemetryActorsSpec {

  "The TelemetryDumperSupervisor" should {
    "success to save telemetry data at first attempt" in {
      val proxy = TestProbe()
      val goodDataTelemetryRepository = repositoryThatSuccess
      val badDataTelemetryRepository = repositoryThatSuccess
      val telemetryDumperSupervisor = system.actorOf(
        TelemetryDumperSupervisor.props(goodDataTelemetryRepository, badDataTelemetryRepository)
      )

      proxy.send(telemetryDumperSupervisor, telemetry1)

      awaitAssert({
        goodDataTelemetryRepository.getSavedData.find(m => m == telemetry1) shouldEqual Some(telemetry1)
      }, 1.second, 100.milliseconds)
    }

    "fails the first attempt but success to save telemetry data at second attempt" in {
      val proxy = TestProbe()
      val goodDataTelemetryRepository = repositoryThatFailFirstTime
      val badDataTelemetryRepository = repositoryThatSuccess
      val telemetryDumperSupervisor = system.actorOf(
        TelemetryDumperSupervisor.props(goodDataTelemetryRepository, badDataTelemetryRepository)
      )

      proxy.send(telemetryDumperSupervisor, telemetry1)

      awaitAssert({
        goodDataTelemetryRepository.getSavedData.length shouldEqual 1
        goodDataTelemetryRepository.getAttempts shouldEqual 2

        goodDataTelemetryRepository.getSavedData.find(m => m == telemetry1) shouldEqual Some(telemetry1)
      }, 6.second, 100.milliseconds)
    }
  }
}