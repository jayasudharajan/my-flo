package com.flo.voice

import java.net.URLEncoder
import java.nio.charset.StandardCharsets

import com.flo.Enums.ValveModes
import com.flo.notification.router.conf._
import com.flo.notification.router.core.api._
import com.flo.notification.router.core.api.localization.LocalizationService
import com.flo.voice.conf.VoiceConfig
import com.typesafe.config.Config
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

trait Module {
  // Requires
  def defaultExecutionContext: ExecutionContext
  def appConfig: Config
  def localizationService: LocalizationService

  // Privates
  private val voiceConfig = appConfig.as[VoiceConfig]("voice")

  private def encodeString(str: String): String = URLEncoder.encode(str, StandardCharsets.UTF_8.toString)

  private def getCallScript(systemMode: Int, locale: Locale, isTenant: Boolean): Future[String] = {
    val asset = systemMode match {
      case ValveModes.AWAY if isTenant  => "nr.away.tenant.template"
      case ValveModes.AWAY if !isTenant => "nr.away.template"
      case ValveModes.HOME if isTenant  => "nr.home.tenant.template"
      case _                            => "nr.home.template"
    }

    localizationService.retrieveLocalizedText(asset, localization.VoiceCall, locale, Map())
  }

  private def generateVoiceScriptUrl(userId: UserId,
                                     message: Message,
                                     alarmIncidentId: AlarmIncidentId,
                                     systemMode: SystemMode,
                                     locale: Locale,
                                     isTenant: Boolean = false): Future[String] = {

    val gatherUrl = voiceConfig.gatherUrl
      .replace(":userId", userId)
      .replace(":alarmIncidentId", alarmIncidentId)

    val queryParams =
      p"?friendly_description=${encodeString(message)}&gather_action_url=${encodeString(gatherUrl)}"

    getCallScript(systemMode, locale, isTenant).map { voiceCallScript =>
      p"$voiceCallScript$queryParams"
    }(defaultExecutionContext)
  }

  private def generateStatusCallbackUrl(userId: UserId, alarmIncidentId: AlarmIncidentId): String =
    voiceConfig.statusCallbackUrl
      .replace(":userId", userId)
      .replace(":alarmIncidentId", alarmIncidentId)

  // Provides
  val voiceStatusCallbackUrlGenerator: VoiceStatusCallbackUrlGenerator = generateStatusCallbackUrl

  val voiceScriptUrlGenerator: VoiceScriptUrlGenerator = generateVoiceScriptUrl
}
