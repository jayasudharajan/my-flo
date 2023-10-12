package flo.services.sms.services

import akka.testkit.TestProbe
import flo.services.sms.domain.Sms
import flo.services.sms.utils.ConfigUtils
import scala.concurrent.duration._

class SmsServiceSupervisorSpec extends BaseSmsActorsSpec {

  "The SmsServiceSupervisor" should {
    "success to send an sms at first attempt" in {
      val proxy = TestProbe()
      val smsClient = smsClientThatSuccess
      val smsServiceSupervisor = system.actorOf(SmsServiceSupervisor.props(smsClient))
      val sms = Sms(ConfigUtils.twilio.fromNumber, "+5491158898021", "Hello Facundo!!!", "", "")

      proxy.send(smsServiceSupervisor, sms)

      awaitAssert({
        smsClient.getMessages.find(m => m == sms) shouldEqual Some(sms)
      }, 1.second, 100.milliseconds)
    }

    "fails the first attempt but success to send an sms at second attempt" in {
      val proxy = TestProbe()
      val smsClient = smsClientThatFailFirstTime
      val smsServiceSupervisor = system.actorOf(SmsServiceSupervisor.props(smsClient))
      val sms = Sms(ConfigUtils.twilio.fromNumber, "+5491158898021", "Hello Facundo!!!", "", "")

      proxy.send(smsServiceSupervisor, sms)

      awaitAssert({
        smsClient.getMessages.length shouldEqual 1
        smsClient.getAttempts shouldEqual 2

        smsClient.getMessages.find(m => m == sms) shouldEqual Some(sms)
      }, 6.second, 100.milliseconds)
    }
  }
}



