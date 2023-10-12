package Models.Mediums

import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.{ICD, ICDAlarmNotificationDeliveryRules, Location}
import com.flo.Models.Users.UserContactInformation

case class EmailChoreographerMessage(
                                      icdAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules,
                                      icdAlarmIncidentMessage: ICDAlarmIncident,
                                      createIcdIncidentRegistryRecord: ICDAlarmIncidentRegistry,
                                      iCd: Option[ICD],
                                      icdLocation: Option[Location],
                                      userInfo: Option[UserContactInformation],
                                      unitSystem: MeasurementUnitSystem
                                    ) {

}
