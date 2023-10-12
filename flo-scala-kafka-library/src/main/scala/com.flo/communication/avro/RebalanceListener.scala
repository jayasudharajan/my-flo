package com.flo.communication.avro

import akka.actor.{Actor, ActorLogging}
import akka.kafka.{TopicPartitionsAssigned, TopicPartitionsRevoked}

class RebalanceListener extends Actor with ActorLogging {
  def receive: Receive = {
    case TopicPartitionsAssigned(sub, assigned) ⇒
      log.info("Assigned: {}", assigned)

    case TopicPartitionsRevoked(sub, revoked) ⇒
      log.info("Revoked: {}", revoked)
  }
}
