package Nators

import com.flo.Models.Logs.ICDAlarmIncidentRegistryLog
import org.joda.time.{DateTime, DateTimeZone}

class ICDAlarmIncidentRegistryLogGenerator {

	def registryLogPost(incidentRegistryId: String, userId: String, deliveryMedium: Int, status: Int, receiptId: Option[String]): ICDAlarmIncidentRegistryLog = {
		ICDAlarmIncidentRegistryLog(
			id = Some(java.util.UUID.randomUUID().toString),
			createdAt = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
			icdAlarmIncidentRegistryId = Some(incidentRegistryId),
			userId = Some(userId),
			deliveryMedium = Some(deliveryMedium),
			status = Some(status),
			receiptId = if (receiptId.isDefined && receiptId.nonEmpty) receiptId else Some(java.util.UUID.randomUUID().toString)
		)
	}

}
