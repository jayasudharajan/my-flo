package MicroService.Email

import MicroService.LocationService
import com.flo.Models.Location
import com.flo.Models.Users.UserContactInformation

class UserMapService {
	lazy private val locationService = new LocationService()

	def getZip(location: Option[Location]): String = locationService.getZip(location)

	def getState(location: Option[Location]): String = locationService.getState(location)

	def getAddress(location: Option[Location]): String = locationService.getAddress(location)

	def getCity(location: Option[Location]): String = locationService.getCity(location)

	def getAddress2(location: Option[Location]): String = locationService.getAddress2(location)

	def getFullAddress(location: Option[Location]): String = locationService.getFullAddress(location)

	def getFirstName(userInfo: Option[UserContactInformation]): String = userInfo match {
		case Some(info) =>
			if (info.firstName.isDefined && info.firstName.nonEmpty)
				info.firstName.get
			else
				""
		case _ =>
			"N/A"
	}

	def getLastName(userInfo: Option[UserContactInformation]): String = userInfo match {
		case Some(info) =>
			if (info.lastName.isDefined && info.lastName.nonEmpty)
				info.lastName.get
			else
				""
		case _ =>
			""
	}

}
