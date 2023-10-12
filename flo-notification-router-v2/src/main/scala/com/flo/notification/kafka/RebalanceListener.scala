package com.flo.notification.kafka

import akka.actor.{Actor, ActorLogging}
import akka.kafka.{TopicPartitionsAssigned, TopicPartitionsRevoked}
import perfolation._

class RebalanceListener extends Actor with ActorLogging {
  def receive: Receive = {
    case TopicPartitionsAssigned(_, assigned) =>
      log.info(p"Assigned: $assigned")

    case TopicPartitionsRevoked(_, revoked) =>
      log.info(p"Revoked: $revoked")
  }
}
