//package flo.services.sms.services
//
//import akka.testkit.{TestActorRef, TestProbe}
//import com.flo.Models.KafkaMessages.SmsMessage
//import com.flo.communication.{FromSneakToCamelCaseDeserializer, IKafkaConsumer, TopicRecord}
//import flo.services.sms.domain.Sms
//import flo.services.sms.utils._
//import org.joda.time.DateTime
//
//class SmsConsumerSpec extends BaseSmsActorsSpec {
//
//  val phone1 = "+11111111111"
//  val phone2 = "+22222222222"
//
//  val body1 = "Sms body"
//  val body2 = "Another sms body"
//
//  val deserializer = new FromSneakToCamelCaseDeserializer
//
//  val kafkaConsumer = new IKafkaConsumer {
//    override def shutdown(): Unit = {}
//
//    override def read[T <: AnyRef: Manifest](deserializer: String => T): Iterable[TopicRecord[T]] =
//      List(
//        TopicRecord(SmsMessage("1", body1, phone1, "a", "b"), DateTime.now()),
//        TopicRecord(SmsMessage("2", body2, phone2, "a", "b"), DateTime.now())
//      ).asInstanceOf[Iterable[TopicRecord[T]]]
//  }
//
//  "The SmsConsumer" should {
//    "start receive data using the consumer" in {
//      val parent = TestProbe()
//
//      val smsClient = smsClientThatSuccess
//
//      val smsConsumerProps = SmsKafkaConsumer.props(
//        SmsKafkaConsumer.SmsConsumerSettings(
//          kafkaConsumer,
//          smsClient,
//          x => deserializer.deserialize[SmsMessage](x),
//          300
//        )
//      )
//
//      TestActorRef(
//        smsConsumerProps,
//       parent.ref,
//       "SmsConsumer"
//      )
//
//      awaitAssert(smsClient.getMessages should contain only (
//        Sms(ConfigUtils.twilio.fromNumber, phone1, body1, "a", "b"),
//        Sms(ConfigUtils.twilio.fromNumber, phone2, body2, "a", "b")
//        )
//      )
//    }
//  }
//}