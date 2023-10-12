package MicroService

import com.flo.Models.Analytics.{DeviceInfo, DeviceInfoItem}
import com.flo.Models.KafkaMessages.Components.ICDAlarmIncident.ICDAlarmIncidentDataSnapshot
import com.flo.Models.{ICD, Location}

class DeviceInfoMicroService() {

  def getLocationId(deviceInfo: DeviceInfoItem): String = deviceInfo.geoLocation match {
    case Some(loc) => loc.locationId
    case _ => throw new Exception(s"DeviceInfo for ${deviceInfo.deviceId} doesn't have geo location information")
  }

  def getDeviceInfoByDeviceId(deviceInfo: Option[DeviceInfo], did: String): DeviceInfoItem = deviceInfo match {
    case Some(info) => info.devices.find(device => device.deviceId == did).getOrElse(throw new Exception(s"Device did: $did is not paired"))
    case _ =>
      throw new Exception(s"Device did: $did is not paired")
  }

  def getLocationFromGeoLocation(deviceInfoItem: DeviceInfoItem): Option[Location] = deviceInfoItem.geoLocation match {
    case Some(geo) => Some(Location(
      accountId = Some(getAccountId(deviceInfoItem)),
      locationId = Some(getLocationId(deviceInfoItem)),
      address = geo.address1,
      address2 = geo.address2,
      city = geo.city,
      state = geo.stateOrProvince,
      postalCode = geo.postalCode,
      country = geo.country,
      timezone = geo.timeZone,
      locationName = None,
      locationType = None,
      stories = None,
      locationSize = None,
      locationSizeCategory = None,
      bathroomAmenities = None,
      bathrooms = None,
      occupants = None,
      kitchenAmenities = None,
      outdoorAmenities = None,
      tankless = None,
      expansionTank = None,
      profileCompleted = None
    ))
    case _ => throw new Exception(s"device info for did ${deviceInfoItem.deviceId} doesn't have geo location info")

  }

  def getICD(deviceInfoItem: DeviceInfoItem, snapshot: ICDAlarmIncidentDataSnapshot): Option[ICD] = {
    Some(
      ICD(
        deviceId = Some(deviceInfoItem.deviceId),
        timeZone = getTimeZone(deviceInfoItem),
        systemMode = snapshot.systemMode,
        localTime = snapshot.localTime,
        id = Some(deviceInfoItem.icdId),
        locationId = Some(getLocationId(deviceInfoItem))
      )
    )
  }

  def getICDUser(deviceInfoItem: DeviceInfoItem): Set[String] = {
    deviceInfoItem.users map (_.userId)
  }

  def getAccountId(deviceInfoItem: DeviceInfoItem): String = deviceInfoItem.accountInfo match {
    case Some(accountInfo) => accountInfo.accountId.getOrElse(throw new Exception(s"deviceinfo  for did ${deviceInfoItem.deviceId} has no account id"))
    case _ => throw new Exception(s"deviceinfo  for did ${deviceInfoItem.deviceId} has no account id")
  }

  def getTimeZone(deviceInfoItem: DeviceInfoItem): Option[String] = getLocationFromGeoLocation(deviceInfoItem) match {
    case Some(loc) => loc.timezone
    case _ => throw new Exception(s"Deviceinfo for did ${deviceInfoItem.deviceId} has no Time zone information")

  }


}
