package com.flo

import org.scalatest.{Assertion, AsyncFreeSpecLike}

import scala.concurrent.Future

trait AsyncTest extends Test with AsyncFreeSpecLike {

  implicit def toSuccess(f: => Future[Unit]): Future[Assertion] = f.map { _ =>
    succeed
  }

}