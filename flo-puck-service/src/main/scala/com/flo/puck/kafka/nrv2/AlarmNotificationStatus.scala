package com.flo.puck.kafka.nrv2

import io.circe.Json

case class DataAlarm(reason: Int)

case class AlarmNotificationStatusData(
                                      alarm: DataAlarm,
                                      snapshot: Json
                                      )

case class AlarmNotificationStatus(
                                  id: String,
                                  ts: Long,
                                  did: String,
                                  status: Int,
                                  data: AlarmNotificationStatusData
                                  )
