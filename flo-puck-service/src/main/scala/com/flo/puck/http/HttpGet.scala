package com.flo.puck.http

import scala.concurrent.Future

trait HttpGet[T, R] extends (T => Future[R])