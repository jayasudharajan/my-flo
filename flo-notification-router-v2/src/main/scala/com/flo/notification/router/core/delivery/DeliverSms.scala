package com.flo.notification.router.core.delivery

import java.time.OffsetDateTime

import com.flo.logging.logbookFor
import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.localization.LocalizationService
import com.flo.notification.router.core.delivery.DeliverSms.log
import com.flo.notification.sdk.model.{Alarm, SystemMode}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

final private[core] class DeliverSms(
    retrieveDeliveryMediumTemplate: DeliveryMediumTemplateRetriever,
    localizationService: LocalizationService,
    sendSms: SmsSender
)(implicit ec: ExecutionContext)
    extends Deliver {

  override def apply(alarmIncident: AlarmIncident,
                     device: Device,
                     user: User,
                     alarm: Alarm,
                     schedule: Option[OffsetDateTime]): Future[Unit] =
    user.phoneNumber match {
      case Some(phoneNumber) =>
        val deliveryMediumTemplate = retrieveDeliveryMediumTemplate(
          alarm.id,
          SystemMode.toString(alarmIncident.systemMode),
          SmsMedium,
          user.account.accountType
        )

        localizationService.buildDefaultLocalizedArgs(alarmIncident, user, device).flatMap { localizationArgs =>
          val assetNames = Set(Option(deliveryMediumTemplate.body.name), deliveryMediumTemplate.body.fallback).flatten
          localizationService
            .retrieveLocalizedTexts(assetNames, localization.Sms, user.locale, localizationArgs)
            .flatMap { localizedBodies =>
              val localizedBody = localizedBodies
                .get(deliveryMediumTemplate.body.name)
                .filterNot(_.isEmpty)
                .orElse {
                  deliveryMediumTemplate.body.fallback
                    .flatMap { fallback =>
                      localizedBodies.get(fallback)
                    }
                }
                .getOrElse("")

              sendSms(
                buildDeliveryId(SmsMedium, alarm.id, user.id, device.id, alarmIncident.id),
                Sms(alarmIncident.id, user.id, phoneNumber, localizedBody),
                schedule
              )
            }
        }

      case None =>
        log.info(
          p"Sms message for alarm ${alarm.id} will not be delivered to user ${user.id} due to missing phone number"
        )
        Future.unit
    }
}

private object DeliverSms {
  private val log = logbookFor(getClass)
}
