package Models.Mediums

import com.flo.Models._
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.{UserAlarmNotificationDeliveryRules, UserContactInformation}

case class PushNotificationChoreographerMessage(
                                                 userDeliveryRules: UserAlarmNotificationDeliveryRules,
                                                 iCD: Option[ICD],
                                                 icdAlarmNotificationDeliveryRules: Option[ICDAlarmNotificationDeliveryRules],
                                                 createIcdIncidentRegistryRecord: Option[ICDAlarmIncidentRegistry],
                                                 icdAlarmIncidentMessage: ICDAlarmIncident,
                                                 location: Option[Location],
                                                 appDeviceInfo: Option[Set[AppDeviceNotificationInfo]],
                                                 userInfo: Option[UserContactInformation],
                                                 notificationTokens: Option[NotificationToken],
                                                 unitSystem: MeasurementUnitSystem
                                               ) {}
