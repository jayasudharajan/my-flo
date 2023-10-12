package com.flo.notification.router.core.filter

import com.flo.AsyncTest
import com.flo.notification.router.core.api._
import org.mockito.Mockito.when

import scala.concurrent.Future

class AlarmsMuteFilterTest extends AsyncTest {
  private val alarmIncident = randomAlarmIncident
  private val alarm         = randomAlarm
  private val user          = randomUser
  private val device        = randomDevice

  "Alarms Mute Filter" - {

    "should allow all mediums when alarms are not muted" in {
      val retrieveDeliverySettings = mock[DeliverySettingsRetriever]
      val alarmsMuteFilter         = new AlarmsMuteFilter(retrieveDeliverySettings)

      when(retrieveDeliverySettings(user, device.id, alarm.id, alarmIncident.systemMode))
        .thenReturn(
          Future.successful(
            Some(
              DeliverySettings(sms = false, email = false, pushNotification = false, voiceCall = false, isMuted = false)
            )
          )
        )

      alarmsMuteFilter.apply(alarmIncident, alarm, user, device).map { filterResult =>
        filterResult shouldEqual AllMediumsAllowed
      }
    }

    "should deny all mediums when alarms are muted" in {
      val retrieveDeliverySettings = mock[DeliverySettingsRetriever]
      val alarmsMuteFilter         = new AlarmsMuteFilter(retrieveDeliverySettings)

      when(retrieveDeliverySettings(user, device.id, alarm.id, alarmIncident.systemMode))
        .thenReturn(
          Future.successful(
            Some(
              DeliverySettings(sms = false, email = false, pushNotification = false, voiceCall = false, isMuted = true)
            )
          )
        )

      alarmsMuteFilter.apply(alarmIncident, alarm, user, device).map { filterResult =>
        filterResult shouldEqual NoMediumsAllowed(AlarmsMuted)
      }
    }
  }
}
