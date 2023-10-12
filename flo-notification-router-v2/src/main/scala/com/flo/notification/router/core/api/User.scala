package com.flo.notification.router.core.api

import com.flo.Enums.GroupAccount.UserGroupAccountRoles

case class UserDevice(id: String)

case class UserLocation(id: String, devices: Seq[UserDevice])

case class User(id: String,
                firstName: String,
                lastName: String,
                email: String,
                phoneNumber: Option[String],
                unitSystem: Option[UnitSystem],
                locale: String,
                account: Account,
                groupId: Option[String],
                roles: Seq[String],
                locations: Seq[UserLocation]) {

  val isLandLord: Boolean =
    roles.contains(UserGroupAccountRoles.LANDLORD) || roles.contains(UserGroupAccountRoles.PROPERTY_MANAGER)

  val isTenant: Boolean =
    roles.contains(UserGroupAccountRoles.TENANT)
}
