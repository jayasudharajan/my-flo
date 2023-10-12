/*
package org.apache.kafka.test


import java.nio.file.{Files, Path}
import kafka.utils.CoreUtils

//This is a workaround to a missing method in Kafka TestUtils
object TestUtils {
   def tempDirectory(parent: Path, prefix: String) = {

    val f = Files.createTempDirectory(parent, prefix).toFile
    f.deleteOnExit()

    Runtime.getRuntime().addShutdownHook(new Thread() {
      override def run() = {
        CoreUtils.delete(Seq(f.getAbsolutePath))
      }
    })
    f
  }
}
*/