package flo.services.sms.domain

case class Sms(from: String, to: String, body: String, deliveryCallback: String, postDeliveryCallback: String) {
  require(from.length >= 0, "from is required")
  require(to.length >= 0, "to is required")
  require(body.length >= 0, "body is required")
}






