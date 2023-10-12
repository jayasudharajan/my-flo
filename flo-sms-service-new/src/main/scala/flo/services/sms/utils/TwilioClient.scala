package flo.services.sms.utils

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import com.flo.FloApi.v2.ISmsEndpoints
import com.flo.Models.TwilioMessage
import com.twilio.Twilio
import com.twilio.`type`.PhoneNumber
import com.twilio.rest.api.v2010.account.Message
import com.typesafe.scalalogging.Logger
import flo.services.sms.domain.Sms
import org.joda.time.format.DateTimeFormat
import scala.collection.JavaConverters._

class TwilioClient(accountSID: String, authToken: String, smsEndpoints: ISmsEndpoints)(implicit val actorSystem: ActorSystem, implicit val actorMaterializer: ActorMaterializer)
  extends SmsClient {

  val logger = Logger[TwilioClient]
  val customFormat = DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
  val unrecoverableErrorCodes = List(
    // Invalid Called Phone Number (The 'To' number xxxxx is not a valid phone number.)
    21211,
    // Invalid Caller Phone Number
    21212,
    // Caller phone number is required
    21213,
    // 'To' phone number cannot be reached
    21214,
    // This Phone Number type does not support SMS
    21407,
    // Permission to send an SMS has not been enabled for the region indicated by the 'To' number
    21408,
    // Message body is required
    21602
  )

  Twilio.init(accountSID, authToken)

  def send(sms: Sms): Unit = {
    try {
      val messageCreator = Message.creator(
        new PhoneNumber(sms.to),
        new PhoneNumber(sms.from),
        sms.body
      )

      if (!sms.postDeliveryCallback.isEmpty) {
        messageCreator.setStatusCallback(sms.postDeliveryCallback)
      }

      val message = messageCreator.create()

      if (!sms.deliveryCallback.isEmpty) {
        val adaptedMessage = TwilioMessage(
          message.getAccountSid,
          message.getApiVersion,
          message.getBody,
          customFormat.print(message.getDateCreated),
          customFormat.print(message.getDateUpdated),
          customFormat.print(message.getDateSent),
          message.getDirection.toString,
          message.getErrorCode,
          message.getErrorMessage,
          message.getFrom.toString,
          message.getNumMedia,
          message.getNumSegments,
          message.getPrice,
          message.getPriceUnit.getDisplayName,
          message.getSid,
          message.getStatus.toString,
          message.getSubresourceUris.asScala.toMap,
          message.getTo,
          message.getUri
        )

        smsEndpoints.notifyDelivery(sms.deliveryCallback, adaptedMessage)
      }
      logger.info("A sms message was sent successfully")
    } catch {
      case e: com.twilio.exception.ApiException if unrecoverableErrorCodes.contains(e.getCode().asInstanceOf[Int]) =>
        throw new UnrecoverableTwilioError(e.getMessage, e)
    }
  }
}

