package com.flo.router.telemetry.utils

import org.scalatest.{Matchers, WordSpec}
import scala.concurrent.duration._

class SimpleBackoffStrategySpec extends WordSpec
  with Matchers {

  "The SimpleBackoffStrategy" should {
    "increment the backoff time until it maximum value and never exceed it" in {
      val backoffStrategy = new SimpleBackoffStrategy(10, 30)

      backoffStrategy.backoffTime shouldEqual (0.milliseconds)

      backoffStrategy.increment()

      backoffStrategy.backoffTime shouldEqual (10.milliseconds)

      backoffStrategy.increment()

      backoffStrategy.backoffTime shouldEqual (20.milliseconds)

      backoffStrategy.increment()

      backoffStrategy.backoffTime shouldEqual (30.milliseconds)

      backoffStrategy.increment()

      backoffStrategy.backoffTime shouldEqual (30.milliseconds)

      backoffStrategy.increment()

      backoffStrategy.backoffTime shouldEqual (30.milliseconds)
    }

    "set the backoff time to zero after reset it" in {
      val backoffStrategy = new SimpleBackoffStrategy(10, 30)

      backoffStrategy.backoffTime shouldEqual (0.milliseconds)

      backoffStrategy.increment()

      backoffStrategy.backoffTime shouldEqual (10.milliseconds)

      backoffStrategy.reset()

      backoffStrategy.backoffTime shouldEqual (0.milliseconds)
    }
  }
}



