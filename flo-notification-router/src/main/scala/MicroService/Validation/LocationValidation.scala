package MicroService.Validation

import com.flo.Models.Location
import argonaut.Argonaut._

class LocationValidation {

  def validateLocation(loc: Option[Location]): Either[Throwable, Boolean] = loc match {
    case Some(location) =>
      if (location.accountId.isEmpty
        || location.timezone.isEmpty
        || location.locationId.isEmpty
      ) Left(throw new IllegalArgumentException(s"accountID, timezone, locationId are required for location location json: ${location.asJson}"))
      Right(true)
    case _ => Left(throw new IllegalArgumentException("location is NONE"))
  }

}
