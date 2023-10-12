package com.flo.task.scheduler.services

import com.flo.communication.IKafkaProducer

trait IKafkaProducerRepository {
  def getByTopic(topic: String): IKafkaProducer
}
