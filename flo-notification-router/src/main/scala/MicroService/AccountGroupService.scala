package MicroService

import com.flo.Enums.GroupAccount.UserGroupAccountRoles
import com.flo.Models.Analytics.DeviceInfo
import com.flo.Models.Users.UserAccountGroupRole
import com.typesafe.scalalogging.LazyLogging

class AccountGroupService extends LazyLogging{

  def isPropertyManaged(roles: Option[Set[UserAccountGroupRole]]): Boolean = roles match {
    case Some(accountGroupRoles) =>
      val rol = accountGroupRoles.find(role => role.roles.contains(UserGroupAccountRoles.LANDLORD))
      rol.isDefined && rol.nonEmpty

    case _ =>
      false
  }

  def getAccountGroupUserIdsByRole(accountGroupRoles: Option[Set[UserAccountGroupRole]], groupAccountRole: String): Set[String] = {
    var accountGroupRoleUserIds = Set[String]()
    if (accountGroupRoles.isDefined && accountGroupRoles.nonEmpty) {
      val ids = accountGroupRoles.get.filter(role => role.roles.contains(groupAccountRole))
      ids.foreach(id => accountGroupRoleUserIds += id.userId)
    }

    accountGroupRoleUserIds
  }
  def getGroupIdFromDeviceInfo(deviceInfo: Option[DeviceInfo], did: String): String = deviceInfo match {
    case Some(d) =>
      var groupID = ""
      if (d.devices.nonEmpty) {
        if (d.devices.head.accountInfo.isDefined && d.devices.head.accountInfo.nonEmpty) {
          groupID = d.devices.head.accountInfo.get.groupId.getOrElse("")
          if (groupID.isEmpty) logger.info(s"did: $did didn't return any group id info in  account info /  device info")
        }
        else logger.info(s"did: $did didn't return account info in  device info")
      }
      else logger.info(s"did: $did didn't return device info")
      groupID
    case _ =>
      ""
  }
}
