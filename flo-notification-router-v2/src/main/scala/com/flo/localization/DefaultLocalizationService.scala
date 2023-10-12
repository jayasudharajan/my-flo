package com.flo.localization

import java.time.format.DateTimeFormatter
import java.time.{Instant, LocalDateTime, ZoneId}
import java.util.concurrent.TimeUnit

import com.flo.FloApi.localization.{LocalizeAssetRequest, LocalizeAssetRequestList, LocalizedApi}
import com.flo.logging.logbookFor
import com.flo.notification.router.core.api.localization._
import com.flo.notification.router.core.api.{
  localization,
  AlarmId,
  AlarmIncident,
  Device,
  SystemModeName,
  TitleAndMessage,
  UnitSystem,
  User
}
import com.flo.notification.sdk.model.SystemMode
import perfolation._

import scala.concurrent.{ExecutionContext, Future}
import scala.util.Try
import scala.util.control.NonFatal

final private class DefaultLocalizationService(localizationApi: LocalizedApi,
                                               defaultDateTimeFormat: String,
                                               defaultTimeZone: ZoneId)(
    implicit ec: ExecutionContext
) extends LocalizationService {

  import DefaultLocalizationService._

  // TODO: Formatting and localization should be done in Localization Service.
  private val defaultDateTimeFormatter = DateTimeFormatter.ofPattern(defaultDateTimeFormat)
  private val frenchDateTimeFormatter =
    DateTimeFormatter.ofPattern("d MMMM 'à' k:mm").withLocale(java.util.Locale.FRENCH)

  override def retrieveAvailableLocales(): Future[Set[Locale]] =
    localizationApi.getLocales(Some(true)).map { locales =>
      locales.items.map(_.id).toSet
    }

  override def retrieveLocalizedText(assetName: AssetName,
                                     assetType: AssetType,
                                     locale: Locale,
                                     args: LocalizationArgs): Future[String] = {

    val assetTypeStr = Assets.assetTypeToString(assetType)

    log.debug(p"Retrieving localized text. AssetName=$assetName, AssetType=$assetTypeStr, Locale=$locale")

    localizationApi
      .getLocalized(assetName, assetTypeStr, locale.toLowerCase, args)
      .map { localizedAsset =>
        val localizedText = localizedAsset.localizedValue

        log.debug(
          p"Retrieved localized text. AssetName=$assetName, AssetType=$assetTypeStr, Locale=$locale => $localizedText"
        )

        localizedText
      }
      .recover {
        case NonFatal(e) =>
          log.error(
            p"Failed to retrieve localized text for AssetName=$assetName, AssetType=$assetTypeStr, Locale=$locale",
            e
          )
          ""
      }
  }

  override def retrieveLocalizedTexts(assetNames: Set[AssetName],
                                      assetType: AssetType,
                                      locale: Locale,
                                      args: LocalizationArgs): Future[Map[AssetName, String]] = {
    val assetTypeStr = Assets.assetTypeToString(assetType)

    log.debug(p"Retrieving localized texts. AssetNames=$assetNames, AssetType=$assetTypeStr, Locale=$locale")

    val assetList = LocalizeAssetRequestList(assetNames.map { assetName =>
      LocalizeAssetRequest(assetName, assetTypeStr, locale, args)
    }.toList)

    localizationApi
      .getLocalized(assetList)
      .map { localizedAssets =>
        if (localizedAssets.errors.nonEmpty) {
          log.warn(
            p"Failed to retrieve localized text for AssetNames=${localizedAssets.errors
              .map(_.name)}. This may be expected. Errors=${localizedAssets.errors}"
          )
        }

        val localizationMap = localizedAssets.items.map { localizedAsset =>
          localizedAsset.name -> localizedAsset.localizedValue
        }.toMap

        assetNames.map { assetName =>
          assetName -> localizationMap.getOrElse(assetName, "")
        }.toMap
      }
      .recover {
        case NonFatal(e) =>
          log.error(
            p"Failed to retrieve localized texts for AssetNames=$assetNames, AssetType=$assetTypeStr, Locale=$locale",
            e
          )
          assetNames.map(_ -> "").toMap
      }
  }

  override def retrieveLocalizedAlarmMessage(locale: String,
                                             alarmId: Int,
                                             systemMode: String,
                                             args: LocalizationArgs): Future[String] =
    retrieveLocalizedText(Assets.alarmMessage(alarmId, systemMode), localization.Display, locale, args)

  override def retrieveLocalizedAlarmTitle(locale: String, alarmId: Int, systemMode: String): Future[String] =
    retrieveLocalizedText(Assets.alarmTitle(alarmId, systemMode), localization.Display, locale, Map())

  override def retrieveLocalizedAlarmTitleAndMessage(
      alarmId: AlarmId,
      systemModeName: SystemModeName,
      args: Map[Locale, Map[UnitSystem, LocalizationArgs]]
  ): Future[Map[TitleAndMessage, (Set[Locale], Set[UnitSystem])]] = {
    val alarmTitleAsset   = Assets.alarmTitle(alarmId, systemModeName)
    val alarmMessageAsset = Assets.alarmMessage(alarmId, systemModeName)

    val eventualLocalizedTuples = Future.sequence {
      args.flatMap {
        case (locale, argsByUnitSystem) =>
          argsByUnitSystem.map {
            case (unitSystem, args) =>
              retrieveLocalizedTexts(
                Set(alarmTitleAsset, alarmMessageAsset),
                localization.Display,
                locale,
                args
              ).map { localizedTexts =>
                (
                  locale,
                  unitSystem,
                  TitleAndMessage(
                    localizedTexts.getOrElse(alarmTitleAsset, ""),
                    localizedTexts.getOrElse(alarmMessageAsset, "")
                  )
                )
              }
          }
      }
    }

    eventualLocalizedTuples.map { localizedTuples =>
      localizedTuples.groupBy(_._3).map {
        case (titleAndMessage, tuple) =>
          titleAndMessage -> ((tuple.map(_._1).toSet, tuple.map(_._2).toSet))
      }
    }
  }

  override def retrieveLocalizedAlarmDisplayName(locale: String, alarmId: Int, systemMode: String): Future[String] =
    retrieveLocalizedText(Assets.alarmDisplayName(alarmId, systemMode), localization.Display, locale, Map())

  override def retrieveLocalizedAlarmDisplayDescription(locale: String,
                                                        alarmId: Int,
                                                        systemMode: String): Future[String] =
    retrieveLocalizedText(Assets.alarmDescription(alarmId, systemMode), localization.Display, locale, Map())

  // TODO: This method should receive a Set[Arg]. See CachedLocalizationService for ideas.
  override def buildDefaultLocalizedArgs(alarmIncident: AlarmIncident,
                                         user: User,
                                         device: Device): Future[Map[String, String]] = {
    val zoneId           = getTimeZone(device, user)
    val unitSystem       = getUnitSystem(user.unitSystem.toRight(user.locale))
    val unitSystemSuffix = com.flo.localization.getUnitSystemString(unitSystem)

    val systemModeName         = SystemMode.toString(alarmIncident.systemMode)
    val systemModeAsset        = Assets.systemMode(alarmIncident.systemMode)
    val volumeAbbrevAsset      = Assets.volumeAbbrev(unitSystemSuffix)
    val volumeNameAsset        = Assets.volumeName(unitSystemSuffix)
    val temperatureAbbrevAsset = Assets.temperatureAbbrev(unitSystemSuffix)
    val temperatureNameAsset   = Assets.temperatureName(unitSystemSuffix)
    val pressureAbbrevAsset    = Assets.pressureAbbrev(unitSystemSuffix)
    val pressureNameAsset      = Assets.pressureName(unitSystemSuffix)
    val rateNameAsset          = Assets.rateName(unitSystemSuffix)
    val rateAbbrevAsset        = Assets.rateAbbrev(unitSystemSuffix)
    val alarmDisplayAsset      = Assets.alarmDisplayName(alarmIncident.alarmId, systemModeName)
    val previousAlertAsset =
      alarmIncident.resolvedAlarmIncident.map(r => Assets.alarmDisplayName(r.alarmId, systemModeName))
    val appTypeAsset = alarmIncident.applicationType.map(appType => Assets.appType(appType))

    val assets = Set(
      systemModeAsset,
      volumeAbbrevAsset,
      volumeNameAsset,
      alarmDisplayAsset,
      temperatureAbbrevAsset,
      temperatureNameAsset,
      pressureAbbrevAsset,
      pressureNameAsset,
      rateNameAsset,
      rateAbbrevAsset,
      Assets.DateFormat
    ) ++ Set(
      previousAlertAsset,
      appTypeAsset
    ).flatten
    val eventualLocalizedTexts = retrieveLocalizedTexts(assets, localization.Display, user.locale, Map())

    val flowDurationInMinutes = alarmIncident.snapshot.efd.fold("") { eventFlowDuration =>
      TimeUnit.SECONDS.toMinutes(eventFlowDuration.toLong).toString
    }
    val userShortName = p"${user.firstName} ${user.lastName.headOption.fold("")(_ + ".")}"
    val previousIncidentDateTime = alarmIncident.resolvedAlarmIncident.fold("") { resolvedAlarmIncident =>
      formattedDateTime(zoneId, user.locale, resolvedAlarmIncident.timestamp)
    }

    eventualLocalizedTexts.map { localizedTexts =>
      Map(
        Args.IncidentDateTime.name          -> formattedDateTime(zoneId, user.locale, alarmIncident.timestamp),
        Args.FlowRate.name                  -> localizeRate(unitSystem, alarmIncident.snapshot.fr),
        Args.MaxTemperature.name            -> localizeTemperature(unitSystem, alarmIncident.snapshot.tmax),
        Args.MinTemperature.name            -> localizeTemperature(unitSystem, alarmIncident.snapshot.tmin),
        Args.FlowDurationInMinutes.name     -> flowDurationInMinutes,
        Args.FlowEvent.name                 -> localizeVolume(unitSystem, alarmIncident.snapshot.ef),
        Args.MinPressure.name               -> localizePressure(unitSystem, alarmIncident.snapshot.pmin),
        Args.MaxPressure.name               -> localizePressure(unitSystem, alarmIncident.snapshot.pmax),
        Args.AppType.name                   -> appTypeAsset.map(localizedTexts(_)).getOrElse(""),
        Args.UserSmallName.name             -> userShortName,
        Args.NewSystemMode.name             -> localizedTexts(systemModeAsset),
        Args.PreviousAlertFriendlyName.name -> previousAlertAsset.map(localizedTexts(_)).getOrElse(""),
        Args.PreviousIncidentDateTime.name  -> previousIncidentDateTime,
        Args.VolumeAbbreviation.name        -> localizedTexts(volumeAbbrevAsset),
        Args.VolumeName.name                -> localizedTexts(volumeNameAsset),
        Args.PressureAbbreviation.name      -> localizedTexts(pressureAbbrevAsset),
        Args.PressureName.name              -> localizedTexts(pressureNameAsset),
        Args.TemperatureAbbreviation.name   -> localizedTexts(temperatureAbbrevAsset),
        Args.TemperatureName.name           -> localizedTexts(temperatureNameAsset),
        Args.AlarmDisplayName.name          -> localizedTexts(alarmDisplayAsset),
        Args.AppLink.name                   -> "floapp://home",
        Args.MinHumidity.name               -> alarmIncident.snapshot.limitHumidityMin.map(roundValue).getOrElse(""),
        Args.MaxHumidity.name               -> alarmIncident.snapshot.limitHumidityMax.map(roundValue).getOrElse(""),
        Args.MinBattery.name                -> alarmIncident.snapshot.limitBatteryMin.map(_.toString).getOrElse(""),
        Args.TemperatureUnitSystem.name     -> localizedTexts(temperatureAbbrevAsset),
        Args.RateName.name                  -> localizedTexts(rateNameAsset),
        Args.RateAbbreviation.name          -> localizedTexts(rateAbbrevAsset),
        Args.RecommendedPressure.name       -> localizePressure(unitSystem, Some(DefaultRecommendedPressure)),
        Args.DeviceNickname.name            -> device.nickname.getOrElse(""),
        Args.LocationNickname.name          -> device.location.nickname.getOrElse(""),
        Args.LocationDeviceHint.name        -> buildLocationDeviceHint(user, device).getOrElse("")
      )
    }
  }

  // TODO: Implement me.
  override def buildDefaultFullyLocalizedArgs(
      alarmIncident: AlarmIncident,
      user: User,
      device: Device
  ): Future[Map[Locale, Map[UnitSystem, Map[String, String]]]] = ???

  override def retrieveLocalizedSystemMode(locale: String, systemMode: Int): Future[String] =
    retrieveLocalizedText(Assets.systemMode(systemMode), localization.Display, locale, Map())

  override def getLocalizedRate(unitSystemOrLocale: Either[String, UnitSystem],
                                maybeWaterFlowRate: Option[Double]): String =
    localizeRate(getUnitSystem(unitSystemOrLocale), maybeWaterFlowRate)

  override def getLocalizedTemperature(unitSystemOrLocale: Either[String, UnitSystem],
                                       maybeTemperature: Option[Double]): String =
    localizeTemperature(getUnitSystem(unitSystemOrLocale), maybeTemperature)

  override def getLocalizedPressure(unitSystemOrLocale: Either[String, UnitSystem],
                                    maybePressure: Option[Double]): String =
    localizePressure(getUnitSystem(unitSystemOrLocale), maybePressure)

  override def getLocalizedVolume(unitSystemOrLocale: Either[String, UnitSystem], maybeVolume: Option[Double]): String =
    localizeVolume(getUnitSystem(unitSystemOrLocale), maybeVolume)

  override def getTimeZone(device: Device, user: User): ZoneId =
    // TODO: Get Timezone from User when available.
    Option(device.location.timezone)
      .filter(_.trim.nonEmpty)
      .flatMap { tz =>
        val maybeZoneId = Try[ZoneId](ZoneId.of(tz))
        maybeZoneId.failed.foreach { e =>
          log.warn(p"Invalid ZoneId $tz for User ${user.id} and Location ${device.location.id}.", e)
        }
        maybeZoneId.toOption
      }
      .getOrElse(defaultTimeZone)

  override def getUnitSystemString(unitSystemOrLocale: Either[String, UnitSystem]): String =
    com.flo.localization.getUnitSystemString(unitSystemOrLocale)

  private def formattedDateTime(zoneId: ZoneId, locale: String, timestamp: Long): String = {
    val formatter = {
      if (locale.startsWith("fr")) frenchDateTimeFormatter
      else defaultDateTimeFormatter
    }
    LocalDateTime
      .ofInstant(Instant.ofEpochMilli(timestamp), zoneId)
      .format(formatter)
      .replace("AM", "am")
      .replace("PM", "pm")
  }
}

private object DefaultLocalizationService {
  private val log = logbookFor(getClass)
}
