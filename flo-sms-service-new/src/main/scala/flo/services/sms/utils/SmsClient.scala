package flo.services.sms.utils

import flo.services.sms.domain.Sms

trait SmsClient {
  def send(sms: Sms): Unit
}
