package flo.directive.router.services

import akka.actor.{Actor, ActorLogging}
import com.flo.communication.IKafkaConsumer
import com.flo.utils.ResourcePuller
import flo.directive.router.services.KafkaActorConsumer.Consume
import org.joda.time.{DateTime, DateTimeZone}
import scala.concurrent.duration._

abstract class KafkaActorConsumer[KafkaMessage <: AnyRef : Manifest](
                                                                      kafkaConsumer: IKafkaConsumer,
                                                                      deserializer: String => KafkaMessage,
                                                                      filter: Option[KafkaMessage => Boolean],
                                                                      filterTimeInSeconds: Int
                                                                    )
  extends Actor
    with ActorLogging {

  private val internalFilter = filter.getOrElse((x: KafkaMessage) => true)
  var isPaused = false
  var killSwitchHasChanged = true

  val puller = new ResourcePuller[Boolean](
    context.system,
    () => {
      val result = sys.env.get("KILL_SWITCH_ENABLED") match {
        case Some(isKillSwitchEnabled) =>
          if(killSwitchHasChanged) log.info(s"KILL_SWITCH_ENABLED: $isKillSwitchEnabled")
          isKillSwitchEnabled.toBoolean
        case None =>
          if(killSwitchHasChanged) log.info("KILL_SWITCH_ENABLED is set to default value: false")
          false
      }
      killSwitchHasChanged = result != isPaused
      result
    }
  )

  puller.pullEvery(2.seconds, paused => {
    isPaused = paused

    if(paused) {
      kafkaConsumer.pause()
    }

    if(!paused && kafkaConsumer.isPaused()) {
      kafkaConsumer.resume()
    }
  })

  override def preStart(): Unit = {
    self ! Consume
  }

  def receive: Receive = {
    case Consume => {
      kafkaConsumer.consume[KafkaMessage](deserializer, record => {
        val shouldBeProcessed = record.createdAt.isAfter(
          DateTime.now(DateTimeZone.UTC).minusSeconds(filterTimeInSeconds)
        )

        if(shouldBeProcessed && internalFilter(record.data)) {
          consume(record.data)
        }
      })
    }
  }

  def consume(kafkaMessage: KafkaMessage): Unit
}

object KafkaActorConsumer {
  object Consume
}



