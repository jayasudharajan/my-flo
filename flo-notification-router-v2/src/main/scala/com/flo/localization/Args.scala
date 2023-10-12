package com.flo.localization

import ca.mrvisser.sealerate.values

// TODO: Should this be private to localization package? It may need to be defined in core and asset <-> arg mapping be done in localization.
private[localization] object Args {

  sealed trait Arg {
    val name: String
    override def toString: String = name
  }

  sealed trait FixedArg extends Arg
  sealed trait StaticArg extends Arg {
    def assetName(suffix: String): String
  }
  sealed trait DynamicArg extends Arg

  case object AppLink extends FixedArg {
    val name = "app_link"
  }

  case object VolumeAbbreviation extends StaticArg {
    val name                                       = "volume_abbrev"
    override def assetName(suffix: String): String = Assets.volumeAbbrev(suffix)
  }
  case object VolumeName extends StaticArg {
    val name                                       = "volume_name"
    override def assetName(suffix: String): String = Assets.volumeName(suffix)
  }
  case object PressureAbbreviation extends StaticArg {
    val name                                       = "pressure_abbrev"
    override def assetName(suffix: String): String = Assets.pressureAbbrev(suffix)
  }
  case object PressureName extends StaticArg {
    val name                                       = "pressure_name"
    override def assetName(suffix: String): String = Assets.pressureName(suffix)
  }
  case object TemperatureAbbreviation extends StaticArg {
    val name                                       = "temperature_abbrev"
    override def assetName(suffix: String): String = Assets.temperatureAbbrev(suffix)
  }
  case object TemperatureName extends StaticArg {
    val name                                       = "temperature_name"
    override def assetName(suffix: String): String = Assets.temperatureName(suffix)
  }
  case object TemperatureUnitSystem extends StaticArg {
    val name                                       = "temp_unit_system"
    override def assetName(suffix: String): String = Assets.temperatureAbbrev(suffix)
  }
  case object RateName extends StaticArg {
    val name                                       = "rate_name"
    override def assetName(suffix: String): String = Assets.rateName(suffix)
  }
  case object RateAbbreviation extends StaticArg {
    val name                                       = "rate_abbrev"
    override def assetName(suffix: String): String = Assets.rateAbbrev(suffix)
  }

  case object IncidentDateTime extends DynamicArg {
    val name = "incident_date_time"
  }
  case object PreviousAlertFriendlyName extends DynamicArg {
    val name = "previous_alert_friendly_name"
  }
  case object PreviousIncidentDateTime extends DynamicArg {
    val name = "previous_incident_date_time"
  }
  case object MaxTemperature extends DynamicArg {
    val name = "max_temperature"
  }
  case object MinTemperature extends DynamicArg {
    val name = "min_temperature"
  }
  case object FlowRate extends DynamicArg {
    val name = "flow_rate"
  }
  case object FlowDurationInMinutes extends DynamicArg {
    val name = "flow_duration"
  }

  case object FlowEvent extends DynamicArg {
    val name = "flow_event"
  }
  case object MinPressure extends DynamicArg {
    val name = "min_pressure"
  }
  case object MaxPressure extends DynamicArg {
    val name = "max_pressure"
  }
  case object AppType extends DynamicArg {
    val name = "app_type"
  }
  case object UserSmallName extends DynamicArg {
    val name = "user_small_name"
  }
  case object NewSystemMode extends DynamicArg {
    val name = "new_system_mode"
  }
  case object AlarmDisplayName extends DynamicArg {
    val name = "alarm_display_name"
  }
  case object MaxHumidity extends DynamicArg {
    val name = "max_humidity"
  }
  case object MinHumidity extends DynamicArg {
    val name = "min_humidity"
  }
  case object MinBattery extends DynamicArg {
    val name = "min_battery"
  }
  case object RecommendedPressure extends DynamicArg {
    val name = "recommended_pressure"
  }

  case object DeviceNickname extends DynamicArg {
    val name = "device_nickname"
  }

  case object LocationNickname extends DynamicArg {
    val name = "location_nickname"
  }

  case object LocationDeviceHint extends DynamicArg {
    val name = "location_device_hint"
  }

  val fixed: Set[FixedArg] = values[FixedArg]

  val static: Set[StaticArg] = values[StaticArg]

  val dynamic: Set[DynamicArg] = values[DynamicArg]

  val all: Set[Arg] = fixed ++ static ++ dynamic
}
