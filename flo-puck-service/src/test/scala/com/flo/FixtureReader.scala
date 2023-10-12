package com.flo

import scala.io.Source

trait FixtureReader {
  def fixture(fileName: String): String = {

    val url = getClass.getResource(s"/$fileName")
    val source  = Source.fromURL(url)
    val content = source.getLines().mkString
    source.close()
    content
  }
}

object FixtureReader extends FixtureReader
