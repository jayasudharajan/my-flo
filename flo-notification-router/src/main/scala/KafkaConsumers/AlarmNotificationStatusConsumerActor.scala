package KafkaConsumers

import Actors.NotificationDelivery.{DeliveryPreProcessing, MediumsChoreographer}
import Actors.{AlarmNotificationStatusReviser, CustomerService, DecisionEngine, KafkaProducer}
import Utils.ApplicationSettings
import akka.actor.{ActorRef, OneForOneStrategy, Props, SupervisorStrategy}
import akka.routing.RoundRobinPool
import akka.stream.Materializer
import com.flo.Models.KafkaMessages.ICDAlarmIncidentStatus
import com.flo.communication.IKafkaConsumer

/**
  * Created by Francisco on 10/19/2016.
  */
/**
  * This actor function is to dequeue messages from kafka meant to update
  * the status of an alarm notification that has self-resolved.
  **/
class AlarmNotificationStatusConsumerActor(
                                            kafkaConsumer: IKafkaConsumer,
                                            deserializer: String => ICDAlarmIncidentStatus,
                                            materializer: Materializer,
                                            filterTimeInSeconds: Int
                                          ) extends KafkaActorConsumer[ICDAlarmIncidentStatus](kafkaConsumer, deserializer, filterTimeInSeconds) {

  val kafkaProducerWorkers = ApplicationSettings.floActors.numberOfWorkers.kafkaProducer.getOrElse(throw new IllegalArgumentException("flo-actors.numbers-ofworkers.kafka-producer was not found in config or environmental variables"))


  val producer = context.system.actorOf(RoundRobinPool(kafkaProducerWorkers).props(KafkaProducer.props(materializer)))
  val csActor = context.system.actorOf(RoundRobinPool(5).props(CustomerService.props(producer)))


  val decisionEngineWorkers = ApplicationSettings
    .floActors.numberOfWorkers
    .decisionEngine
    .getOrElse(throw new IllegalArgumentException("flo-actors.numbers-ofworkers.decision-engine was not found in config or environmental variables"))
  val choreographer = context.system.actorOf(RoundRobinPool(5).props(MediumsChoreographer.props(producer)))

  val preDelivery = context.system.actorOf(RoundRobinPool(5).props(DeliveryPreProcessing.props(producer, choreographer, csActor)))

  val decisionEngine = context
    .system
    .actorOf(RoundRobinPool(decisionEngineWorkers).props(DecisionEngine.props( preDelivery)))

  val alarmNotificationStatusReviser: ActorRef = context.system.actorOf(RoundRobinPool(10).props(AlarmNotificationStatusReviser.props(decisionEngine)))

  override def supervisorStrategy = OneForOneStrategy() {
    case (ex: Throwable) => log.error(ex, "AlarmNotificationStatusConsumerSuperV")
      SupervisorStrategy.restart
  }

  def consume(kafkaMessage: ICDAlarmIncidentStatus): Unit = {
    alarmNotificationStatusReviser ! kafkaMessage
  }

}

object AlarmNotificationStatusConsumerActor {
  def props(
             kafkaConsumer: IKafkaConsumer,
             deserializer: String => ICDAlarmIncidentStatus,
             materializer: Materializer,
             filterTimeInSeconds: Int
           ): Props = Props(classOf[AlarmNotificationStatusConsumerActor], kafkaConsumer, deserializer, materializer, filterTimeInSeconds)
}