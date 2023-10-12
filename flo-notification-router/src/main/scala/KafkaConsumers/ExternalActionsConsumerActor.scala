package KafkaConsumers

import Actors.ExternalActionsActor
import Models.ExternalActions.ValveStatusActorMessage
import Utils.ApplicationSettings
import akka.actor.Props
import akka.routing.RoundRobinPool
import akka.stream.Materializer
import com.flo.Models.TelemetryCompact
import com.flo.communication.IKafkaConsumer


/**
	* Created by Francisco on 1/11/2017.
	* This actor will take care of dequeueing messages from kafka regarding external user actions.
	*/
class ExternalActionsConsumerActor(
	                                  kafkaConsumer: IKafkaConsumer,
	                                  deserializer: String => TelemetryCompact,
	                                  materializer: Materializer,
	                                  filterTimeInSeconds: Int
                                  ) extends KafkaActorConsumer[TelemetryCompact](kafkaConsumer, deserializer, filterTimeInSeconds) {

	// Get application settings
	val externalActionsActorWorkers = ApplicationSettings.floActors.numberOfWorkers.externalActions.getOrElse(throw new IllegalArgumentException("flo-actors.numberOfWorkers.kafkaReaderExternalActions was not found in config or environmental variables"))

	val externalActionsActor = context.system.actorOf(Props[ExternalActionsActor].withRouter(RoundRobinPool(externalActionsActorWorkers)))

	def consume(kafkaMessage: TelemetryCompact): Unit = {
		externalActionsActor ! ValveStatusActorMessage(telemetry = Some(kafkaMessage))
	}
}

object ExternalActionsConsumerActor {
	def props(
		         kafkaConsumer: IKafkaConsumer,
		         deserializer: String => TelemetryCompact,
		         materializer: Materializer,
		         filterTimeInSeconds: Int
	         ): Props = Props(classOf[ExternalActionsConsumerActor], kafkaConsumer, deserializer, materializer, filterTimeInSeconds)
}
