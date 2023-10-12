package com.flo.notification.router.core

import java.time.OffsetDateTime

import com.flo.notification.router.core.api.{
  AlarmId,
  AlarmIncident,
  AlarmIncidentId,
  DeliveryMedium,
  Device,
  DeviceId,
  User,
  UserId
}
import com.flo.notification.sdk.model.Alarm
import perfolation._

import scala.concurrent.Future

package object delivery {
  private[delivery] type Deliver = (AlarmIncident, Device, User, Alarm, Option[OffsetDateTime]) => Future[Unit]

  private[delivery] def buildDeliveryId(deliveryMedium: DeliveryMedium,
                                        alarmId: AlarmId,
                                        userId: UserId,
                                        deviceId: DeviceId,
                                        incidentId: AlarmIncidentId): String =
    p"${deliveryMedium.toString}-$alarmId-$userId-$deviceId-$incidentId"

  private[delivery] trait DeliveryService {
    def deliverEmail: Deliver
    def deliverVoiceCall: Deliver
    def deliverPushNotification: Deliver
    def deliverSms: Deliver
  }
}
