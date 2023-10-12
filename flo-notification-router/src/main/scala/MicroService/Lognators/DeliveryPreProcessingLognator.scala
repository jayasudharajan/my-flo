package MicroService.Lognators

import Models.Mediums.PreProcessingMessage
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentData
import com.flo.Models.Logs.{ICDAlarmIncidentRegistry, ICDAlarmNotificationStatusRegistry}


class DeliveryPreProcessingLognator {

  def incidentLogMessage(ppMessage: PreProcessingMessage): String = {
    val alarmLogMesage = getAlarmInfoFromIncidentData(ppMessage.icdAlarmIncidentMessage.data)

    s"Original incident ID: ${ppMessage.icdAlarmIncidentMessage.id} incident Registry id: ${getIncidentIdFromIncident(ppMessage.createIcdIncidentRegistryRecord)} alarm info: $alarmLogMesage icd id: ${getIcdIdFromIncident(ppMessage.createIcdIncidentRegistryRecord)}"

  }

  def zendeskEmailNotSent(ppMsg: PreProcessingMessage): String = {
    s"CS email was not sent. It's scheduled notifications: ${ppMsg.icdAlarmIncidentMessage.scheduledNotificationInfo.isEmpty.toString} is user tenant:${ppMsg.isUserTenant.toString} log message:${incidentLogMessage(ppMsg)}"
  }

  private def getIcdIdFromIncident(incident: Option[ICDAlarmIncidentRegistry]): String = incident match {
    case Some(incidentRegistry) => incidentRegistry.icdId
    case _ => "N/A"
  }

  private def getIncidentIdFromIncident(incident: Option[ICDAlarmIncidentRegistry]): String = incident match {
    case Some(incidentRegistry) => incidentRegistry.id
    case _ => "N/A"
  }

  private def getAlarmInfoFromIncidentData(data: ICDAlarmIncidentData): String = {
    s"alarm id: ${data.alarm.alarmId} system mode: ${data.snapshot.systemMode.getOrElse("N/A")}"

  }

}
