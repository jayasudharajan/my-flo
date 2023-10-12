package com.flo.notification.router.core.api

case class TitleAndMessage(title: String, message: String)

case class IncidentInfo(alarmIncident: AlarmIncident,
                        alarmId: AlarmId,
                        deviceId: DeviceId,
                        locationId: LocationId,
                        accountId: AccountId,
                        groupId: Option[GroupId],
                        alarmStatus: AlarmStatus,
                        localizedTexts: Map[TitleAndMessage, (Set[Locale], Set[UnitSystem])] = Map(),
                        userId: Option[UserId] = None)
