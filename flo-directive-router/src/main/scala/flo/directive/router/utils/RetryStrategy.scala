package flo.directive.router.utils

trait RetryStrategy {
  def increment(): Unit

  def isRetryLimitReached(): Boolean
}
