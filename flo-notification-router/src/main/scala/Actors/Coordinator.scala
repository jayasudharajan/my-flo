package Actors

import KafkaConsumers.{AlarmNotificationStatusConsumerActor, ExternalActionsConsumerActor, NotificationActorConsumer}
import Utils.ApplicationSettings
import akka.actor.{Actor, ActorLogging, OneForOneStrategy, SupervisorStrategy}
import akka.pattern.{Backoff, BackoffSupervisor}
import akka.stream.ActorMaterializer
import argonaut.Parse
import com.flo.Enums.Services.ServiceController
import com.flo.Models.KafkaMessages.{ICDAlarmIncident, ICDAlarmIncidentStatus}
import com.flo.Models.TelemetryCompact
import com.flo.communication.KafkaConsumer
import com.flo.communication.utils.KafkaConsumerMetrics
import kamon.Kamon

import scala.concurrent.duration._

class Coordinator extends Actor with ActorLogging {
  private val materializer = ActorMaterializer()(context)
  val system = context.system

  def receive = {
    case ServiceController.START =>
      log.info("Coordinator > receive > start")

      implicit val notificationConsumerMetrics = Kamon.metrics.entity(
        KafkaConsumerMetrics,
        ApplicationSettings.kafka.topic.get,
        tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
      )

      val kafkaConsumer = new KafkaConsumer(
        ApplicationSettings.kafka.host.get,
        ApplicationSettings.kafka.groupId.get,
        ApplicationSettings.kafka.topic.get,
        notificationConsumerMetrics,
        clientName = Some("kafka-consumer"),
        maxPollRecords = ApplicationSettings.kafka.maxPollRecords,
        pollTimeout = ApplicationSettings.kafka.pollTimeout
      )

      implicit val alarmNotificationStatusConsumerMetrics = Kamon.metrics.entity(
        KafkaConsumerMetrics,
        ApplicationSettings.kafka.alarmNotificationStatusTopic.get,
        tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
      )

      val kafkaConsumerAlarmNotificationStatus = new KafkaConsumer(
        ApplicationSettings.kafka.host.get,
        ApplicationSettings.kafka.groupId.get,
        ApplicationSettings.kafka.alarmNotificationStatusTopic.get,
        alarmNotificationStatusConsumerMetrics,
        maxPollRecords = 5,
        clientName = Some("alarm-notification-status")
      )

      implicit val externalActionsConsumerMetrics = Kamon.metrics.entity(
        KafkaConsumerMetrics,
        ApplicationSettings.kafka.externalActionsValveStatusTopic.get,
        tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
      )

      val externalActionsConsumerActor = new KafkaConsumer(
        ApplicationSettings.kafka.host.get,
        ApplicationSettings.kafka.groupId.get,
        ApplicationSettings.kafka.externalActionsValveStatusTopic.get,
        externalActionsConsumerMetrics,
        clientName = Some("external-actions"),
        maxPollRecords = ApplicationSettings.kafka.maxPollRecords,
        pollTimeout = ApplicationSettings.kafka.pollTimeout
      )
      val externalActionsValveStatusReader = ExternalActionsConsumerActor.props(
        externalActionsConsumerActor,
        m => Parse.decodeOption[TelemetryCompact](m).get,
        materializer,
        ApplicationSettings.kafka.filterTimeInSeconds
      )

      val notificationAlarmStatusReader = AlarmNotificationStatusConsumerActor.props(
        kafkaConsumerAlarmNotificationStatus,
        x => Parse.decodeOption[ICDAlarmIncidentStatus](x).get,
        materializer,
        ApplicationSettings.kafka.filterTimeInSeconds
      )

      val nReader = NotificationActorConsumer.props(
        kafkaConsumer,
        x => Parse.decodeOption[ICDAlarmIncident](x).get,
        materializer,
        ApplicationSettings.kafka.filterTimeInSeconds
      )
      val supervisor = BackoffSupervisor.props(
        Backoff.onStop(
          nReader,
          childName = "notification-consumer",
          minBackoff = 3.seconds,
          maxBackoff = 30.seconds,
          randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
        ).withSupervisorStrategy(
          OneForOneStrategy() {
            case ex =>
              log.error("There was an error in KafkaActor", ex)
              SupervisorStrategy.Restart //Here we can add some log or send a notification
          })
      )

      val supervisorAlarmNotificationStatus = BackoffSupervisor.props(
        Backoff.onStop(
          notificationAlarmStatusReader,
          childName = "notification-consumer-alarms-status",
          minBackoff = 3.seconds,
          maxBackoff = 30.seconds,
          randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
        ).withSupervisorStrategy(
          OneForOneStrategy() {
            case ex =>
              log.error("There was an error in KafkaActor", ex)
              SupervisorStrategy.Restart //Here we can add some log or send a notification
          })
      )

      val supervisorExternalActionsValveStatusReader = BackoffSupervisor.props(
        Backoff.onStop(
          childProps = externalActionsValveStatusReader,
          childName = "external-actions-valve-status-reader",
          minBackoff = 3.seconds,
          maxBackoff = 30.seconds,
          randomFactor = 0.2 // adds 20% "noise" to vary the intervals slightly
        ).withSupervisorStrategy(
          OneForOneStrategy() {
            case ex =>
              log.error("There was an error in KafkaActor", ex)
              SupervisorStrategy.Restart //Here we can add some log or send a notification
          })
      )

      system.actorOf(supervisor)
      system.actorOf(supervisorAlarmNotificationStatus)
      system.actorOf(supervisorExternalActionsValveStatusReader)
  }
}
