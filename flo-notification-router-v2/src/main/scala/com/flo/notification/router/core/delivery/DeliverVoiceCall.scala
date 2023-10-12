package com.flo.notification.router.core.delivery

import java.time.OffsetDateTime

import com.flo.json4s.SimpleSerialization
import com.flo.logging.logbookFor
import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.localization.LocalizationService
import com.flo.notification.router.core.delivery.DeliverVoiceCall.log
import com.flo.notification.sdk.model.{Alarm, SystemMode}
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

final private[core] class DeliverVoiceCall(
    retrieveDeliveryMediumTemplate: DeliveryMediumTemplateRetriever,
    localizationService: LocalizationService,
    sendCall: VoiceCallSender,
    voiceScriptUrlGenerator: VoiceScriptUrlGenerator,
    voiceStatusCallbackUrlGenerator: VoiceStatusCallbackUrlGenerator
)(implicit ec: ExecutionContext)
    extends Deliver
    with SimpleSerialization {

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
          VoiceCallMedium,
          user.account.accountType
        )

        val assetNames = Set(Option(deliveryMediumTemplate.body.name), deliveryMediumTemplate.body.fallback).flatten
        val eventualLocalizedMessages =
          localizationService.buildDefaultLocalizedArgs(alarmIncident, user, device).flatMap { localizationArgs =>
            localizationService.retrieveLocalizedTexts(
              assetNames,
              localization.VoiceCall,
              user.locale,
              localizationArgs
            )
          }

        val eventualLocalizedMessage = eventualLocalizedMessages.map { localizedMessages =>
          localizedMessages
            .get(deliveryMediumTemplate.body.name)
            .filterNot(_.isEmpty)
            .orElse {
              deliveryMediumTemplate.body.fallback
                .flatMap { fallback =>
                  localizedMessages.get(fallback)
                }
            }
            .getOrElse("")
        }

        for {
          localizedMessage <- eventualLocalizedMessage
          voiceScript <- voiceScriptUrlGenerator(
                          user.id,
                          localizedMessage,
                          alarmIncident.id,
                          alarmIncident.systemMode,
                          user.locale,
                          user.isTenant
                        )
        } yield {
          val callMessage = CallMessage(
            None,
            phoneNumber,
            voiceScript,
            voiceStatusCallbackUrlGenerator(user.id, alarmIncident.id),
            Some(
              MetaData(
                device.macAddress,
                device.id,
                user.id,
                alarm.id,
                alarmIncident.systemMode,
                alarmIncident.id
              )
            )
          )

          sendCall(
            buildDeliveryId(VoiceCallMedium, alarm.id, user.id, device.id, alarmIncident.id),
            VoiceCall(
              alarmIncident.id,
              serializeToSnakeCase(callMessage),
              VoiceCallData(
                "notification-router-v2",
                alarm.severity
              )
            ),
            schedule
          )
        }

      case None =>
        log.info(p"Voice call for alarm ${alarm.id} will not be made to user ${user.id} due to missing phone number")
        Future.unit
    }
}

private object DeliverVoiceCall {
  private val log = logbookFor(getClass)
}
