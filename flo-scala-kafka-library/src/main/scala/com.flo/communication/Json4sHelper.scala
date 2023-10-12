package com.flo.communication

import org.json4s.{DefaultFormats, ext}

trait Json4sHelper {
  val formatsWithMilliseconds = DefaultFormats.lossless ++ ext.JodaTimeSerializers.all
  val formatsWithoutMilliseconds = DefaultFormats ++ ext.JodaTimeSerializers.all
}
