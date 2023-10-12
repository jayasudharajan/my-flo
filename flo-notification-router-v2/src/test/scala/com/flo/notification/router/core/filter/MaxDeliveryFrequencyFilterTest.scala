package com.flo.notification.router.core.filter

import java.time.{Clock, Instant, LocalDateTime, ZoneId, ZoneOffset}

import com.flo.AsyncTest
import com.flo.notification.router.core.api._
import com.softwaremill.quicklens._
import org.mockito.Mockito._

import scala.concurrent.Future

class MaxDeliveryFrequencyFilterTest extends AsyncTest {
  private val alarmIncidentTimestamp            = LocalDateTime.of(2019, 1, 1, 0, 0)
  private val clock                             = Clock.fixed(Instant.ofEpochMilli(0), ZoneId.of("UTC"))
  private val frequencyCapExpirationInTheFuture = alarmIncidentTimestamp.plusHours(1)
  private val frequencyCapExpirationInThePast   = alarmIncidentTimestamp.minusHours(1)
  private val alarmIncident = randomAlarmIncident
    .modify(_.timestamp)
    .setTo(alarmIncidentTimestamp.toInstant(ZoneOffset.UTC).toEpochMilli)

  "MaxDeliveryFrequencyFilter" - {

    "should allow all mediums when no there is no previous alarm event" in {
      val retrieveFrequencyCapExpiration = mock[FrequencyCapExpirationRetriever]
      val alarm                          = randomAlarm
      val device                         = randomDevice
      val user                           = randomUser
      val maxDeliveryFreqFilter          = new MaxDeliveryFrequencyFilter(clock, retrieveFrequencyCapExpiration)

      when(retrieveFrequencyCapExpiration(alarm.id, device.id, user.id))
        .thenReturn(Future.successful(None))

      maxDeliveryFreqFilter.apply(alarmIncident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual AllMediumsAllowed
      }
    }

    "should return a failed future when retrieving latest alarm event fails" in {
      val retrieveFrequencyCapExpiration = mock[FrequencyCapExpirationRetriever]
      val alarm                          = randomAlarm
      val device                         = randomDevice
      val user                           = randomUser
      val maxDeliveryFreqFilter          = new MaxDeliveryFrequencyFilter(clock, retrieveFrequencyCapExpiration)

      when(retrieveFrequencyCapExpiration(alarm.id, device.id, user.id))
        .thenReturn(Future.failed(new RuntimeException))

      maxDeliveryFreqFilter.apply(alarmIncident, alarm, user, device).failed.map { e =>
        e shouldBe an[RuntimeException]
      }
    }

    "should deny all mediums when delivery frequency is exceeded" in {
      val retrieveFrequencyCapExpiration = mock[FrequencyCapExpirationRetriever]
      val alarm                          = randomAlarm
      val device                         = randomDevice
      val user                           = randomUser
      val maxDeliveryFreqFilter          = new MaxDeliveryFrequencyFilter(clock, retrieveFrequencyCapExpiration)

      when(retrieveFrequencyCapExpiration(alarm.id, device.id, user.id))
        .thenReturn(Future.successful(Some(frequencyCapExpirationInTheFuture)))

      maxDeliveryFreqFilter.apply(alarmIncident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual NoMediumsAllowed(MaxDeliveryFrequencyCap)
      }
    }

    "should allow all mediums when delivery frequency is not exceeded" in {
      val retrieveFrequencyCapExpiration = mock[FrequencyCapExpirationRetriever]
      val alarm                          = randomAlarm.modify(_.maxDeliveryFrequency).setTo("0 hour")
      val device                         = randomDevice
      val user                           = randomUser
      val maxDeliveryFreqFilter          = new MaxDeliveryFrequencyFilter(clock, retrieveFrequencyCapExpiration)

      when(retrieveFrequencyCapExpiration(alarm.id, device.id, user.id))
        .thenReturn(Future.successful(Some(frequencyCapExpirationInThePast)))

      maxDeliveryFreqFilter.apply(alarmIncident, alarm, user, device).map { allowedMediums =>
        allowedMediums shouldEqual AllMediumsAllowed
      }
    }
  }
}
