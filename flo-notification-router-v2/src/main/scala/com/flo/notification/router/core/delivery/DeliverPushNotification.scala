package com.flo.notification.router.core.delivery

import java.time.OffsetDateTime

import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.localization.LocalizationService
import com.flo.notification.sdk.delivery.PushNotification
import com.flo.notification.sdk.model.{Alarm, SystemMode}

import scala.concurrent.{ExecutionContext, Future}

final private[core] class DeliverPushNotification(
    retrieveDeliveryMediumTemplate: DeliveryMediumTemplateRetriever,
    localizationService: LocalizationService,
    sendPushNotification: PushNotificationSender
)(implicit ec: ExecutionContext)
    extends Deliver {

  override def apply(alarmIncident: AlarmIncident,
                     device: Device,
                     user: User,
                     alarm: Alarm,
                     schedule: Option[OffsetDateTime]): Future[Unit] = {
    val deliveryMediumTemplate = retrieveDeliveryMediumTemplate(
      alarm.id,
      SystemMode.toString(alarmIncident.systemMode),
      PushNotificationMedium,
      user.account.accountType
    )

    localizationService.buildDefaultLocalizedArgs(alarmIncident, user, device).flatMap { localizationArgs =>
      val eventualLocalizedSubject = getLocalizedSubject(user, deliveryMediumTemplate, localizationArgs)
      val eventualLocalizedBody    = getLocalizedBody(user, deliveryMediumTemplate, localizationArgs)
      val eventualMetadata         = buildMetadata(device, alarmIncident, user, alarm)

      for {
        localizedSubject <- eventualLocalizedSubject
        localizedBody    <- eventualLocalizedBody
        metadata         <- eventualMetadata
      } yield
        sendPushNotification(
          buildDeliveryId(PushNotificationMedium, alarm.id, user.id, device.id, alarmIncident.id),
          PushNotification(
            alarmIncident.id,
            user.id,
            device.id,
            localizedSubject,
            localizedBody,
            GeneratePushNotificationToTag(alarm.id, 3),
            GeneratePushNotificationColor(alarm.severity),
            "com.flotechnologies.intent.action.INCIDENT",
            metadata
          ),
          schedule
        )
    }
  }

  private def getLocalizedSubject(user: User,
                                  deliveryMediumTemplate: DeliveryMediumTemplate,
                                  localizationArgs: Map[String, String]): Future[String] = {
    val assetNames = deliveryMediumTemplate.subject
      .map { s =>
        Set(Option(s.name), s.fallback).flatten
      }
      .getOrElse(Set())

    localizationService
      .retrieveLocalizedTexts(assetNames, localization.PushNotification, user.locale, localizationArgs)
      .map { localizedTexts =>
        deliveryMediumTemplate.subject
          .flatMap { s =>
            localizedTexts
              .get(s.name)
              .filterNot(_.isEmpty)
              .orElse {
                s.fallback.flatMap { fallback =>
                  localizedTexts.get(fallback)
                }
              }
          }
          .getOrElse("")
      }
  }

  private def getLocalizedBody(user: User,
                               deliveryMediumTemplate: DeliveryMediumTemplate,
                               localizationArgs: Map[String, String]): Future[String] = {
    val assetNames = Set(Option(deliveryMediumTemplate.body.name), deliveryMediumTemplate.body.fallback).flatten
    localizationService
      .retrieveLocalizedTexts(assetNames, localization.PushNotification, user.locale, localizationArgs)
      .map { localizedTexts =>
        localizedTexts
          .get(deliveryMediumTemplate.body.name)
          .filterNot(_.isEmpty)
          .orElse {
            deliveryMediumTemplate.body.fallback
              .flatMap { fallback =>
                localizedTexts.get(fallback)
              }
          }
          .getOrElse("")
      }
  }

  private def buildMetadata(device: Device,
                            alarmIncident: AlarmIncident,
                            user: User,
                            alarm: Alarm): Future[Map[String, Any]] =
    localizationService
      .retrieveLocalizedAlarmDisplayDescription(user.locale, alarm.id, SystemMode.toString(alarmIncident.systemMode))
      .map { description =>
        Map(
          "id" -> alarmIncident.id,
          "ts" -> alarmIncident.timestamp,
          "notification" -> Map(
            "alarm_id"    -> alarm.id,
            "name"        -> alarm.name,
            "severity"    -> alarm.severity,
            "description" -> description
          ),
          "icd" -> Map(
            "device_id"   -> device.macAddress,
            "time_zone"   -> alarmIncident.snapshot.tz.getOrElse(""),
            "system_mode" -> alarmIncident.systemMode,
            "icd_id"      -> device.id
          ),
          "version" -> 1
        )
      }
}
