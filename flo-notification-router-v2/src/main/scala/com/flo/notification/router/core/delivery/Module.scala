package com.flo.notification.router.core.delivery

import java.time.Clock

import com.flo.notification.router.conf._
import com.flo.notification.router.core.api.localization.LocalizationService
import com.flo.notification.router.core.api.{UserId, _}
import com.typesafe.config.Config

import scala.concurrent.{ExecutionContext, Future}

trait Module {
  // Requires
  def defaultExecutionContext: ExecutionContext
  def appConfig: Config
  def defaultClock: Clock
  def emailSender: EmailSender
  def voiceCallSender: VoiceCallSender
  def pushNotificationSender: PushNotificationSender
  def smsSender: SmsSender
  def retrieveDeliveryMediumTemplate: DeliveryMediumTemplateRetriever
  def localizationService: LocalizationService
  def voiceScriptUrlGenerator: VoiceScriptUrlGenerator
  def voiceStatusCallbackUrlGenerator: VoiceStatusCallbackUrlGenerator
  def registerDeliveryMediumTriggered: RegisterDeliveryMediumTriggered
  def retrieveDoNotDisturbSettings: DoNotDisturbSettingsRetriever
  def cancelScheduledTask(id: String): Future[Unit]

  // Private
  private val defaultDndSettings = appConfig.as[DoNotDisturbSettings]("alarm-filters.default-do-not-disturb-settings")

  // TODO: Move this out?
  private val emailCallbackHook = appConfig.as[String]("email.callback-hook")
  private def buildCallbackHook(alarmIncidentId: AlarmIncidentId, userId: UserId): String =
    emailCallbackHook
      .replace(":incidentId", alarmIncidentId)
      .replace(":userId", userId)

  private val doNotDisturbScheduleGenerator = new DoNotDisturbScheduleGenerator(
    defaultClock,
    retrieveDoNotDisturbSettings,
    defaultDndSettings,
    localizationService.getTimeZone
  )(defaultExecutionContext)

  private val deliveryService: DeliveryService = new DeliveryService {
    override def deliverEmail: Deliver =
      new DeliverEmail(
        retrieveDeliveryMediumTemplate,
        localizationService,
        buildCallbackHook,
        emailSender
      )(defaultExecutionContext)

    override def deliverVoiceCall: Deliver =
      new DeliverVoiceCall(
        retrieveDeliveryMediumTemplate,
        localizationService,
        voiceCallSender,
        voiceScriptUrlGenerator,
        voiceStatusCallbackUrlGenerator
      )(defaultExecutionContext)

    override def deliverPushNotification: Deliver =
      new DeliverPushNotification(
        retrieveDeliveryMediumTemplate,
        localizationService,
        pushNotificationSender
      )(defaultExecutionContext)

    override def deliverSms: Deliver =
      new DeliverSms(
        retrieveDeliveryMediumTemplate,
        localizationService,
        smsSender
      )(defaultExecutionContext)
  }

  // Provides
  val deliverAlarmIncident: AlarmIncidentDelivery =
    new DeliverAlarmIncident(
      deliveryService,
      registerDeliveryMediumTriggered,
      doNotDisturbScheduleGenerator
    )(
      defaultExecutionContext
    )

  val cancelDelivery: DeliveryCancel = (deliveryMedium: DeliveryMedium,
                                        alarmId: AlarmId,
                                        userId: UserId,
                                        deviceId: DeviceId,
                                        incidentId: AlarmIncidentId) => {
    val id = buildDeliveryId(deliveryMedium, alarmId, userId, deviceId, incidentId)
    cancelScheduledTask(id)
  }
}
