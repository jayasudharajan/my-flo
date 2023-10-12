package flo.services.sms.utils

import com.twilio.exception.ApiException

case class UnrecoverableTwilioError(message: String, cause: Throwable) extends ApiException(message, cause)