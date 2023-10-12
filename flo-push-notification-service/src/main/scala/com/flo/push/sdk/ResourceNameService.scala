package com.flo.push.sdk

import com.flo.Enums.Apps.{DeviceNotificationStatus, DevicePlatFormNames}
import com.flo.FloApi.v2.AppDeviceNotificationInfoEnpoints
import com.flo.Models.AppDeviceNotificationInfo
import org.joda.time.{DateTime, DateTimeZone}

import scala.concurrent.{ExecutionContext, Future}

class ResourceNameService(appDeviceNotificationInfoEndpoints: AppDeviceNotificationInfoEnpoints)
                         (implicit ec: ExecutionContext) {

  def retrieveEndpoint(userId: String, deviceId: String, token: String): Future[Option[String]] = {
    appDeviceNotificationInfoEndpoints
      .GetByUserIdAndIcdId(userId, deviceId)
      .map(_.getOrElse(Nil).find(info => info.registrationToken.contains(token)).map(_.endpointArn.get))
  }

  def storeEndpoint(userId: String, deviceId: String, platformArn: String, endpointArn: String, token: String): Future[Boolean] = {
    val platform =
      if (platformArn.contains("GCM") || platformArn.contains("FCM"))
        DevicePlatFormNames.ANDROID_PHONE
      else
        DevicePlatFormNames.APPLE_IPHONE

    // write endpoint arn to permanent storage
    appDeviceNotificationInfoEndpoints
      .Post(
        Some(
          AppDeviceNotificationInfo(
            id = Some(java.util.UUID.randomUUID().toString),
            ts = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            tsUpdated = Some(DateTime.now(DateTimeZone.UTC).toDateTimeISO.toString()),
            icdId = Some(deviceId),
            userId = Some(userId),
            platform = Some(platform),
            platformArn = Some(platformArn),
            endpointArn = Some(endpointArn),
            status = Some(DeviceNotificationStatus.OK),
            statusMessage = None,
            registrationToken = Some(token),
            isDeleted = Some(false)
          )
        )
      )
      .map(_ => true)
  }
}
