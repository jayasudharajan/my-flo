package com.flo.notification.sdk.circe

import com.flo.notification.router.core.api.VoiceCall
import com.flo.notification.sdk.circe
import io.circe.syntax._

final private[sdk] class SerializeVoiceCall extends (VoiceCall => String) {

  override def apply(voiceCall: VoiceCall): String = {
    import circe._

    voiceCall.asJson.noSpaces
  }

}
