package Nators

import MicroService.TimeService
import com.flo.Models.AlarmNotificationDeliveryFilters
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot

class AlarmNotificationDeliveryFiltersGenerators {
	private lazy val timeService = new TimeService()

	def PutForResolvedAndUnresolved(alarmNotificationDeliveryFilters: AlarmNotificationDeliveryFilters, snapshot: ICDAlarmIncidentDataSnapshot, lastIcdAlarmIncidentRegistryId: String, incidentTime: String, filterStatus: Int): AlarmNotificationDeliveryFilters = {

		AlarmNotificationDeliveryFilters(
			icdId = alarmNotificationDeliveryFilters.icdId,
			alarmId = alarmNotificationDeliveryFilters.alarmId,
			createdAt = alarmNotificationDeliveryFilters.createdAt,
			updatedAt = Some(timeService.getCurrentTimeInISODateUTC()),
			expiresAt = Some(timeService.getCurrentTimeInISODateUTCPlus(years = 100)),
			lastDecisionUserId = alarmNotificationDeliveryFilters.lastDecisionUserId,
			status = Some(filterStatus),
			systemMode = snapshot.systemMode,
			lastIcdAlarmIncidentRegistryId = Some(lastIcdAlarmIncidentRegistryId),
			incidentTime = Some(incidentTime),
			severity = alarmNotificationDeliveryFilters.severity
		)

	}

}
