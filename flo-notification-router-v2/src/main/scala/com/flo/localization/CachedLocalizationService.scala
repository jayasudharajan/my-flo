package com.flo.localization

import java.time.{Instant, LocalDateTime, ZoneId}
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit

import com.flo.localization.Args.{DynamicArg, _}
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
import com.flo.notification.router.core.api.localization.{
  AssetName,
  Display,
  Locale,
  LocalizationArgs,
  LocalizationService
}
import com.flo.notification.sdk.model.SystemMode
import com.github.blemale.scaffeine.Cache
import perfolation._

import scala.concurrent.{ExecutionContext, Future}

class CachedLocalizationService(underlying: LocalizationService, cache: Cache[String, String])(
    implicit ec: ExecutionContext
) extends LocalizationService {

  override def retrieveAvailableLocales(): Future[Set[Locale]] = {
    val key = "locale.all"

    cache
      .getIfPresent(key)
      .map { locales =>
        Future.successful(locales.split(',').toSet)
      }
      .getOrElse {
        underlying.retrieveAvailableLocales().map { locales =>
          cache.put(key, locales.mkString(","))
          locales
        }
      }
  }

  override def retrieveLocalizedAlarmMessage(locale: String,
                                             alarmId: Int,
                                             systemMode: String,
                                             args: LocalizationArgs): Future[String] = {
    val key = p"alarm.$alarmId.$systemMode.message.$locale"

    cache
      .getIfPresent(key)
      .map(Future.successful)
      .getOrElse {
        underlying.retrieveLocalizedAlarmMessage(locale, alarmId, systemMode, args).map { message =>
          if (args.isEmpty) cache.put(key, message)
          message
        }
      }
  }

  override def retrieveLocalizedAlarmTitle(locale: String, alarmId: Int, systemMode: String): Future[String] = {
    val key = p"alarm.$alarmId.$systemMode.title.$locale"

    cache
      .getIfPresent(key)
      .map(Future.successful)
      .getOrElse {
        underlying.retrieveLocalizedAlarmTitle(locale, alarmId, systemMode).map { title =>
          cache.put(key, title)
          title
        }
      }
  }

  override def retrieveLocalizedAlarmTitleAndMessage(
      alarmId: AlarmId,
      systemModeName: SystemModeName,
      args: Map[Locale, Map[UnitSystem, LocalizationArgs]]
  ): Future[Map[TitleAndMessage, (Set[Locale], Set[UnitSystem])]] =
    underlying.retrieveLocalizedAlarmTitleAndMessage(alarmId, systemModeName, args)

  override def retrieveLocalizedAlarmDisplayName(locale: String, alarmId: Int, systemMode: String): Future[String] = {
    val key = p"alarm.$alarmId.$systemMode.displayName.$locale"

    cache
      .getIfPresent(key)
      .map(Future.successful)
      .getOrElse {
        underlying.retrieveLocalizedAlarmDisplayName(locale, alarmId, systemMode).map { displayName =>
          cache.put(key, displayName)
          displayName
        }
      }
  }

  override def retrieveLocalizedAlarmDisplayDescription(locale: String,
                                                        alarmId: Int,
                                                        systemMode: String): Future[String] = {
    val key = p"alarm.$alarmId.$systemMode.description.$locale"

    cache
      .getIfPresent(key)
      .map(Future.successful)
      .getOrElse {
        underlying.retrieveLocalizedAlarmDisplayDescription(locale, alarmId, systemMode).map { description =>
          cache.put(key, description)
          description
        }
      }
  }

  override def retrieveLocalizedText(assetName: AssetName,
                                     assetType: localization.AssetType,
                                     locale: Locale,
                                     args: LocalizationArgs): Future[String] = {
    val key = buildTextKey(assetName, assetType, locale)

    cache
      .getIfPresent(key)
      .map(Future.successful)
      .getOrElse {
        underlying.retrieveLocalizedText(assetName, assetType, locale, args).map { text =>
          if (args.isEmpty) cache.put(key, text)
          text
        }
      }
  }

  override def retrieveLocalizedTexts(assetNames: Set[AssetName],
                                      assetType: localization.AssetType,
                                      locale: Locale,
                                      args: LocalizationArgs): Future[Map[AssetName, String]] =
    if (args.nonEmpty) {
      underlying.retrieveLocalizedTexts(assetNames, assetType, locale, args)
    } else {
      val cachedTexts = assetNames.flatMap { assetName =>
        val key = buildTextKey(assetName, assetType, locale)
        cache.getIfPresent(key).map(text => assetName -> text)
      }.toMap

      val nonCachedAssets = assetNames.diff(cachedTexts.keySet)

      if (nonCachedAssets.isEmpty) Future.successful(cachedTexts)
      else {
        underlying.retrieveLocalizedTexts(nonCachedAssets, assetType, locale, args).map { texts =>
          texts.foreach {
            case (assetName, text) =>
              val key = buildTextKey(assetName, assetType, locale)
              cache.put(key, text)
          }

          cachedTexts ++ texts
        }
      }
    }

  // TODO: This method should receive a Set[Arg]. We should cache whatever possible.
  override def buildDefaultLocalizedArgs(alarmIncident: AlarmIncident,
                                         user: User,
                                         device: Device): Future[Map[String, String]] =
    underlying.buildDefaultLocalizedArgs(alarmIncident, user, device)

  override def buildDefaultFullyLocalizedArgs(
      alarmIncident: AlarmIncident,
      user: User,
      device: Device
  ): Future[Map[Locale, Map[UnitSystem, Map[String, String]]]] = {
    val unitSystems     = UnitSystem.values
    val eventualLocales = retrieveAvailableLocales()

    eventualLocales.flatMap { locales =>
      val eventualLocalizedTuples = Future.sequence(locales.flatMap { locale =>
        unitSystems.map { unitSystem =>
          localizeArgs(Args.all, locale, unitSystem, alarmIncident, user, device).map { localizedArgs =>
            (locale, unitSystem, localizedArgs)
          }
        }
      })

      eventualLocalizedTuples.map { localizedTuples =>
        localizedTuples.groupBy(_._1).map {
          case (locale, tuples) =>
            locale -> tuples.map {
              case (_, unitSystem, args) =>
                unitSystem -> args
            }.toMap
        }
      }
    }

  }

  override def retrieveLocalizedSystemMode(locale: String, systemMode: Int): Future[String] = {
    val key = p"systemMode.$systemMode.$locale"

    cache
      .getIfPresent(key)
      .map(Future.successful)
      .getOrElse {
        underlying.retrieveLocalizedSystemMode(locale, systemMode).map { systemMode =>
          cache.put(key, systemMode)
          systemMode
        }
      }
  }

  override def getLocalizedPressure(unitSystemOrLocale: Either[String, UnitSystem],
                                    maybePressure: Option[Double]): String =
    underlying.getLocalizedPressure(unitSystemOrLocale, maybePressure)

  override def getLocalizedTemperature(unitSystemOrLocale: Either[String, UnitSystem],
                                       maybeTemperature: Option[Double]): String =
    underlying.getLocalizedTemperature(unitSystemOrLocale, maybeTemperature)

  override def getLocalizedRate(unitSystemOrLocale: Either[String, UnitSystem],
                                maybeWaterFlowRate: Option[Double]): String =
    underlying.getLocalizedRate(unitSystemOrLocale, maybeWaterFlowRate)

  override def getLocalizedVolume(unitSystemOrLocale: Either[String, UnitSystem], maybeVolume: Option[Double]): String =
    underlying.getLocalizedVolume(unitSystemOrLocale, maybeVolume)

  override def getTimeZone(device: Device, user: User): ZoneId = underlying.getTimeZone(device, user)

  override def getUnitSystemString(unitSystemOrLocale: Either[String, UnitSystem]): String =
    com.flo.localization.getUnitSystemString(unitSystemOrLocale)

  private def localizeArgs(args: Set[Arg],
                           locale: Locale,
                           unitSystem: UnitSystem,
                           alarmIncident: AlarmIncident,
                           user: User,
                           device: Device): Future[Map[String, String]] = {
    val fixedArgs   = args.collect { case a: FixedArg   => a }
    val staticArgs  = args.collect { case a: StaticArg  => a }
    val dynamicArgs = args.collect { case a: DynamicArg => a }

    val eventualFixedArgs   = localizeFixedArgs(fixedArgs)
    val eventualStaticArgs  = localizeStaticArgs(staticArgs, locale, unitSystem)
    val eventualDynamicArgs = localizeDynamicArgs(dynamicArgs, locale, unitSystem, alarmIncident, user, device)

    for {
      fixedArgs   <- eventualFixedArgs
      staticArgs  <- eventualStaticArgs
      dynamicArgs <- eventualDynamicArgs
    } yield {
      fixedArgs ++ staticArgs ++ dynamicArgs
    }
  }

  private def localizeStaticArgs(args: Set[StaticArg],
                                 locale: Locale,
                                 unitSystem: UnitSystem): Future[Map[String, String]] = {
    val unitSystemStr = unitSystem.toString.toLowerCase
    val cachedArgs = args.flatMap { arg =>
      val key = p"${arg.assetName(unitSystemStr)}.$locale"
      cache.getIfPresent(key).map(value => arg.name -> value)
    }.toMap

    val cachedArgsKeys = cachedArgs.keySet
    val nonCachedArgs  = args.filterNot(a => cachedArgsKeys.contains(a.name))

    if (nonCachedArgs.isEmpty) Future.successful(cachedArgs)
    else {
      val nonCachedAssetMap = nonCachedArgs.map { arg =>
        arg.assetName(unitSystemStr) -> arg.name
      }.toMap

      underlying.retrieveLocalizedTexts(nonCachedAssetMap.keySet, Display, locale, Map()).map { texts =>
        val textsWithArgName = texts.map {
          case (assetName, text) =>
            cache.put(p"$assetName.$locale", text)
            nonCachedAssetMap(assetName) -> text
        }

        cachedArgs ++ textsWithArgName
      }
    }
  }

  private def localizeFixedArgs(args: Set[FixedArg]): Future[Map[String, String]] =
    Future.successful {
      args.map { arg =>
        val argValue = arg match {
          case AppLink => "floapp://home"
        }
        arg.name -> argValue
      }.toMap
    }

  private def localizeDynamicArgs(args: Set[DynamicArg],
                                  locale: Locale,
                                  unitSystem: UnitSystem,
                                  alarmIncident: AlarmIncident,
                                  user: User,
                                  device: Device): Future[Map[String, String]] = {
    def maybeAsset(arg: DynamicArg, asset: => String): Option[String] =
      if (args(arg)) Some(asset) else None

    val systemModeName = SystemMode.toString(alarmIncident.systemMode)

    val systemModeAsset   = Assets.systemMode(alarmIncident.systemMode)
    val alarmDisplayAsset = Assets.alarmDisplayName(alarmIncident.alarmId, systemModeName)
    val previousAlertAsset =
      alarmIncident.resolvedAlarmIncident.map(r => Assets.alarmDisplayName(r.alarmId, systemModeName))
    val appTypeAsset    = alarmIncident.applicationType.map(appType => Assets.appType(appType))
    val dateFormatAsset = Assets.DateFormat

    val assets = Set(
      maybeAsset(IncidentDateTime, dateFormatAsset).orElse(maybeAsset(PreviousIncidentDateTime, dateFormatAsset)),
      maybeAsset(NewSystemMode, systemModeAsset),
      maybeAsset(AlarmDisplayName, alarmDisplayAsset),
      previousAlertAsset.flatMap { asset =>
        maybeAsset(PreviousAlertFriendlyName, asset)
      },
      appTypeAsset.flatMap { appType =>
        maybeAsset(AppType, appType)
      }
    ).flatten

    val eventualLocalizedTexts = retrieveLocalizedTexts(assets, localization.Display, locale, Map())

    eventualLocalizedTexts.map { localizedTexts =>
      args.map { arg =>
        val argValue = arg match {
          case IncidentDateTime =>
            formatDateTime(
              localizedTexts(dateFormatAsset),
              getTimeZone(device, user),
              locale,
              alarmIncident.timestamp
            )

          case PreviousAlertFriendlyName =>
            previousAlertAsset.map(localizedTexts(_)).getOrElse("")

          case PreviousIncidentDateTime =>
            alarmIncident.resolvedAlarmIncident.fold("") { resolvedAlarmIncident =>
              formatDateTime(
                localizedTexts(dateFormatAsset),
                getTimeZone(device, user),
                locale,
                resolvedAlarmIncident.timestamp
              )
            }

          case MaxTemperature =>
            localizeTemperature(unitSystem, alarmIncident.snapshot.tmax)

          case MinTemperature =>
            localizeTemperature(unitSystem, alarmIncident.snapshot.tmin)

          case FlowRate =>
            localizeRate(unitSystem, alarmIncident.snapshot.fr)

          case FlowDurationInMinutes =>
            alarmIncident.snapshot.efd.fold("") { eventFlowDuration =>
              TimeUnit.SECONDS.toMinutes(eventFlowDuration.toLong).toString
            }

          case FlowEvent =>
            localizeVolume(unitSystem, alarmIncident.snapshot.ef)

          case MinPressure =>
            localizePressure(unitSystem, alarmIncident.snapshot.pmin)

          case MaxPressure =>
            localizePressure(unitSystem, alarmIncident.snapshot.pmax)

          case AppType =>
            appTypeAsset.map(localizedTexts(_)).getOrElse("")

          case UserSmallName =>
            p"${user.firstName} ${user.lastName.headOption.fold("")(_ + ".")}"

          case NewSystemMode =>
            localizedTexts(systemModeAsset)

          case AlarmDisplayName =>
            localizedTexts(alarmDisplayAsset)

          case MinHumidity =>
            alarmIncident.snapshot.limitHumidityMin.map(roundValue).getOrElse("")

          case MaxHumidity =>
            alarmIncident.snapshot.limitHumidityMax.map(roundValue).getOrElse("")

          case MinBattery =>
            alarmIncident.snapshot.limitBatteryMin.map(_.toString).getOrElse("")

          case RecommendedPressure =>
            localizePressure(unitSystem, Some(DefaultRecommendedPressure))

          case DeviceNickname => device.nickname.getOrElse("")

          case LocationNickname => device.location.nickname.getOrElse("")

          case LocationDeviceHint => buildLocationDeviceHint(user, device).getOrElse("")
        }
        arg.name -> argValue
      }.toMap
    }
  }

  private def buildTextKey(assetName: String, assetType: localization.AssetType, locale: String): String =
    p"$assetName.$assetType.$locale"

  private def formatDateTime(pattern: String, zoneId: ZoneId, locale: String, timestamp: Long): String = {
    val formatter = DateTimeFormatter
      .ofPattern(pattern)
      .withLocale(java.util.Locale.forLanguageTag(locale))

    LocalDateTime
      .ofInstant(Instant.ofEpochMilli(timestamp), zoneId)
      .format(formatter)
      .replace("AM", "am")
      .replace("PM", "pm")
  }
}
