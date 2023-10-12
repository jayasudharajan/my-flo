package Models.Mediums

import com.flo.Models.Android.PushNotification
import com.flo.Models.{AppDeviceNotificationInfo, NotificationToken}

/**
	* Created by Francisco on 2/24/2017.
	*/
case class AndroidMobileDeviceMessage(
	                                     notificationInfo: Option[Set[AppDeviceNotificationInfo]],
	                                     androidPushNotification: Option[PushNotification],
	                                     notificationTokens: Option[NotificationToken],
	                                     icdId: Option[String],
	                                     icdAlarmIncidentRegistryId: Option[String]
                                     ) {}

