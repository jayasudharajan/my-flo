package Models.Mediums

import com.flo.Models.{AppDeviceNotificationInfo, ApplePushNotification, NotificationToken}

/**
	* Created by Francisco on 5/10/2016.
	*/
case class AppleMobileDeviceMessage(
	                                   notificationInfo: Option[Set[AppDeviceNotificationInfo]],
	                                   applePushNotification: Option[ApplePushNotification],
	                                   notificationTokens: Option[NotificationToken],
	                                   icdId: Option[String],
	                                   icdAlarmIncidentRegistryId: Option[String]
                                   ) {}
