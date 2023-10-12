package com.flo.notification.router.core.filter

import com.flo.AsyncTest
import com.flo.notification.router.core.api.Fixture.{device, user}
import com.flo.notification.router.core.api._
import com.softwaremill.quicklens._

class AlarmSettingsFilterTest extends AsyncTest {
  private val alarm = randomAlarm
  private val alarmIncident = randomAlarmIncident
    .modify(_.snapshot.sw1)
    .setTo(None)
    .modify(_.snapshot.sw2)
    .setTo(None)
  private val valveClosedAlarmIncident = alarmIncident
    .modify(_.snapshot.sw1)
    .setTo(Some(0))
    .modify(_.snapshot.sw2)
    .setTo(Some(1))

  "Alarm Settings Filter" - {

    "should deny all mediums when alarm is internal" in {
      val internalAlarm = alarm.copy(
        isInternal = true,
        enabled = true
      )

      new AlarmSettingsFilter().apply(alarmIncident, internalAlarm, user, device).map { filterResult =>
        filterResult shouldEqual NoMediumsAllowed(AlarmIsInternal)
      }
    }

    "should deny all mediums when alarm is disabled" in {
      val disabledAlarm = alarm.copy(
        isInternal = false,
        enabled = false
      )

      new AlarmSettingsFilter().apply(alarmIncident, disabledAlarm, user, device).map { filterResult =>
        filterResult shouldEqual NoMediumsAllowed(AlarmIsDisabled)
      }
    }

    "should allow all mediums when alarm is not internal and is enabled" in {
      val regularAlarm = alarm.copy(
        enabled = true,
        isInternal = false
      )

      new AlarmSettingsFilter().apply(alarmIncident, regularAlarm, user, device).map { filterResult =>
        filterResult shouldEqual AllMediumsAllowed
      }
    }

    "should deny all mediums when valve is closed and alarm should not be sent under such scenario" in {
      val doNotSendWhenValveClosedAlarm = alarm.copy(enabled = true, isInternal = false, sendWhenValveIsClosed = false)

      new AlarmSettingsFilter().apply(valveClosedAlarmIncident, doNotSendWhenValveClosedAlarm, user, device).map {
        filterResult =>
          filterResult shouldEqual NoMediumsAllowed(ValveClosed)
      }
    }

    "should allow supported mediums when valve is closed and alarm should be sent under such scenario" in {
      val sendWhenValveIsClosedAlarm = alarm.copy(
        enabled = true,
        isInternal = false,
        sendWhenValveIsClosed = true
      )

      new AlarmSettingsFilter().apply(valveClosedAlarmIncident, sendWhenValveIsClosedAlarm, user, device).map {
        filterResult =>
          filterResult shouldEqual AllMediumsAllowed
      }
    }
  }
}
