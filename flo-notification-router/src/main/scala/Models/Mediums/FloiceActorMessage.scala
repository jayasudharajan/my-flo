package Models.Mediums

import com.flo.Models.{ICDAlarmNotificationDeliveryRules, Location}
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.UserContactInformation

case class FloiceActorMessage(
                               userContactInformation: UserContactInformation,
                               incidentRegistry: ICDAlarmIncidentRegistry,
                               location: Option[Location],
                               iCDAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules,
                               snapshot: ICDAlarmIncidentDataSnapshot,
                               isUserTenant: Boolean,
                               isUserLandlord: Boolean,
                               unitSystem: MeasurementUnitSystem
                             ) {

}
