package com.flo.services.email.models.SendWithUs

import argonaut._
import argonaut.Argonaut._

case class Sender(
	                 name: String,
	                 address: String,
	                 replyTo: String
                 ) {

}

object Sender {
	implicit def SenderCodecJson: CodecJson[Sender] = casecodec3(Sender.apply, Sender.unapply)(
		"name",
		"address",
		"reply_to"
	)
}
