package Models.Mediums

import Models.SubscriptionInfo
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.{AlarmNotificationDeliveryFilters, ICD, ICDAlarmNotificationDeliveryRules, Location}
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.UserAlarmNotificationDeliveryRules

case class PreProcessingMessage(
                                 ultimateAlarmNotificationDeliveryFilters: AlarmNotificationDeliveryFilters,
                                 createIcdIncidentRegistryRecord: Option[ICDAlarmIncidentRegistry],
                                 icdAlarmIncidentMessage: ICDAlarmIncident, icdLocation: Location,
                                 snapshot: ICDAlarmIncidentDataSnapshot,
                                 icdAlarmNotificationDeliveryRules: Option[ICDAlarmNotificationDeliveryRules],
                                 iCD: Option[ICD],
                                 userRules: UserAlarmNotificationDeliveryRules,
                                 hasUsersMutedAlarm: Boolean,
                                 isUserLandLord: Boolean,
                                 isUserTenant: Boolean,
                                 subscriptionInfo: Option[SubscriptionInfo],
                                 unitSystem: MeasurementUnitSystem
                               ) {}
