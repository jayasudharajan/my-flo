package com.flo.notification.router.core.api.localization

import java.time.ZoneId

import com.flo.notification.router.core.api.{
  AlarmId,
  AlarmIncident,
  Device,
  SystemModeName,
  TitleAndMessage,
  UnitSystem,
  User
}

import scala.concurrent.Future

trait LocalizationService {

  def retrieveAvailableLocales(): Future[Set[Locale]]

  def retrieveLocalizedAlarmMessage(locale: Locale,
                                    alarmId: Int,
                                    systemMode: String,
                                    args: LocalizationArgs): Future[String]

  def retrieveLocalizedAlarmTitle(locale: Locale, alarmId: Int, systemMode: String): Future[String]

  def retrieveLocalizedAlarmTitleAndMessage(
      alarmId: AlarmId,
      systemModeName: SystemModeName,
      args: Map[Locale, Map[UnitSystem, LocalizationArgs]]
  ): Future[Map[TitleAndMessage, (Set[Locale], Set[UnitSystem])]]

  def retrieveLocalizedAlarmDisplayName(locale: Locale, alarmId: Int, systemMode: String): Future[String]

  def retrieveLocalizedAlarmDisplayDescription(locale: Locale, alarmId: Int, systemMode: String): Future[String]

  def retrieveLocalizedText(assetName: AssetName,
                            assetType: AssetType,
                            locale: Locale,
                            args: LocalizationArgs): Future[String]

  def retrieveLocalizedTexts(assetNames: Set[AssetName],
                             assetType: AssetType,
                             locale: Locale,
                             args: LocalizationArgs): Future[Map[AssetName, String]]

  def retrieveLocalizedSystemMode(locale: Locale, systemMode: Int): Future[String]

  def buildDefaultLocalizedArgs(alarmIncident: AlarmIncident, user: User, device: Device): Future[Map[String, String]]

  def buildDefaultFullyLocalizedArgs(alarmIncident: AlarmIncident,
                                     user: User,
                                     device: Device): Future[Map[Locale, Map[UnitSystem, Map[String, String]]]]

  def getLocalizedPressure(unitSystemOrLocale: Either[String, UnitSystem], maybePressure: Option[Double]): String

  def getLocalizedTemperature(unitSystemOrLocale: Either[String, UnitSystem], maybeTemperature: Option[Double]): String

  def getLocalizedRate(unitSystemOrLocale: Either[String, UnitSystem], maybeWaterFlowRate: Option[Double]): String

  def getLocalizedVolume(unitSystemOrLocale: Either[String, UnitSystem], maybeVolume: Option[Double]): String

  def getTimeZone(device: Device, user: User): ZoneId

  def getUnitSystemString(unitSystemOrLocale: Either[String, UnitSystem]): String
}
