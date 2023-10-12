package com.flo.push.kafka

import java.time.Duration

package object conf {
  private[push] case class ConsumerConfig(hosts: String,
                                          groupId: String,
                                          topic: String,
                                          pollTimeout: Duration,
                                          parallelism: Int)
}
