package MicroService

import com.flo.Models.Location

class LocationService {

	def getFullAddress(location: Option[Location]): String = location match {
		case Some(loc) =>
			if (loc.address.isDefined && loc.address2.isDefined && loc.city.isDefined && loc.state.isDefined && loc.postalCode.isDefined) {
				s"${loc.address.get.trim} ${loc.address2.getOrElse("").trim} ${loc.city.get.trim}, ${loc.state.get.trim}, ${loc.postalCode.get.trim}"
			}
			else if (loc.address.isDefined && loc.city.isDefined && loc.state.isDefined && loc.postalCode.isDefined) {
				s"${loc.address.get.trim} ${loc.city.get.trim}, ${loc.state.get.trim}, ${loc.postalCode.get.trim}"
			}
			else if (loc.address.isDefined) {
				s"${loc.address.get.trim} ${loc.address2.getOrElse("").trim} ${loc.city.getOrElse("").trim} ${loc.state.getOrElse("").trim} ${loc.postalCode.getOrElse("").trim}".trim
			}
			else
				""
		case None => ""
	}

	def getShortAddress(location: Option[Location]): String = location match {
		case Some(loc) =>
			if (loc.address.isDefined && loc.address.nonEmpty) {
				val address2 = if (loc.address2.isDefined && loc.address2.nonEmpty) s" ${loc.address2.get}"
				s"${loc.address.get.trim}$address2"
			} else ""
		case _ => ""

	}

	def getZip(location: Option[Location]): String = location match {
		case Some(loc) =>
			if (loc.postalCode.isDefined && loc.postalCode.nonEmpty) loc.postalCode.get else ""
		case _ => ""
	}

	def getState(location: Option[Location]): String = location match {
		case Some(loc) =>
			if (loc.state.isDefined && loc.state.nonEmpty) loc.state.get else ""
		case _ => ""
	}

	def getAddress(location: Option[Location]): String = location match {
		case Some(loc) =>
			if (loc.address.isDefined && loc.address.nonEmpty) loc.address.get else ""
		case _ => ""
	}

	def getCity(location: Option[Location]): String = location match {
		case Some(loc) =>
			if (loc.city.isDefined && loc.city.nonEmpty) loc.city.get else ""
		case _ => ""
	}

	def getAddress2(location: Option[Location]): String = location match {
		case Some(loc) =>
			if (loc.address2.isDefined && loc.address2.nonEmpty) loc.address2.get else ""
		case _ => ""
	}

	def getTimezone(location: Option[Location]): String = location match {
		case Some(loc) =>
			if (loc.timezone.isDefined && loc.timezone.nonEmpty) loc.timezone.get
			else throw new IllegalArgumentException(s"location id: ${loc.locationId.getOrElse("N/A")} doesn't have timezone property.")
		case _ =>
			throw new IllegalArgumentException(s"location argument did not match the expected Option[Location] param")
	}

}
