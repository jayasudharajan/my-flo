package flo.services.sms.services

import akka.actor.Props
import com.flo.Models.KafkaMessages.SmsMessage
import com.flo.communication.IKafkaConsumer
import flo.services.sms.domain.Sms
import flo.services.sms.services.SmsKafkaConsumer.SmsConsumerSettings
import flo.services.sms.utils.{ConfigUtils, SmsClient}

class SmsKafkaConsumer(settings: SmsConsumerSettings)
  extends KafkaActorConsumer[SmsMessage](settings.kafkaConsumer, settings.deserializer, settings.filterTimeInSeconds) {

  log.info("SmsKafkaConsumer started!")

  val smsServiceSupervisor = context.actorOf(
    SmsServiceSupervisor.props(settings.smsClient),
    "sms-service-supervisor"
  )

  def consume(kafkaSms: SmsMessage): Unit = {
    val sms = Sms(
      ConfigUtils.twilio.fromNumber,
      kafkaSms.phone,
      kafkaSms.text,
      kafkaSms.deliveryCallback,
      kafkaSms.postDeliveryCallback
    )

    smsServiceSupervisor ! sms
  }
}

object SmsKafkaConsumer {
  case class SmsConsumerSettings(
                                  kafkaConsumer: IKafkaConsumer,
                                  smsClient: SmsClient,
                                  deserializer: String => SmsMessage,
                                  filterTimeInSeconds: Int
                                )

  def props(settings: SmsConsumerSettings) = Props(classOf[SmsKafkaConsumer], settings)
}