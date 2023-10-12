package com.flo.services.email.models.SendWithUs

import argonaut._
import argonaut.Argonaut._

case class Recipient(
                    name:Option[String],
                    address:String
                    ) {

}
object Recipient {
implicit def  RecipientCodecJson:CodecJson[Recipient] = casecodec2(Recipient.apply, Recipient.unapply)(
	"name",
	"address"
)
}
