package com.flo.notification.router.core

import com.flo.logging.logbookFor
import com.flo.notification.router.core.api.activity.{Deleted, Device, EntityActivity}
import com.flo.notification.router.core.api.{
  DeviceDataCleanUp,
  DeviceUnpaired,
  EntityActivityProcessor,
  PendingAlertResolver
}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class ProcessEntityActivity(resolvePendingAlerts: PendingAlertResolver, cleanUpDeviceData: DeviceDataCleanUp)(
    implicit ec: ExecutionContext
) extends EntityActivityProcessor {

  import ProcessEntityActivity.log

  override def apply(entityActivity: EntityActivity): Future[Unit] = entityActivity match {
    case EntityActivity(_, Device, Deleted, entityId) =>
      log.info(p"Processing Entity Activity: $entityActivity")
      val eventualResolution = resolvePendingAlerts(entityId, DeviceUnpaired)
      val eventualCleanup    = cleanUpDeviceData(entityId)
      Future.sequence(Seq(eventualResolution, eventualCleanup)).map(_ => ())

    case entityActivity: EntityActivity =>
      log.debug(p"Ignoring Entity Activity: $entityActivity")
      Future.unit
  }

}

object ProcessEntityActivity {
  private val log = logbookFor(getClass)
}
