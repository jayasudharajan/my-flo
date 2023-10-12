package com.flo.router.telemetry.utils

import com.flo.router.telemetry.domain.Telemetry
import org.scalatest.{Matchers, WordSpec}

class TelemetryValidatorSpec extends WordSpec
  with Matchers {

  "The TelemetryValidator" should {
    "validate all fields rules" in {
      val telemetry1 = new Telemetry(
        f = Some(1.5),
        p = Some(10),
        t = Some(54),
        wf = Some(4),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry1) shouldEqual true

      val telemetry2 = new Telemetry(
        f = Some(2.1),
        p = Some(10),
        t = Some(54),
        wf = Some(4),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry2) shouldEqual false

      val telemetry3 = new Telemetry(
        f = Some(-0.1),
        p = Some(10),
        t = Some(54),
        wf = Some(4),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry3) shouldEqual false

      val telemetry4 = new Telemetry(
        f = Some(0.2),
        p = Some(201),
        t = Some(54),
        wf = Some(4),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry4) shouldEqual false

      val telemetry5 = new Telemetry(
        f = Some(1.8),
        p = Some(-1),
        t = Some(54),
        wf = Some(4),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry5) shouldEqual false

      val telemetry6 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(-1),
        wf = Some(4),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry6) shouldEqual false

      val telemetry7 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(201),
        wf = Some(4),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry7) shouldEqual false

      val telemetry8 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(1),
        wf = Some(-1),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry8) shouldEqual false

      val telemetry9 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(201),
        wf = Some(121),
        sm = Some(3),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry9) shouldEqual false

      val telemetry10 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(1),
        wf = Some(1),
        sm = Some(0),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry10) shouldEqual false

      val telemetry11 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(45),
        wf = Some(121),
        sm = Some(5),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry11) shouldEqual false

      val telemetry12 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(45),
        wf = Some(121),
        sm = Some(1),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry12) shouldEqual false

      val telemetry13 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(45),
        wf = Some(121),
        sm = Some(1),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry13) shouldEqual false

      val telemetry14 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(45),
        wf = Some(121),
        sm = Some(1),
        sw1 = Some(2),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry14) shouldEqual false

      val telemetry15 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(45),
        wf = Some(121),
        sm = Some(1),
        sw1 = Some(1),
        sw2 = Some(2)
      )

      TelemetryValidator.isValid(telemetry15) shouldEqual false

      val telemetry16 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(45),
        wf = Some(121),
        sm = Some(5),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry16) shouldEqual false

      val telemetry17 = new Telemetry(
        f = Some(0.2),
        p = Some(3),
        t = Some(45),
        wf = Some(121),
        sm = Some(1),
        sw1 = Some(1),
        sw2 = Some(1)
      )

      TelemetryValidator.isValid(telemetry17) shouldEqual false
    }
  }
}



