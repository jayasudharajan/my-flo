package com.flo.util

import perfolation._

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

object Meter {

  val tagExclusionList = List()
  val enabled          = false

  def time[R](tag: String)(block: => Future[R])(implicit ex: ExecutionContext): Future[R] = {
    val t0 = System.nanoTime()

    val r = block

    if (enabled && !tagExclusionList.contains(tag)) {
      r.onComplete {
        case Success(_) =>
          val t1 = System.nanoTime()
          println(p"Success ($tag) Elapsed time: ${((t1 - t0) / 1000000)}ms")

        case Failure(ex) =>
          val t1 = System.nanoTime()
          println(p"Error ($tag) Elapsed time: ${((t1 - t0) / 1000000)}ms")
          println(ex)
      }
    }

    r // call-by-name
  }
}
