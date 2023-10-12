package com.flo.puck.core.trigger

import com.flo.puck.core.api.{Device, PuckTelemetryProperties}

import scala.concurrent.{ExecutionContext, Future}

final private class ActionTriggerExecutor(triggers: List[ActionTrigger])(
  implicit ec: ExecutionContext
) extends ActionTrigger {

  override def apply(puckTelemetryProperties: PuckTelemetryProperties, device: Device): Future[Unit] = {
    Future.traverse(triggers) { trigger =>
      trigger(puckTelemetryProperties, device)
    }.map(_ => ())
  }
}
