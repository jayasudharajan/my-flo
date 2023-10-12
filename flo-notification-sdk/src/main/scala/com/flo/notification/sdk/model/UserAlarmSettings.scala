package com.flo.notification.sdk.model

import java.util.UUID

case class UserAlarmSettings(
                              userId: UUID,
                              icdId: UUID,
                              floSenseLevel: Option[Int],
                              smallDripSensitivity: Option[Int]
                            )


object UserAlarmSettings {
  val defaults = new {
    val floSenseLevel = 5
    val smallDripSensitivity = 1
  }

  def merge(newSettings: UserAlarmSettings, oldSettings: UserAlarmSettings): UserAlarmSettings = {
    newSettings.copy(
      floSenseLevel = newSettings.floSenseLevel.orElse(oldSettings.floSenseLevel.orElse(Some(defaults.floSenseLevel))),
      smallDripSensitivity = newSettings.smallDripSensitivity.orElse(oldSettings.smallDripSensitivity.orElse(Some(defaults.smallDripSensitivity)))
    )
  }

  def buildDefault(userId: UUID, icdId: UUID): UserAlarmSettings = {
    UserAlarmSettings(userId, icdId, Some(defaults.floSenseLevel), Some(defaults.smallDripSensitivity))
  }
}
