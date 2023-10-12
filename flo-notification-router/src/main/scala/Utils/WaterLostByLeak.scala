package Utils

import com.flo.Enums.Locale.VolumeUnitSystemAbbreviation
import com.flo.Models.Locale.MeasurementUnitSystem

object WaterLostByLeak {
	private val waterLostByLeakInGallons = Map(
		28 -> 250.0,
		29 -> 100.0,
		30 -> 25.0,
		31 -> 5.0
	)

	def getByAlertId(alertId: Int, unitSystem: MeasurementUnitSystem): Option[Int] = {
		waterLostByLeakInGallons
			.get(alertId)
			.map(value => convertVolumeFromUSImperial(
				value,
				unitSystem.units.volume.abbrev
			).toInt)
	}

	private def convertVolumeFromUSImperial(gallons: Double, unit: String): Double = unit match {
		case VolumeUnitSystemAbbreviation.LITER =>
			gallons * 3.78541
		case _ => gallons
	}
}