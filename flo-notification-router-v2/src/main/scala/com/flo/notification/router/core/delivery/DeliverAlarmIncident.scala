package com.flo.notification.router.core.delivery

import com.flo.notification.router.core.api._
import com.flo.notification.sdk.model.Alarm
import com.flo.logging.logbookFor
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class DeliverAlarmIncident(
    deliveryService: DeliveryService,
    registerDeliveryMediumTriggered: RegisterDeliveryMediumTriggered,
    doNotDisturbScheduleGenerator: DoNotDisturbScheduleGenerator
)(implicit ec: ExecutionContext)
    extends AlarmIncidentDelivery {

  import DeliverAlarmIncident.log

  override def apply(alarmIncident: AlarmIncident,
                     alarm: Alarm,
                     user: User,
                     device: Device,
                     deliverySettings: DeliverySettings): Future[Unit] = {

    val eventualCall =
      executeIfTrue(
        deliverySettings.voiceCall,
        withLogs(alarmIncident, VoiceCallMedium, user, device, alarm, deliveryService.deliverVoiceCall)
      )

    val eventualEmail =
      executeIfTrue(
        deliverySettings.email,
        withLogs(alarmIncident, EmailMedium, user, device, alarm, deliveryService.deliverEmail)
      )

    val eventualPush =
      executeIfTrue(
        deliverySettings.pushNotification,
        withLogs(alarmIncident, PushNotificationMedium, user, device, alarm, deliveryService.deliverPushNotification)
      )

    val eventualSms =
      executeIfTrue(
        deliverySettings.sms,
        withLogs(alarmIncident, SmsMedium, user, device, alarm, deliveryService.deliverSms)
      )

    eventualCall.failed.foreach { t =>
      log.warn(p"Voice call delivery failed for incident ${alarmIncident.id}", t)
    }

    eventualEmail.failed.foreach { t =>
      log.warn(p"Email delivery failed for incident ${alarmIncident.id}", t)
    }

    eventualPush.failed.foreach { t =>
      log.warn(p"Push notification delivery failed for incident ${alarmIncident.id}", t)
    }

    eventualSms.failed.foreach { t =>
      log.warn(p"Sms delivery failed for incident ${alarmIncident.id}", t)
    }

    Future
      .sequence(Seq(eventualCall, eventualEmail, eventualPush, eventualSms))
      .map(_ => ())
  }

  private def executeIfTrue(condition: Boolean, thunk: => Future[Unit]): Future[Unit] =
    if (condition) thunk
    else Future.unit

  private def withLogs(alarmIncident: AlarmIncident,
                       deliveryMedium: DeliveryMedium,
                       user: User,
                       device: Device,
                       alarm: Alarm,
                       thunk: => Deliver): Future[Unit] = {

    log.info(p"Triggering $deliveryMedium for User=${user.id}, Device=${device.id}, Incident=${alarmIncident.id}")

    doNotDisturbScheduleGenerator.getMediumSchedule(alarm, user, device, deliveryMedium).flatMap { schedule =>
      thunk(alarmIncident, device, user, alarm, schedule).flatMap { _ =>
        log.info(p"$deliveryMedium triggered for User=$user.id, Device=$device.id, Incident=${alarmIncident.id}")
        registerDeliveryMediumTriggered(alarmIncident.id, deliveryMedium.getId, user.id)
      }
    }
  }
}

object DeliverAlarmIncident {
  private val log = logbookFor(getClass)
}
