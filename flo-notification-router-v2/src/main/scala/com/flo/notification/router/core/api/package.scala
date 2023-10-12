package com.flo.notification.router.core

import java.time.{LocalDateTime, OffsetDateTime}

import com.flo.Models.KafkaMessages.EmailFeatherMessage
import com.flo.notification.router.core.api.activity.EntityActivity
import com.flo.notification.sdk.delivery.PushNotification
import com.flo.notification.sdk.model.{Alarm, Incident, UserAlarmSettings}

import scala.concurrent.Future

package object api {
  type UserId           = String
  type MacAddress       = String
  type DeviceId         = String
  type AlarmId          = Int
  type SystemMode       = Int
  type SystemModeName   = String
  type RequestId        = String
  type AlarmIncidentId  = String
  type Message          = String
  type DeliveryMediumId = Int
  type LocationId       = String
  type AccountId        = String
  type GroupId          = String
  type SeverityId       = Int
  type Locale           = String
  type HealthTestId     = String
  type Json             = io.circe.Json

  type AlarmIncidentProcessor = AlarmIncident => Future[Unit]
  type AlertStatusProcessor   = Alert => Future[Unit]
  type ResumeOnExceptions     = Set[Class[_ <: Throwable]]

  type LatestHealthTestByDeviceIdRetriever = DeviceId => Future[Option[HealthTest]]
  type HealthTestByDeviceIdRetriever       = (DeviceId, HealthTestId) => Future[Option[HealthTest]]
  type UsersByMacAddressRetriever          = MacAddress => Future[Option[DeviceUsers]]
  type AlarmRetriever                      = AlarmId => Future[Option[Alarm]]
  type DeliverySettingsRetriever           = (User, DeviceId, AlarmId, SystemMode) => Future[Option[DeliverySettings]]
  type DeliveryMediumTemplateRetriever =
    (AlarmId, SystemModeName, DeliveryMedium, AccountType) => DeliveryMediumTemplate
  type DoNotDisturbSettingsRetriever = UserId => Future[Option[DoNotDisturbSettings]]
  type UserAlarmSettingsRetriever    = (UserId, DeviceId) => Future[Option[UserAlarmSettings]]

  type VoiceScriptUrlGenerator         = (UserId, Message, AlarmIncidentId, SystemMode, Locale, Boolean) => Future[String]
  type VoiceStatusCallbackUrlGenerator = (UserId, AlarmIncidentId) => String

  type EmailSender            = (String, EmailFeatherMessage, Option[OffsetDateTime]) => Future[Unit]
  type VoiceCallSender        = (String, VoiceCall, Option[OffsetDateTime]) => Future[Unit]
  type PushNotificationSender = (String, PushNotification, Option[OffsetDateTime]) => Future[Unit]
  type SmsSender              = (String, Sms, Option[OffsetDateTime]) => Future[Unit]
  type DeliveryCancel         = (DeliveryMedium, AlarmId, UserId, DeviceId, AlarmIncidentId) => Future[Unit]

  type RegisterDeliveryMediumTriggered = (AlarmIncidentId, DeliveryMediumId, UserId) => Future[Unit]
  type RegisterIncident                = IncidentInfo => Future[Unit]
  type HealthTestRelatedAlarmsResolver = DeviceId => Future[Unit]
  type SnoozeTimeRetriever             = (AlarmId, DeviceId, LocationId, UserId) => Future[Option[LocalDateTime]]
  type FrequencyCapExpirationRetriever = (AlarmId, DeviceId, UserId) => Future[Option[LocalDateTime]]

  type AlarmIncidentScheduler = (DeviceId, AlarmIncident, LocalDateTime) => Future[Unit]

  type EntityActivityProcessor       = EntityActivity => Future[Unit]
  type PendingAlertResolver          = (DeviceId, FilterReason) => Future[Unit]
  type PendingAlertsForAlarmResolver = (DeviceId, AlarmId, FilterReason) => Future[Seq[Incident]]
  type AlarmIncidentConverter        = (Alert, Incident) => AlarmIncident
  type DeviceDataCleanUp             = (DeviceId) => Future[Unit]

  // Private API
  private[core] type AlarmIncidentDelivery = (AlarmIncident, Alarm, User, Device, DeliverySettings) => Future[Unit]
  private[core] type AlarmIncidentFilter   = (AlarmIncident, Alarm, User, Device) => Future[FilterResult]
  // TODO: Find less misleading names.
  private[core] type AlarmIncidentReScheduler = (FilterReason, User, AlarmIncident, Device) => Future[Unit]
}
