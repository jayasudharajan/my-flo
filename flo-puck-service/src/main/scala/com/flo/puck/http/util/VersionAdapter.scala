package com.flo.puck.http.util

class VersionAdapter extends (Int => String) {
  val majorFactor = 10000
  val minorFactor = 100

  override def apply(version: Int): String = {
    val major = version / majorFactor
    val minorF = version - (major * majorFactor)
    val minor = minorF / minorFactor
    val build = minorF - (minor * minorFactor)
    s"$major.$minor.$build"
  }
}
