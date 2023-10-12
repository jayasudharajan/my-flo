package MicroService

import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.Telemetry
import com.typesafe.scalalogging.LazyLogging

class SnapShotMicroService extends LazyLogging {

  /**
    * This function translates the new Snapshot object the ICD sends in the AlarmNotificationIncidentMessage and
    * creates a Telemetry object
    **/
  def snapshotToTelemetryGenerator(snapshot: ICDAlarmIncidentDataSnapshot): Option[Telemetry] = {
    val tel = Telemetry(
      wf = snapshot.flowRate,
      t = snapshot.temperature,
      p = snapshot.pressure,
      sw1 = snapshot.valveSwitch1,
      sw2 = snapshot.valveSwitch2,
      pef = snapshot.eventFlow,
      ft = snapshot.flowTotalization,
      fd = {
        if (snapshot.eventFlowDurationInSeconds.isDefined) Some(snapshot.eventFlowDurationInSeconds.get)
        else
          None
      },
      pefl = snapshot.eventFlowLimit,
      pmax = snapshot.pressureMaximus,
      pmin = snapshot.pressureMinimum,
      tmax = snapshot.temperatureMaximum,
      tmin = snapshot.temperatureMinimum,
      mafr = snapshot.flowRateLimit,
      ftl = snapshot.flowTotalizationLimit,
      fdl = {
        if (snapshot.eventFlowDurationLimitInSeconds.isDefined)
          Some(snapshot.eventFlowDurationLimitInSeconds.get)
        else
          None
      },
      f = snapshot.flow,
      v = None
    )
    val theV = tel.getTheV(tel.sw1, tel.sw2)
    Some(tel.copy(v = theV))
  }

  /**
    * Business requirement to not send a low preassure alarm notification if the valve is closed, it returns a boolean true if the alarm needs to be filtered, it returns false otherwise.
    **/
  def isValveClosed(sw1: Option[Int], sw2: Option[Int]): Boolean = {
    //validation
    if (sw1.isEmpty || sw2.isEmpty) {
      logger.error(s"Parameters cannot be NONE  sw1: ${sw1.toString} sw2: ${sw2.toString}")
      false
    }
    else {
      val s1 = sw1.get
      val s2 = sw2.get

      if (s1 == 0 && s2 == 1) true else false
    }

  }

}
