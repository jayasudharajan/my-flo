package com.flo

import scala.io.Source

trait FixtureReader {
  def fixture(fileName: String): String = {
    val source  = Source.fromURL(getClass.getResource(s"/$fileName"))
    val content = source.getLines().mkString
    source.close()
    content
  }
}

object FixtureReader extends FixtureReader
