package com.flo.notification.router.core.filter

import cats.data.NonEmptySet
import com.flo.AsyncTest
import com.flo.notification.router.core.api._
import org.mockito.Mockito.when

import scala.concurrent.Future

class DeliverySettingsFilterTest extends AsyncTest {
  private val alarmIncident = randomAlarmIncident
  private val alarm         = randomAlarm
  private val user          = randomUser
  private val device        = randomDevice

  "Delivery Settings Filter" - {

    "should deny all mediums when no delivery settings are found" in {
      val retrieveDeliverySettings = mock[DeliverySettingsRetriever]

      when(retrieveDeliverySettings(user, device.id, alarm.id, alarmIncident.systemMode))
        .thenReturn(Future.successful(None))

      new DeliverySettingsFilter(retrieveDeliverySettings).apply(alarmIncident, alarm, user, device).map {
        filterResult =>
          filterResult shouldEqual NoMediumsAllowed(DeliverySettingsNotFound)
      }
    }

    "should deny all mediums when configured to do so" in {
      val retrieveDeliverySettings = mock[DeliverySettingsRetriever]
      val deliverySettings         = DeliverySettings(sms = false, email = false, pushNotification = false, voiceCall = false)

      when(retrieveDeliverySettings(user, device.id, alarm.id, alarmIncident.systemMode))
        .thenReturn(Future.successful(Some(deliverySettings)))

      new DeliverySettingsFilter(retrieveDeliverySettings).apply(alarmIncident, alarm, user, device).map {
        filterResult =>
          filterResult shouldEqual NoMediumsAllowed(DeliverySettingsNoMediumsAllowed)
      }
    }

    "should allow the configured mediums" in {
      val retrieveDeliverySettings = mock[DeliverySettingsRetriever]
      val deliverySettings         = DeliverySettings(sms = true, email = true, pushNotification = false, voiceCall = false)

      when(retrieveDeliverySettings(user, device.id, alarm.id, alarmIncident.systemMode))
        .thenReturn(Future.successful(Some(deliverySettings)))

      new DeliverySettingsFilter(retrieveDeliverySettings).apply(alarmIncident, alarm, user, device).map {
        filterResult =>
          filterResult shouldEqual AllowedMediums(NonEmptySet.of(SmsMedium, EmailMedium))
      }
    }

  }
}
