package flo.services.sms.services

import akka.testkit.{TestActorRef, TestProbe}
import flo.services.sms.domain.Sms
import flo.services.sms.services.SmsServiceSupervisor.Sent
import flo.services.sms.utils.{ConfigUtils, SimpleBackoffStrategy}

class SmsServiceSpec extends BaseSmsActorsSpec {

  "The SmsService" should {
    "success to send an sms and notify the parent" in {
      val parent = TestProbe()
      val smsClient = smsClientThatSuccess
      val sms = Sms(ConfigUtils.twilio.fromNumber, "+5491158898021", "Hello Facundo!!!", "", "")

      val smsServiceSupervisor = TestActorRef(
        SmsService.props(smsClient, new SimpleBackoffStrategy, sms),
        parent.ref,
        "SmsService"
      )
      smsServiceSupervisor ! sms

      parent.expectMsg(Sent(sms))
    }
  }
}
