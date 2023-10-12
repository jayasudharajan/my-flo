package Models.Actors

import Models.SubscriptionInfo
import com.flo.Models.Analytics.DeviceInfo
import com.flo.Models.Locale.MeasurementUnitSystem
import com.flo.Models.Users.{UserAccountGroupRole, UserAlarmNotificationDeliveryRules}
import com.flo.Models._

class RudimentaryIncidentInfo(
                               val deliveryRules: ICDAlarmNotificationDeliveryRules,
                               val icd: Option[ICD],
                               val icdUsersIds: Option[Set[String]],
                               val userAlarmNotificationDeliveryRules: Option[Set[UserAlarmNotificationDeliveryRules]],
                               val alarmNotificationDeliveryFilters: Option[AlarmNotificationDeliveryFilters],
                               val icdLocation: Option[Location],
                               val deviceInfo: Option[DeviceInfo],
                               val usersAccountGroupRoles: Option[Set[UserAccountGroupRole]],
                               val accountGroupDeliveryRules: Option[Set[AccountGroupAlarmNotificationDeliveryRule]],
                               val subscriptionInfo: Option[SubscriptionInfo],
                               val unitSystem: MeasurementUnitSystem
                             ) {

}
