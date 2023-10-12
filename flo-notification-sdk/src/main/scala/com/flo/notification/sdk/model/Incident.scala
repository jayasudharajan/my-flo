package com.flo.notification.sdk.model

import java.time.LocalDateTime
import java.util.UUID
import io.getquill.Embedded

case class Incident(
                     id: UUID,
                     alarmId: Int,
                     icdId: UUID,
                     status: Int,
                     reason: Option[Int],
                     snoozeTo: Option[LocalDateTime],
                     locationId: UUID,
                     systemMode: Int,
                     accountId: UUID,
                     groupId: Option[UUID],
                     healthTestRoundId: Option[UUID],
                     dataValues: Map[String, Any],
                     updateAt: LocalDateTime,
                     createAt: LocalDateTime,
                     newIncidentRef: Option[UUID] = None,
                     oldIncidentRef: Option[UUID] = None
) extends Embedded


case class IncidentWithAlarmInfo(incident: Incident, alarm: Alarm)