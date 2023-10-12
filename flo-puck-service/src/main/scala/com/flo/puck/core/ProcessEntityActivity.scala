package com.flo.puck.core

import java.time.{Clock, LocalDateTime}

import com.flo.logging.logbookFor
import com.flo.puck.core.api.activity._
import com.flo.puck.core.api.{AudioSettings, EntityActivityProcessor, AudioSettingsSaver}
import perfolation._

import scala.concurrent.Future

private class ProcessEntityActivity(clock: Clock,
                                    saveAudioSettings: AudioSettingsSaver)
  extends EntityActivityProcessor {

  import ProcessEntityActivity.log

  override def apply(entityActivity: EntityActivity): Future[Unit] = {
    val now = LocalDateTime.now(clock)

    entityActivity match {
      case EntityActivity(_, Alert, Updated, Some(EntityActivityItem(_, Resolved, Some(Snoozed), Some(snoozeTo)))) if now.isAfter(snoozeTo) =>
        log.warn(p"Snooze time $snoozeTo is prior to current time $now. Ignoring.")
        Future.unit

      case EntityActivity(_, Alert, Updated, Some(EntityActivityItem(device, Resolved, Some(Snoozed), Some(snoozeTo)))) =>
        log.info(p"Processing Entity Activity: $entityActivity")
        saveAudioSettings(device.macAddress, AudioSettings(snoozeTo))

      case entityActivity: EntityActivity =>
        log.debug(p"Ignoring Entity Activity: $entityActivity")
        Future.unit
    }
  }

}

object ProcessEntityActivity {
  private val log = logbookFor(getClass)
}
