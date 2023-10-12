package com.flo.puck.core.resolver

import com.flo.logging.logbookFor
import com.flo.puck.core.api.{AlarmAutoResolveProcessor, AlarmStateSender, AlertTriggered, Device, GetEventsByDeviceId, PuckTelemetryProperties}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

private class AlarmAutoResolver(
                                 getEventsByDeviceId: GetEventsByDeviceId,
                                 sendAlarmState: AlarmStateSender
                               )(implicit ec: ExecutionContext) extends AlarmAutoResolveProcessor {

  import AlarmAutoResolver.log

  private val highHumidity    = 102
  private val lowHumidity     = 103
  private val highTemperature = 104
  private val lowTemperature  = 105
  private val lowBattery      = 106

  override def apply(device: Device, telemetry: PuckTelemetryProperties): Future[Unit] = {
    val puckResolvableAlerts = Map(
      highHumidity    -> telemetry.alertHumidityHighActive,
      lowHumidity     -> telemetry.alertHumidityLowActive,
      highTemperature -> telemetry.alertTemperatureHighActive,
      lowTemperature  -> telemetry.alertTemperatureLowActive,
      lowBattery      -> telemetry.alertBatteryActive
    )

    getEventsByDeviceId(device.id).map(events => {
      val eventsToResolve = events.filter(event => {
        val isActive = puckResolvableAlerts.getOrElse(event.alarm.id, Some(true)).contains(true)
        event.status == AlertTriggered && !isActive
      })

      if (eventsToResolve.nonEmpty) {
        Future.traverse(eventsToResolve) { event =>
          val futureState = sendAlarmState(device.macAddress, event)
          futureState.failed.foreach(e => {
            log.error(p"Error auto-resolving alarm ${event.alarm.id} for device ${device.macAddress}", e)
          })

          futureState.map { _ =>
            log.info(p"Alarm ${event.alarm.id} successfully auto-resolved for device ${device.macAddress}")
          }
        }
      }
    })
  }
}

object AlarmAutoResolver {
  private val log = logbookFor(getClass)
}
