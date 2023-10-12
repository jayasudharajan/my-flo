package MicroService.Email

import com.flo.Enums.ValveModes
import com.flo.Models.ICD

class ICDMapService {
	def getDeviceId(iCD: Option[ICD]): String = iCD match {
		case Some(icd) =>
			if (icd.deviceId.isDefined && icd.deviceId.nonEmpty)
				icd.deviceId.get
			else "N/A"
		case _ => "N/A"
	}

	def getICDId(iCD: Option[ICD]): String = iCD match {
		case Some(icd) =>
			if (icd.id.isDefined && icd.id.nonEmpty)
				icd.id.get
			else "N/A"
		case _ =>
			"N/A"
	}

	def getSystemMode(systemMode: Int): String = systemMode match {
		case ValveModes.VACATION =>
			"vacation"
		case ValveModes.UNKNOWN =>
			"unknown"
		case ValveModes.MANUAL =>
			"manual"
		case ValveModes.HOME =>
			"home"
		case ValveModes.AUTORUN =>
			"autorun"
		case ValveModes.AWAY =>
			"away"
		case _ =>
			"unknown"
	}

}
