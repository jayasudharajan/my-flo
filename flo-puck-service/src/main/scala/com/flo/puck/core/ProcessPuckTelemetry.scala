package com.flo.puck.core

import com.flo.logging.logbookFor
import com.flo.puck.core.api.{AlarmAutoResolveProcessor, CurrentPuckTelemetrySaver, GetDeviceByMacAddress, HistoricalPuckTelemetryAppender, PuckTelemetry, PuckTelemetryProcessor}
import com.flo.puck.core.trigger.ActionTrigger
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

private class ProcessPuckTelemetry(applyActionTrigger: ActionTrigger,
                                   appendHistoricalPuckTelemetry: HistoricalPuckTelemetryAppender,
                                   saveCurrentPuckTelemetry: CurrentPuckTelemetrySaver,
                                   getDeviceByMacAddress: GetDeviceByMacAddress,
                                   processAlarmAutoResolve: AlarmAutoResolveProcessor)
                                  (implicit ec: ExecutionContext) extends PuckTelemetryProcessor {

  import ProcessPuckTelemetry.log

  override def apply(puckTelemetry: PuckTelemetry): Future[Unit] = {
    log.info(p"Processing Puck Telemetry: $puckTelemetry")

    appendHistoricalPuckTelemetry(puckTelemetry).failed.foreach { e =>
      log.error(p"Error appending historical puck telemetry for device ${puckTelemetry.properties.macAddress}", e)
    }

    saveCurrentPuckTelemetry(puckTelemetry.properties.macAddress, puckTelemetry).failed.foreach { e =>
      log.error(p"Error saving current puck telemetry for device ${puckTelemetry.properties.macAddress}", e)
    }

    val eventualDevice = getDeviceByMacAddress(puckTelemetry.properties.macAddress)

    eventualDevice.flatMap(device => {
      processAlarmAutoResolve(device, puckTelemetry.properties).failed.foreach { e =>
        log.error(p"Error processing alarm auto resolve for device ${puckTelemetry.properties.macAddress}", e)
      }
      applyActionTrigger(puckTelemetry.properties, device)
    })
  }
}

object ProcessPuckTelemetry {
  private val log = logbookFor(getClass)
}
