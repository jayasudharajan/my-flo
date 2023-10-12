package com.flo.notification.router

import java.time.format.DateTimeFormatter
import java.time.{LocalTime, Duration => JavaDuration}

import com.flo.pureconfig.AutoDerivation
import com.typesafe.config.Config
import pureconfig.configurable._
import pureconfig.{ConfigConvert, ConfigReader}

import scala.concurrent.duration.Duration
import scala.reflect.ClassTag

package object conf extends AutoDerivation {

  implicit val durationReader: ConfigReader[JavaDuration] =
    ConfigReader[Duration].map(d => JavaDuration.ofNanos(d.toNanos))

  implicit val localTimeConverter: ConfigConvert[LocalTime] = localTimeConfigConvert(DateTimeFormatter.ISO_LOCAL_TIME)

  implicit class ConfigLoader(config: Config) {
    def as[A: ClassTag](key: String)(implicit reader: pureconfig.Derivation[ConfigReader[A]]): A =
      pureconfig.loadConfigOrThrow[A](config, key)
  }
}
