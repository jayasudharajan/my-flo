package com.flo.voice

package object conf {

  private[voice] case class VoiceConfig(gatherUrl: String, statusCallbackUrl: String)

}
