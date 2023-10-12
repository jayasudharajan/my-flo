package KafkaConsumers

import Actors.NotificationDelivery.DeliveryPreProcessing
import Actors._
import Utils.ApplicationSettings
import akka.actor.{ActorRef, OneForOneStrategy, Props, SupervisorStrategy}
import akka.routing.RoundRobinPool
import akka.stream.{ActorMaterializer, Materializer}
import com.flo.Enums.ValveModes
import com.flo.FloApi.v2.Abstracts.FloTokenProviders
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.{ICDAlarmIncidentData, ICDAlarmIncidentDataAlarm, ICDAlarmIncidentDataSnapshot}
import com.flo.Models.KafkaMessages.ICDAlarmIncident
import com.flo.communication.IKafkaConsumer
import com.flo.utils.{FromCamelToSneakCaseSerializer, HttpMetrics}
import kamon.Kamon
import Actors.NotificationDelivery.MediumsChoreographer
import kamon.metric.instrument.Counter.Snapshot


/**
  * This actor is reposible for dequeueing kafka messages regarding
  * alarm notifications for users.
  */

class NotificationActorConsumer(
                                 kafkaConsumer: IKafkaConsumer,
                                 deserializer: String => ICDAlarmIncident,
                                 materializer: Materializer,
                                 filterTimeInSeconds: Int
                               )
  extends KafkaActorConsumer[ICDAlarmIncident](kafkaConsumer, deserializer, filterTimeInSeconds) {

  implicit val mt = ActorMaterializer()(context)
  implicit val system = context.system

  implicit val httpMetrics = Kamon.metrics.entity(
    HttpMetrics,
    "flo-api",
    tags = Map("service-name" -> ApplicationSettings.kafka.groupId.get)
  )
  val clientCredentialsTokenProvider = FloTokenProviders.getClientCredentialsProvider()

  val kafkaReaderWorkers = ApplicationSettings.floActors.numberOfWorkers.kafkaReader.getOrElse(throw new IllegalArgumentException("flo-actors.numbers-ofworkers.kafka-reader was not found in config or environmental variables"))
  val kafkaProducerWorkers = ApplicationSettings.floActors.numberOfWorkers.kafkaProducer.getOrElse(throw new IllegalArgumentException("flo-actors.numbers-ofworkers.kafka-producer was not found in config or environmental variables"))


  val producer = context.system.actorOf(RoundRobinPool(kafkaProducerWorkers).props(KafkaProducer.props(materializer)))


  val decisionEngineWorkers = ApplicationSettings
    .floActors.numberOfWorkers
    .decisionEngine
    .getOrElse(throw new IllegalArgumentException("flo-actors.numbers-ofworkers.decision-engine was not found in config or environmental variables"))
  val csActor = context.system.actorOf(RoundRobinPool(10).props(CustomerService.props(producer)))

  val choreographer = context.system.actorOf(RoundRobinPool(10).props(MediumsChoreographer.props(producer)))

  val preDelivery = context.system.actorOf(RoundRobinPool(10).props(DeliveryPreProcessing.props(producer, choreographer, csActor)))

  val decisionEngine = context
    .system
    .actorOf(RoundRobinPool(decisionEngineWorkers).props(DecisionEngine.props(preDelivery)))

  val scheduledNotifications: ActorRef = context.system.actorOf(ScheduledNotifications.props(preDelivery))

  val serializer = new FromCamelToSneakCaseSerializer

  val notificationLogger = context
    .system
    .actorOf(RoundRobinPool(decisionEngineWorkers).props(
      NotificationLogger.props(csActor)
    ))

  override def supervisorStrategy = OneForOneStrategy() {
    case (ex: Throwable) => log.error(ex, "NotificationActorSuperV")
      SupervisorStrategy.restart
  }

  def consume(kafkaMessage: ICDAlarmIncident): Unit = {
    kafkaMessage match {
      case csAlarm if csAlarm.data.alarm.alarmId >= 5000 =>
        csActor ! csAlarm

      case ICDAlarmIncident(_, _, _, ICDAlarmIncidentData(alarm, snapshot), _, _, _) if shouldBeLogged(alarm, snapshot) =>
        notificationLogger ! kafkaMessage

      case scheduled: ICDAlarmIncident if scheduled.scheduledNotificationInfo.isDefined && scheduled.scheduledNotificationInfo.nonEmpty =>
        scheduledNotifications ! scheduled

      case _ => decisionEngine ! checkIncidentData(kafkaMessage)
    }
  }

  private def shouldBeLogged(alarm: ICDAlarmIncidentDataAlarm, snapshot: ICDAlarmIncidentDataSnapshot): Boolean = {
    snapshot.systemMode.getOrElse(0) == ValveModes.MANUAL &&
      !ApplicationSettings.flo.alarmSettings.especialTrashAlertsWithSleepModeDefinition.contains(alarm.alarmId) &&
      !ApplicationSettings.flo.alertsWithSleepModeDefinitions.contains(alarm.alarmId)
  }

  private def checkIncidentData(incident: ICDAlarmIncident): ICDAlarmIncident = {
    val snapshot = incident.data.snapshot
    if (checkNegativeInts(Set[Option[Int]](snapshot.valveSwitch1, snapshot.valveSwitch2))) {
      val snapshotCopy = snapshot.copy(valveSwitch1 = Some(1), valveSwitch2 = Some(0))
      incident.copy(data = incident.data.copy(snapshot = snapshotCopy))
    } else {
      incident
    }
  }

  private def checkNegativeInts(ints: Set[Option[Int]]): Boolean = {
    var hasNegative = false
    ints.foreach { i =>
      if (i.getOrElse(0) < 0)
        hasNegative = true
    }
    hasNegative
  }


}

object NotificationActorConsumer {
  def props(
             kafkaConsumer: IKafkaConsumer,
             deserializer: String => ICDAlarmIncident,
             materializer: Materializer,
             filterTimeInSeconds: Int
           ): Props = Props(classOf[NotificationActorConsumer], kafkaConsumer, deserializer, materializer, filterTimeInSeconds)
}