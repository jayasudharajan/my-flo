package com.flo.notification.router.core.filter

import ca.mrvisser.sealerate.values
import cats.data.NonEmptyList
import com.flo.logging.logbookFor
import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

final private class DeliverySettingsFilter(retrieveDeliverySettings: DeliverySettingsRetriever)(
    implicit ec: ExecutionContext
) extends AlarmIncidentFilter {

  import DeliverySettingsFilter.log

  override def apply(alarmIncident: AlarmIncident, alarm: Alarm, user: User, device: Device): Future[FilterResult] =
    retrieveDeliverySettings(user, device.id, alarm.id, alarmIncident.systemMode).map {

      case None =>
        log.error(
          p"No Delivery Settings found for UserId=${user.id}, DeviceId=${device.id}, " +
            p"AlarmId=${alarm.id}, SystemMode=${alarmIncident.systemMode}"
        )
        NoMediumsAllowed(DeliverySettingsNotFound)

      case Some(deliverySettings) =>
        log.debug(
          p"Delivery Settings found for UserId=${user.id}, DeviceId=${device.id} " +
            p"AlarmId=${alarm.id}, SystemMode=${alarmIncident.systemMode} => $deliverySettings"
        )

        allowedDeliveryMediums(deliverySettings)
    }

  private def allowedDeliveryMediums(deliverySettings: DeliverySettings): FilterResult = {
    val sms: List[DeliveryMedium]       = if (deliverySettings.sms) List(SmsMedium) else List()
    val email: List[DeliveryMedium]     = if (deliverySettings.email) List(EmailMedium) else List()
    val voiceCall: List[DeliveryMedium] = if (deliverySettings.voiceCall) List(VoiceCallMedium) else List()
    val push: List[DeliveryMedium]      = if (deliverySettings.pushNotification) List(PushNotificationMedium) else List()

    NonEmptyList.fromList(sms ++ email ++ voiceCall ++ push).map(_.toNes) match {
      case None                                                                        => NoMediumsAllowed(DeliverySettingsNoMediumsAllowed)
      case Some(allowedMediums) if allowedMediums.length < values[DeliveryMedium].size => AllowedMediums(allowedMediums)
      case _                                                                           => AllMediumsAllowed
    }
  }

}

object DeliverySettingsFilter {
  private val log = logbookFor(getClass)
}
