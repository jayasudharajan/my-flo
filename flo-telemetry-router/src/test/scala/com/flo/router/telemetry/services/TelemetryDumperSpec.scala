package com.flo.router.telemetry.services

import akka.testkit.{TestActorRef, TestProbe}
import com.flo.router.telemetry.services.TelemetryDumperSupervisor.Saved
import com.flo.router.telemetry.utils.SimpleBackoffStrategy

class TelemetryDumperSpec extends BaseTelemetryActorsSpec {

  "The TelemetryDumper" should {
    "success to save telemetry data and notify the parent" in {
      val parent = TestProbe()
      val goodDataTelemetryRepository = repositoryThatSuccess
      val badDataTelemetryRepository = repositoryThatSuccess

      val telemetryDumperSupervisor = TestActorRef(
        TelemetryDumper.props(
          goodDataTelemetryRepository, badDataTelemetryRepository, new SimpleBackoffStrategy, telemetry1
        ),
        parent.ref,
        "TelemetryDumper"
      )
      telemetryDumperSupervisor ! telemetry1

      parent.expectMsg(Saved(telemetry1))
    }
  }
}