package com.flo.router.telemetry.services

import akka.actor.SupervisorStrategy.Restart
import akka.actor.{Actor, ActorLogging, OneForOneStrategy, Props}
import com.flo.router.telemetry.domain.Telemetry
import com.flo.router.telemetry.services.TelemetryDumperSupervisor.Saved
import com.flo.router.telemetry.utils._

class TelemetryDumperSupervisor(
                                 goodDataTelemetryRepository: ITelemetryRepository,
                                 badDataTelemetryRepository: ITelemetryRepository
                               ) extends Actor with ActorLogging {

  log.info("TelemetryDumperSupervisor started!")

  override val supervisorStrategy = OneForOneStrategy(loggingEnabled = false) {
    case e: Exception =>
      log.error(e, "There was an error when trying to save telemetry data, restarting.")
      Restart
  }

  def receive: Receive = {
    case telemetry: Telemetry =>
      context.actorOf(
        TelemetryDumper.props(
          goodDataTelemetryRepository, badDataTelemetryRepository, new SimpleBackoffStrategy, telemetry
        )
      )
    case Saved(telemetry) =>
      //Make some post process
  }
}

object TelemetryDumperSupervisor {
  def props(goodDataTelemetryRepository: ITelemetryRepository, badDataTelemetryRepository: ITelemetryRepository): Props =
    Props(classOf[TelemetryDumperSupervisor], goodDataTelemetryRepository, badDataTelemetryRepository)

  case class Saved(telemetry: Telemetry)
}




