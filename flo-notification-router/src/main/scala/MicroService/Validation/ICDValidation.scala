package MicroService.Validation

import com.flo.Models.ICD
import argonaut.Argonaut._

class ICDValidation {

  def validateIcd(iCD: Option[ICD]): Either[Throwable, Boolean] = iCD match {
    case Some(icd) =>
      if (icd.deviceId.isEmpty
        || icd.id.isEmpty
        || icd.locationId.isEmpty
      ) Left(throw new IllegalArgumentException(s" Deviceid, icdId, location id are required icd json: ${icd.asJson} "))
      else Right(true)
    case _ => throw new IllegalArgumentException("icd is none")
  }

}
