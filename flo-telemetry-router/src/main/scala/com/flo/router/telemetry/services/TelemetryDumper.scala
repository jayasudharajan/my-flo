package com.flo.router.telemetry.services

import akka.actor.{Actor, ActorLogging, Props}
import TelemetryDumperSupervisor.Saved
import com.flo.router.telemetry.domain.Telemetry
import com.flo.router.telemetry.utils.{BackoffStrategy, ITelemetryRepository, TelemetryValidator}

class TelemetryDumper(
                       goodDataTelemetryRepository: ITelemetryRepository,
                       badDataTelemetryRepository: ITelemetryRepository,
                       backoffStrategy: BackoffStrategy,
                       telemetry: Telemetry
                     )
  extends Actor with ActorLogging {

  import context.dispatcher

  override def preStart(): Unit = {
    context.system.scheduler.scheduleOnce(backoffStrategy.backoffTime, self, telemetry)
    backoffStrategy.increment()
  }


  // The only stable data the actor has during restarts is those embedded in
  // the Props when it was created. In this case telemetryRepository, backoffStrategy and telemetry.
  def receive: Receive = {
    case telemetry: Telemetry =>

//   Stop filtering data all together as we don't want bad P/T sensors to affect water usage.
     // if (TelemetryValidator.isValid(telemetry)) {
        goodDataTelemetryRepository.save(telemetry)
     // } else {
     //   badDataTelemetryRepository.save(telemetry)
     // }

      backoffStrategy.reset()

      //indicate to supervisor that the operation was a success
      context.parent ! Saved(telemetry)
      // Don't forget to stop the actor after it has nothing more to do
      context.stop(self)
  }
}

object TelemetryDumper {
  def props(
             goodDataTelemetryRepository: ITelemetryRepository,
             badDataTelemetryRepository: ITelemetryRepository,
             backoffStrategy: BackoffStrategy,
             telemetry: Telemetry
           ): Props =
    Props(classOf[TelemetryDumper], goodDataTelemetryRepository, badDataTelemetryRepository, backoffStrategy, telemetry)
}


