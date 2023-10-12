package com.flo.task.scheduler.services

import com.flo.communication.IKafkaProducer

class KafkaProducerRepository(producerGeneratorByTopic: String => IKafkaProducer)
  extends IKafkaProducerRepository {

  private var producers: Map[String, IKafkaProducer] = Map()

  override def getByTopic(topic: String): IKafkaProducer = {
    producers.get(topic) match {
      case Some(producer) => producer
      case None => {
        val producer = producerGeneratorByTopic(topic)
        producers = producers + (topic -> producer)
        producer
      }
    }
  }
}
