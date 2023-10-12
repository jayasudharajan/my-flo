package com.flo.notification.router.core.api

import java.util.UUID

import com.flo.notification.sdk.util.RandomDataGeneratorUtil
import org.scalacheck.{Arbitrary, Gen}

object Fixture extends RandomDataGeneratorUtil {
  implicit private val randomUnitSystem: Arbitrary[UnitSystem] = Arbitrary(Gen.oneOf(Imperial, Metric))

  val user: User = random[User]

  val accountId: String  = random[UUID].toString
  val locationId: String = random[UUID].toString
  val deviceId: String   = random[UUID].toString

  val location =
    Location(
      locationId,
      "1561  Ridenour Street",
      None,
      "Miami",
      Some("FL"),
      "USA",
      "33179",
      "America/Los_Angeles",
      Some("My Flo Device")
    )

  val device = Device(
    deviceId,
    "21374d8b6641",
    location,
    None,
    Some("Flo Device")
  )
}
