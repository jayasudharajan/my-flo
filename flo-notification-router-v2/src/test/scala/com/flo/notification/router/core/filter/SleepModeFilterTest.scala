package com.flo.notification.router.core.filter

import com.flo.AsyncTest
import com.flo.Enums.ValveModes
import com.flo.notification.router.core.api.{AllMediumsAllowed, NoMediumsAllowed, SleepMode}
import com.softwaremill.quicklens._

class SleepModeFilterTest extends AsyncTest {
  "Sleep Mode Filter" - {
    "should filter all alarms that are not exceptions when in sleep mode" in {
      val alarm    = randomAlarm
      val device   = randomDevice
      val user     = randomUser
      val incident = randomAlarmIncident.modify(_.systemMode).setTo(ValveModes.SLEEP)

      val sleepModeFilter = new SleepModeFilter(Set())

      sleepModeFilter.apply(incident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual NoMediumsAllowed(SleepMode)
      }
    }

    "should not filter alarms configured as exceptions when in sleep mode" in {
      val alarm    = randomAlarm.modify(_.id).setTo(1)
      val device   = randomDevice
      val user     = randomUser
      val incident = randomAlarmIncident.modify(_.systemMode).setTo(ValveModes.SLEEP)

      val sleepModeFilter = new SleepModeFilter(Set(1))

      sleepModeFilter.apply(incident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual AllMediumsAllowed
      }
    }

    "should not filter alarms when not in sleep mode" in {
      val alarm    = randomAlarm
      val device   = randomDevice
      val user     = randomUser
      val incident = randomAlarmIncident.modify(_.systemMode).setTo(ValveModes.HOME)

      val sleepModeFilter = new SleepModeFilter(Set())

      sleepModeFilter.apply(incident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual AllMediumsAllowed
      }
    }
  }
}
