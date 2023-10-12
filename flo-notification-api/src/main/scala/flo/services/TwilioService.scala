package flo.services

import com.flo.FloApi.gateway.api.FirmwareProperties
import com.flo.notification.sdk.model.{IncidentWithAlarmInfo, SystemMode}
import com.twilio.twiml.VoiceResponse
import com.twilio.twiml.voice.{Dial, Hangup, Play, Redirect}
import javax.inject.{Inject, Provider, Singleton}
import just.semver.SemVer

import scala.concurrent.{ExecutionContext, Future}

case class TwilioConfig(customerCarePhoneNumber: String)

@Singleton
class TwilioService @Inject()(config: TwilioConfig,
                              gatewayService: Provider[GatewayService],
                              localizationService: LocalizationService)(implicit ec: ExecutionContext) {

  private val NewFwVersion = SemVer.parseUnsafe("4.1.0")

  def processUserAction(digits: String, incidentWithAlarmInfo: IncidentWithAlarmInfo): Future[Unit] =
    digits match {
      case "1" => gatewayService.get().closeValve(incidentWithAlarmInfo.incident.icdId)

      case "2" => // Sleep for 2 hours
        val deviceId  = incidentWithAlarmInfo.incident.icdId
        val gwService = gatewayService.get()
        gwService.getDevice(deviceId).flatMap { maybeDevice =>
          maybeDevice.fold(Future.unit) { device =>
            if (device.fwVersion.exists(isNewFirmware)) {
              gwService
                .setFwProperties(deviceId, FirmwareProperties(alarmSuppressUntilEventEnd = Some(true)))
            } else {
              val sleepTimeInMinutes = 120
              gwService.setToSleep(deviceId, sleepTimeInMinutes)
            }
          }
        }

      case _ => Future.unit
    }

  def buildTwilioResponse(digits: String, systemMode: Int, gatherUrl: String, locale: String): Future[String] = {
    val eventualResponseBuilder = digits match {
      case "0" =>
        localizationService.getLocalization("nr.option.0", "voice", locale).map { option0 =>
          val responseBuilder = new VoiceResponse.Builder()
          val playBuilder     = new Play.Builder()
          playBuilder.url(option0)

          val dialBuilder = new Dial.Builder()
          dialBuilder.number(config.customerCarePhoneNumber)

          responseBuilder.play(playBuilder.build())
          responseBuilder.dial(dialBuilder.build())
        }

      case "1" if systemMode == SystemMode.Home =>
        localizationService.getLocalization("nr.option.1", "voice", locale).map { option1 =>
          val responseBuilder = new VoiceResponse.Builder()
          val playBuilder     = new Play.Builder()
          playBuilder.url(option1)

          val hangup = new Hangup.Builder().build()

          responseBuilder.play(playBuilder.build())
          responseBuilder.hangup(hangup)
        }

      case "2" if systemMode == SystemMode.Home =>
        localizationService.getLocalization("nr.option.2", "voice", locale).map { option2 =>
          val responseBuilder = new VoiceResponse.Builder()
          val playBuilder     = new Play.Builder()
          playBuilder.url(option2)

          val hangup = new Hangup.Builder().build()

          responseBuilder.play(playBuilder.build())
          responseBuilder.hangup(hangup)
        }

      case _ if systemMode == SystemMode.Home =>
        localizationService.getLocalization("nr.wrongInput.home", "voice", locale).map { wrongInput =>
          val responseBuilder = new VoiceResponse.Builder()
          val redirect        = new Redirect.Builder(s"$wrongInput?gather_action_url=$gatherUrl")
          responseBuilder.redirect(redirect.build())
        }

      case _ =>
        localizationService.getLocalization("nr.wrongInput.away", "voice", locale).map { wrongInput =>
          val responseBuilder = new VoiceResponse.Builder()
          val redirect        = new Redirect.Builder(s"$wrongInput?gather_action_url=$gatherUrl")
          responseBuilder.redirect(redirect.build())
        }
    }
    eventualResponseBuilder.map(_.build().toXml)
  }

  private def isNewFirmware(fwVersion: String): Boolean =
    SemVer
      .parse(fwVersion)
      .map(_ >= NewFwVersion)
      .getOrElse(false)
}
