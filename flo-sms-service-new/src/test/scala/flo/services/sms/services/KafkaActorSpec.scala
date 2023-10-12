//package flo.services.sms.services
//
//import akka.actor.{ActorSystem, Props}
//import akka.testkit.{ImplicitSender, TestActorRef, TestKit, TestProbe}
//import com.flo.communication.{FromSneakToCamelCaseDeserializer, IKafkaConsumer, TopicRecord}
//import org.joda.time.DateTime
//import org.scalatest.{BeforeAndAfterAll, Matchers, WordSpecLike}
//
//class KafkaActorSpec extends TestKit(ActorSystem("KafkaActorSpec"))
//  with ImplicitSender
//  with WordSpecLike with Matchers with BeforeAndAfterAll {
//
//  val deserializer = new FromSneakToCamelCaseDeserializer
//
//  val kafkaConsumer = new IKafkaConsumer {
//    override def read[T <: AnyRef : Manifest](deserializer: String => T): Iterable[TopicRecord[T]] =
//      List(TopicRecord(KafkaTestMessage(), DateTime.now())).asInstanceOf[Iterable[TopicRecord[T]]]
//
//    def shutdown(): Unit = {}
//  }
//
//  case class KafkaTestMessage()
//
//  class TestKafkaActorConsumer extends KafkaActorConsumer[KafkaTestMessage](
//    kafkaConsumer,
//    x => deserializer.deserialize[KafkaTestMessage](x),
//    300
//  ) {
//
//    override def consume(message: KafkaTestMessage): Unit = {
//      TestKafkaActorConsumer.consumeActionCalled = true
//    }
//  }
//
//  object TestKafkaActorConsumer {
//    var consumeActionCalled = false
//  }
//
//  override def afterAll() = {
//    TestKit.shutdownActorSystem(system)
//  }
//
//  "The TestKafkaActor" should {
//    "start receive data using the consumer" in {
//      val parent = TestProbe()
//
//      TestActorRef(
//        Props(new TestKafkaActorConsumer),
//        parent.ref,
//        "TestKafkaActor"
//      )
//
//      awaitAssert(TestKafkaActorConsumer.consumeActionCalled shouldEqual true)
//    }
//  }
//}