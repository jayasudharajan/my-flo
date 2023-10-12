package com.flo.puck.core.water

import com.flo.logging.logbookFor
import com.flo.puck.core.ActionResolver
import com.flo.puck.core.api._
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class WaterPresenceResolver(
  getActionRules: GetActionRules,
  sendWaterLeakPuckAlert: PuckIncidentSender,
  executeWaterShutoff: ShutoffExecutor
)(implicit ec: ExecutionContext) extends ActionResolver {

  import WaterPresenceResolver.log

  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): Future[Unit] = {
    log.info(p"Resolving water presence for puck: ${puckTelemetryProperties.macAddress}")

    val futureIncidentAction = sendWaterLeakPuckAlert(puckTelemetryProperties, device)

    val eventualAction = for {
      actionRules     <- getActionRules(device.id)
      _               <- executeWaterShutoff(actionRules)
      incidentAction  <- futureIncidentAction
    } yield incidentAction

    eventualAction.failed.foreach { e =>
      throw new RuntimeException(p"Error while trying to resolve water presence for puck ${puckTelemetryProperties.macAddress}", e)
    }

    eventualAction.foreach { _ =>
      log.info(p"Water presence successfully resolved for puck: ${puckTelemetryProperties.macAddress}")
    }

    eventualAction
  }
}

object WaterPresenceResolver {
  private val log = logbookFor(getClass)
}
