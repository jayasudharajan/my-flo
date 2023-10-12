package MicroService

import Models.CustomerService.RegularCSEmailForUserAlert
import Models.SubscriptionInfo
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.{ICD, ICDAlarmNotificationDeliveryRules, Location}
import com.flo.Models.Logs.ICDAlarmIncidentRegistry
import com.flo.Models.Users.{UserAlarmNotificationDeliveryRules, UserContactInformation}

class ZendeskService {
  def generateRegularCSEmailForUserAlert(
                                          icdAlarmNotificationDeliveryRules: Option[ICDAlarmNotificationDeliveryRules],
                                          iCD: ICD,
                                          userContactInformation: Option[UserContactInformation],
                                          icdLocation: Option[Location],
                                          createIcdIncidentRegistryRecord: ICDAlarmIncidentRegistry,
                                          incidentMessage: ICDAlarmIncident,
                                          userDeliveryRules: UserAlarmNotificationDeliveryRules,
                                          subscriptionInfo: Option[SubscriptionInfo],
                                          unitSystem: Option[MeasurementUnitSystem]
                                        ): RegularCSEmailForUserAlert = {
    RegularCSEmailForUserAlert(
      icdAlarmNotificationDeliveryRules,
      iCD,
      userContactInformation,
      icdLocation,
      createIcdIncidentRegistryRecord,
      incidentMessage,
      userDeliveryRules,
      subscriptionInfo,
      unitSystem
    )
  }


}
