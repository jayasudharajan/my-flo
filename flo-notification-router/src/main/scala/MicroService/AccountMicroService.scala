package MicroService

import com.flo.Models.AccountSubscription
import com.flo.Models.Analytics.DeviceInfo

class AccountMicroService {


  def getPlanIdFromAccountSubscription(sub: Option[AccountSubscription]): String = sub match {
    case Some(accountSubscription) =>
      accountSubscription.plaId
    case _ => ""
  }

  def getAccountIdByDeviceId(deviceId: String, deviceInfo: Option[DeviceInfo]): String = {
    accountIdByDeviceId(deviceId, deviceInfo).getOrElse("")
  }

  /**
    * This method returns the account id for a device id, it returns None otherwise
    */
  private def accountIdByDeviceId(deviceId: String, deviceInfo: Option[DeviceInfo]): Option[String] = deviceInfo match {
    case Some(info) =>
      val s = info.devices.find(d => d.deviceId == deviceId).map(_.accountInfo) flatMap (_.get.accountId)
      s

    case _ => None
  }

}
