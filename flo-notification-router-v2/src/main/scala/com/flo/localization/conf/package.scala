package com.flo.localization

import scala.concurrent.duration.Duration

package object conf {
  private[localization] case class CacheConfig(maxSize: Long, expireAfterWrite: Duration)
}
