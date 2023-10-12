package com.flo

import com.flo.notification.router.core.api._
import perfolation._

package object localization {
  private val UsLocale      = "en-us"
  private val LiberiaLocale = "en-lr"
  private val MyanmarLocale = "my-mm"

  private val ImperialStr = Imperial.toString.toLowerCase
  private val MetricStr   = Metric.toString.toLowerCase

  val DefaultRecommendedPressure: Double = 80.0

  def getUnitSystem(unitSystemOrLocale: Either[String, UnitSystem]): UnitSystem =
    unitSystemOrLocale match {
      case Left(locale) =>
        locale.toLowerCase match {
          case UsLocale | LiberiaLocale | MyanmarLocale => Imperial
          case _                                        => Metric
        }
      case Right(unitSystem) if unitSystem == Metric => Metric
      case _                                         => Imperial
    }

  def getUnitSystemString(unitSystemOrLocale: Either[String, UnitSystem]): String =
    getUnitSystemString(getUnitSystem(unitSystemOrLocale))

  def getUnitSystemStringOrDefault(maybeUnitSystem: Option[UnitSystem]): String =
    maybeUnitSystem.fold(ImperialStr) { unitSystem =>
      if (unitSystem == Imperial) ImperialStr else MetricStr
    }

  def getUnitSystemString(unitSystem: UnitSystem): String = unitSystem match {
    case Imperial => ImperialStr
    case Metric   => MetricStr
  }

  def getUnitSystemString(isImperialUnitSystem: Boolean): String =
    if (isImperialUnitSystem) ImperialStr else MetricStr

  def localizeTemperature(unitSystem: UnitSystem, maybeTemperature: Option[Double]): String =
    maybeTemperature.fold("") { temperature =>
      unitSystem match {
        case Imperial => roundValue(temperature)
        case Metric   => roundValue((temperature - 32) * 5 / 9) // Celsius
      }
    }

  def localizePressure(unitSystem: UnitSystem, maybePressure: Option[Double]): String =
    maybePressure.fold("") { pressure =>
      unitSystem match {
        case Imperial => roundValue(pressure)
        case Metric   => roundValue(pressure * 6.89476) // kPa
      }
    }

  def localizeVolume(unitSystem: UnitSystem, maybeVolume: Option[Double]): String =
    maybeVolume.fold("") { volume =>
      unitSystem match {
        case Imperial => roundValue(volume)
        case Metric   => roundValue(volume * 3.7854) // Liters
      }
    }

  def localizeRate(unitSystem: UnitSystem, maybeWaterFlowRate: Option[Double]): String =
    maybeWaterFlowRate.fold("") { waterFlowRate =>
      unitSystem match {
        case Imperial => roundValue(waterFlowRate)
        case Metric   => roundValue(waterFlowRate * 3.7854) // LPM
      }
    }

  def roundValue(value: Double): String = {
    val decimals   = ((value - value.toInt) * 100).toInt
    val hasDecimal = decimals != 0

    if (hasDecimal) f"$value%.1f" else value.toInt.toString
  }

  def buildLocationDeviceHint(user: User, device: Device): Option[String] =
    if (user.locations.size == 1) {
      if (user.locations.head.devices.size == 1) None
      else device.nickname.map(n => p"(${abbreviate(n)})")

    } else {
      val locationHint = device.location.nickname.getOrElse {
        Seq(
          Option(device.location.address),
          device.location.address2,
          Option(device.location.city),
          device.location.state,
          Option(device.location.postalCode)
        ).flatten
          .mkString(" ")
      }

      // Enterprise users will not have locations populated for performance reasons.
      val maybeDeviceHint = user.locations.headOption
        .fold(device.nickname) { _ =>
          user.locations
            .find(_.id == device.location.id)
            .flatMap { l =>
              if (l.devices.size == 1) None
              else device.nickname
            }
        }

      Option(
        Seq(
          Option(locationHint).map(abbreviate(_)),
          maybeDeviceHint.map(abbreviate(_))
        ).flatten
          .mkString("(", ", ", ")")
      )
    }

  def abbreviate(str: String, maxWidth: Int = 32): String =
    if (str.length <= maxWidth) str
    else p"${str.take(maxWidth)}..."
}
