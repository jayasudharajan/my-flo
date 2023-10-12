package Models.Mediums

import com.flo.Models.ICDAlarmNotificationDeliveryRules
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.UserContactInformation

case class SMSChoreographerMessage(
                                    icdAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules,
                                    icdAlarmIncidentMessage: ICDAlarmIncident,
                                    createIcdIncidentRegistryRecord: ICDAlarmIncidentRegistry,
                                    userInfo: Option[UserContactInformation],
                                    unitSystem: MeasurementUnitSystem
                                  ) {}
