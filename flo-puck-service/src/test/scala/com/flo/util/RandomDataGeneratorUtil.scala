package com.flo.util

import java.time.LocalDateTime
import java.util.UUID

import com.danielasfregola.randomdatagenerator.RandomDataGenerator
import org.scalacheck.{Arbitrary, Gen}

trait RandomDataGeneratorUtil extends RandomDataGenerator {
  implicit val implicitTime = Arbitrary.apply(Gen.delay(LocalDateTime.now))
  implicit val implicitText = Arbitrary.apply(Gen.delay(UUID.randomUUID.toString))
  implicit val implicitUUID = Arbitrary.apply(Gen.delay(UUID.randomUUID))
  implicit val implicitInt = Arbitrary.apply(Gen.choose(1, 1000))
  implicit val implicitMap = Arbitrary.apply(Gen.delay(Map[String, Any]()))
  implicit val implicitJsonString = Arbitrary.apply(Gen.alphaStr.map(io.circe.Json.fromString))
}
