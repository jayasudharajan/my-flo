package flo.services.sms.services

import akka.actor.ActorSystem
import akka.testkit.{ImplicitSender, TestKit}
import flo.services.sms.domain.Sms
import flo.services.sms.utils.SmsClient
import org.scalatest.{BeforeAndAfterAll, Matchers, WordSpecLike}

abstract class BaseSmsActorsSpec extends TestKit(ActorSystem("MySpec"))
  with ImplicitSender
  with WordSpecLike with Matchers with BeforeAndAfterAll {

  override def afterAll() = {
    TestKit.shutdownActorSystem(system)
  }

  def smsClientThatSuccess = new SmsClient {
    private var messages: List[Sms] = Nil

    def getMessages = messages

    override def send(sms: Sms): Unit = {
      messages = sms :: messages
    }
  }

  def smsClientThatFailFirstTime = new SmsClient {
    private var messages: List[Sms] = Nil
    private var attempts = 0

    def getMessages = messages
    def getAttempts = attempts

    override def send(sms: Sms): Unit = {
      attempts = attempts + 1

      if(attempts <= 1)
        throw new com.twilio.exception.ApiException("ShouldFail error.")

      messages = sms :: messages
    }
  }
}
