package flo.directive.router.utils

import org.scalatest.{Matchers, WordSpec}

class SimpleRetryStrategySpec extends WordSpec
  with Matchers {

  "The SimpleRetryStrategy" should {
    "increment the retry counter until it maximum value and isRetryLimitReached should be true" in {
      val retryStrategy = new SimpleRetryStrategy(2)

      retryStrategy.isRetryLimitReached() shouldEqual false

      retryStrategy.increment()

      retryStrategy.isRetryLimitReached() shouldEqual false

      retryStrategy.increment()

      retryStrategy.isRetryLimitReached() shouldEqual true
    }
  }
}