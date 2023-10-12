package flo.services.sms.utils

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.FloApi.v2.ISmsEndpoints
import com.flo.Models.TwilioMessage
import flo.services.sms.domain.Sms
import org.scalatest.{Matchers, WordSpec}

import scala.concurrent.Future

class TwilioClientSpec extends WordSpec
  with Matchers {
  implicit val system = ActorSystem("sms-service-system")
  implicit val materializer = ActorMaterializer()
  implicit var ex = system.dispatcher

  val smsEndpoints = new ISmsEndpoints {
    override def notifyDelivery(callbackUrl: String, message: TwilioMessage) = Future {
      message
    }
  }

  def smsClient = new TwilioClient(ConfigUtils.twilio.accountSID, ConfigUtils.twilio.authToken, smsEndpoints)

  "The Twilio client" should {
    "success to send an sms to a valid number" in {
      smsClient.send(Sms(ConfigUtils.twilio.fromNumber, "+5491158898021", "Sms body", "", ""))
    }

    "fail to send an sms to an invalid number" in {
      val invalidPhoneNumber = "+15005550001"

      intercept[com.twilio.exception.ApiException] {
        smsClient.send(Sms(ConfigUtils.twilio.fromNumber, invalidPhoneNumber, "Sms body", "", ""))
      }
    }
  }
}




