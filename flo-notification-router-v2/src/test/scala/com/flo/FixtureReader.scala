package com.flo

import perfolation._

import scala.io.Source

trait FixtureReader {
  def fixture(fileName: String): String = {
    val source  = Source.fromURL(getClass.getResource(p"/$fileName"))
    val content = source.getLines().mkString
    source.close()
    content
  }
}

object FixtureReader extends FixtureReader
