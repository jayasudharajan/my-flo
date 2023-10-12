package com.flo

import java.time.LocalDateTime

package object scheduler {
  private[scheduler] case class FixedDateScheduleConfig(target: LocalDateTime)
  private[scheduler] case class FixedDateSchedule(`type`: String = "fixedDate", config: FixedDateScheduleConfig)

  private[scheduler] case class KafkaTransportPayload(topic: String, message: String)
  private[scheduler] case class HttpTransportPayload(method: String, url: String, contentType: String, body: String)

  private[scheduler] case class KafkaTransport(`type`: String = "kafka", payload: KafkaTransportPayload)
  private[scheduler] case class HttpTransport(`type`: String = "http", payload: HttpTransportPayload)

  private[scheduler] case class KafkaTask(id: String,
                                          source: String = "notification-router-v2",
                                          schedule: FixedDateSchedule,
                                          transport: KafkaTransport)
  private[scheduler] case class HttpTask(id: String,
                                         source: String = "notification-router-v2",
                                         schedule: FixedDateSchedule,
                                         transport: HttpTransport)
}
