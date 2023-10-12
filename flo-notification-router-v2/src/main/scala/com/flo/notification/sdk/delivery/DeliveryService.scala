package com.flo.notification.sdk.delivery

import java.time.LocalTime
import java.util.UUID

import com.flo.notification.router.core.api._
import com.flo.notification.sdk.service.NotificationService
import com.flo.util.TypeConversions.Uuid._
import com.github.blemale.scaffeine.{Cache, Scaffeine}
import perfolation._

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}

final private[sdk] class DeliveryService(
    notificationService: NotificationService,
    retrieveHierarchyAwareDeliverySettings: (UserId, DeviceId) => Future[Seq[AlarmSystemModeDeliverySettings]]
)(implicit val ex: ExecutionContext) {

  private val deliverySettingsCache: Cache[String, Seq[AlarmSystemModeDeliverySettings]] =
    Scaffeine()
      .recordStats()
      .expireAfterWrite(2.minutes)
      .maximumSize(500)
      .build[String, Seq[AlarmSystemModeDeliverySettings]]()

  def retrieveDeliverySettings(user: User,
                               deviceId: DeviceId,
                               alarmId: AlarmId,
                               systemMode: SystemMode): Future[Option[DeliverySettings]] = {

    val cacheKey = {
      if (user.isLandLord) p"${user.id}_landlord"
      else p"${user.id}_$deviceId"
    }

    val settings = deliverySettingsCache.getIfPresent(cacheKey) match {
      case Some(settings) => Future.successful(settings)
      case None =>
        val result = if (user.isLandLord) {
          // TODO: right now users have one role in the group, but if they have more than one they should just one
          // associated with the NR so we do not send notifications more than once due to multiple roles
          notificationService
            .getGroupRoleDeliverySettings(
              UUID.fromString(user.groupId.get),
              user.roles.headOption.getOrElse("")
            )
            .map(
              settings =>
                settings
                  .map(
                    setting =>
                      AlarmSystemModeDeliverySettings(
                        setting.alarmId,
                        setting.systemMode,
                        setting.settings.smsEnabled.getOrElse(false),
                        setting.settings.emailEnabled.getOrElse(false),
                        setting.settings.pushEnabled.getOrElse(false),
                        setting.settings.callEnabled.getOrElse(false),
                        isMuted = false
                    )
                )
            )
        } else {
          retrieveHierarchyAwareDeliverySettings(user.id, deviceId)
        }

        result.foreach(deliverySettingsCache.put(cacheKey, _))

        result
    }

    settings.map { alertSettingsList =>
      alertSettingsList
        .withFilter { alertSettings =>
          alertSettings.alarmId == alarmId && alertSettings.systemMode == systemMode
        }
        .map { alertSettings =>
          alertSettings.deliverySettings
        }
        .headOption
    }
  }

  def retrieveDeliveryMediumTemplate(alarmId: AlarmId,
                                     systemMode: String,
                                     deliveryMedium: DeliveryMedium,
                                     accountType: AccountType): DeliveryMediumTemplate = {

    val baseTemplate        = p"nr.alarm.$alarmId.$systemMode"
    val baseBodyTemplate    = p"$baseTemplate.template"
    val baseSubjectTemplate = p"$baseTemplate.subject"

    val bodyTemplate = accountType match {
      case Enterprise => NameAndFallback(p"$baseBodyTemplate.enterprise", Some(baseBodyTemplate))
      case _          => NameAndFallback(p"$baseBodyTemplate", None)
    }

    val subject = accountType match {
      case Enterprise => NameAndFallback(p"$baseSubjectTemplate.enterprise", Some(baseSubjectTemplate))
      case _          => NameAndFallback(p"$baseSubjectTemplate", None)
    }

    deliveryMedium match {
      case PushNotificationMedium => DeliveryMediumTemplate(bodyTemplate, Some(subject))
      case _                      => DeliveryMediumTemplate(bodyTemplate, None)
    }
  }

  def retrieveDoNotDisturbSettings(
      userId: UserId
  ): Future[Option[DoNotDisturbSettings]] =
    notificationService.getUserGraveyardTime(userId).map { maybeUserGraveyardTime =>
      maybeUserGraveyardTime.map { userGraveyardTime =>
        DoNotDisturbSettings(
          startsAt = LocalTime.parse(userGraveyardTime.startsAt),
          endsAt = LocalTime.parse(userGraveyardTime.endsAt),
          allowEmail = userGraveyardTime.allowEmail,
          allowSms = userGraveyardTime.allowSms,
          allowPushNotification = userGraveyardTime.allowPush,
          allowVoiceCall = userGraveyardTime.allowCall,
          allowedSeverities = userGraveyardTime.whenSeverityIs.split(',').map(_.toInt).toSet
        )
      }
    }

}
