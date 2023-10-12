package com.flo.puck.http

import scala.concurrent.Future

trait HttpPost[T] extends (T => Future[Unit])
