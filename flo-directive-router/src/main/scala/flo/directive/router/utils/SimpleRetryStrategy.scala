package flo.directive.router.utils

class SimpleRetryStrategy(numberOfRetries: Int) extends RetryStrategy{
  var count = 0

  def increment(): Unit = {
    count = count + 1
  }

  def isRetryLimitReached(): Boolean = {
    numberOfRetries <= count
  }
}
