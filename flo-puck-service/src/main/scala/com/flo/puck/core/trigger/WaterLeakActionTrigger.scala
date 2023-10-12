package com.flo.puck.core.trigger

import com.flo.logging.logbookFor
import com.flo.puck.core.ActionResolver
import com.flo.puck.core.api.{AlertTriggered, Device, PuckTelemetryProperties}

import scala.concurrent.Future
import perfolation._

final private class WaterLeakActionTrigger(resolveWaterPresence: ActionResolver) extends ActionTrigger {

  import WaterLeakActionTrigger.log

  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): Future[Unit] = {

    val alertWaterActive = puckTelemetryProperties.alertWaterActive.contains(true)
    val alertStateTriggered = puckTelemetryProperties.alertState.contains(AlertTriggered)

    if (alertWaterActive && alertStateTriggered)
      resolveWaterPresence(puckTelemetryProperties, device)
    else {
      log.debug(p"Water leak action not triggered for puck ${puckTelemetryProperties.macAddress}. " +
        p"AlertWaterActive=${alertWaterActive}. AlertStateTriggered=${alertStateTriggered}")
      Future.unit
    }
  }
}

object WaterLeakActionTrigger {
  private val log = logbookFor(getClass)
}