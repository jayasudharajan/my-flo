package com.flo.services.email.models.SendWithUs

import argonaut._
import argonaut.Argonaut._

case class Response(
	                   success: Boolean,
	                   status: String,
	                   receiptId: String
                   ) {}

object Response {
	implicit def ResponseCodecJson: CodecJson[Response] = casecodec3(Response.apply, Response.unapply)(
		"success",
		"status",
		"receipt_id"
	)
}


