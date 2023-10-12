package com.flo.puck.kafka.nrv2

import java.time.ZoneOffset

import com.flo.puck.core.api.{AlarmEvent, MacAddress}

final private[kafka] class AlarmStatusAdapter(generateUuid: => String) extends ((AlarmEvent, MacAddress) => AlarmNotificationStatus) {

  override def apply(event: AlarmEvent, macAddress: MacAddress): AlarmNotificationStatus = {
    AlarmNotificationStatus(
      id      = generateUuid,
      ts      = event.createAt.toEpochSecond(ZoneOffset.UTC),
      did     = macAddress,
      status  = 1, //resolved
      data    = AlarmNotificationStatusData(
        alarm       = DataAlarm(reason = event.alarm.id),
        snapshot    = event.rawFwPayload
      )
    )
  }
}
