package com.flo.notification.sdk.model.kafka

case class AlarmIncidentAlarmInfo(
                                   //reason == alarmId
                                   reason:Int,
                                   //ht => happenedAt
                                   ht: Long,
                                   defer: Long = 0,
                                   acts: Option[String] = None
                                 )
