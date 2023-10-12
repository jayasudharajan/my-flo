package com.flo.notification.router.core.api

import com.flo.notification.sdk.model.{Alarm, Incident}
import com.flo.notification.sdk.util.RandomDataGeneratorUtil
import io.circe.{Json => CirceJson}
import org.scalacheck.{Arbitrary, Gen}

trait RandomFixtures extends RandomDataGeneratorUtil {
  implicit private val randomUnitSystem: Arbitrary[UnitSystem] = Arbitrary(Gen.oneOf(Imperial, Metric))

  implicit private val randomJson: Arbitrary[Option[Json]] = Arbitrary(
    Gen.option(Gen.const(CirceJson.obj("test" -> CirceJson.fromString("1"))))
  )

  def randomAlarm: Alarm                 = random[Alarm]
  def randomAlarmIncident: AlarmIncident = random[AlarmIncident]
  def randomIncident: Incident           = random[Incident]
  def randomUser: User                   = random[User]
  def randomDevice: Device               = random[Device]
}
