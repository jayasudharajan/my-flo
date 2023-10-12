package flo.services.sms.utils

import java.util.concurrent.TimeUnit
import scala.concurrent.duration.FiniteDuration

class SimpleBackoffStrategy(
                             private val backoffDelta: Long = 3000,
                             private val maxBackoff: Long = 30000
                           ) extends BackoffStrategy {

  private var time: Long = 0

  def increment(): Unit = {
    val newTime = time + backoffDelta
    if(newTime > maxBackoff)
      time = maxBackoff
    else
      time = newTime
  }

  def backoffTime: FiniteDuration = {
    FiniteDuration(time, TimeUnit.MILLISECONDS)
  }

  def reset(): Unit = { time = 0 }
}
