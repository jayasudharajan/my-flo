package com.flo.services.email.models.SendWithUs

import argonaut._
import argonaut.Argonaut._

case class ExtraEmailsCcAndBcc(
                              address:String
                              )
{

}
object ExtraEmailsCcAndBcc{
	implicit def ExtraEmailsCcAndBccCodecJson: CodecJson[ExtraEmailsCcAndBcc] = casecodec1(ExtraEmailsCcAndBcc.apply, ExtraEmailsCcAndBcc.unapply)(
		"address"
	)
}

