package com.flo.services.email.utils

import scala.concurrent.duration.FiniteDuration

trait BackoffStrategy {
  def increment(): Unit

  def backoffTime: FiniteDuration

  def reset(): Unit
}
