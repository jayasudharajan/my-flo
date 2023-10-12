package MicroService.Lognators

import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentData
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Logs.ICDAlarmIncidentRegistry

class DecisionEngineLognator {

  def incidentLogMessage(deviceId: String, incident: ICDAlarmIncident, incidentRegistry: Option[ICDAlarmIncidentRegistry]): String = incidentRegistry match {
    case Some(incidentReg) =>
      val alarmLogMesage = getAlarmInfoFromIncidentData(incident.data)
      s"deviceId: ${incident.deviceId}  incident Registry id: ${incidentReg.id} alarm info: $alarmLogMesage icd id: ${incidentReg.icdId}"
    case _ =>
      val alarmLogMesage = getAlarmInfoFromIncidentData(incident.data)
      s"deviceId: ${incident.deviceId}  incident ID: ${incident.id} alarm info: $alarmLogMesage "
  }

  private def getAlarmInfoFromIncidentData(data: ICDAlarmIncidentData): String = {
    s"alarm id: ${data.alarm.alarmId} system mode: ${data.snapshot.systemMode.getOrElse("N/A")}"

  }


}



