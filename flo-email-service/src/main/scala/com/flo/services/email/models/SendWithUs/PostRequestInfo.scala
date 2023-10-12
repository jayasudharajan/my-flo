package com.flo.services.email.models.SendWithUs

import argonaut._
import argonaut.Argonaut._

case class PostRequestInfo(
	                          metaInfo: Option[Map[String, String]],
	                          postBody: String
                          ) {

}

object PostRequestInfo {
	implicit def PostRequestInfoCodecJson: CodecJson[PostRequestInfo] = casecodec2(PostRequestInfo.apply, PostRequestInfo.unapply)(
		"meta_info",
		"postBody"
	)
}
