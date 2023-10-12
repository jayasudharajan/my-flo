package MicroService

import com.flo.Enums.GroupAccount.UserGroupAccountRoles
import com.flo.Enums.Notifications.AlarmSeverity
import com.flo.Models.Logs.ICDAlarmIncidentRegistryUser
import com.flo.Models.{AccountGroupAlarmNotificationDeliveryRule, ICD, ICDAlarmNotificationDeliveryRules, ICDAlarmNotificationFilterSettings}
import com.flo.Models.Users.UserAlarmNotificationDeliveryRules

import scala.collection.parallel.mutable.ParSet

class ICDAlarmNotificationDeliveryRuleService {


  def getGroupAccountDRMediums(gADR: Option[AccountGroupAlarmNotificationDeliveryRule]): Option[Set[Int]] = gADR match {
    case Some(deliveryRule) => Some(deliveryRule.optional)
    case _ => None
  }


  def getGroupAccountDRByRole(rules: Option[Set[AccountGroupAlarmNotificationDeliveryRule]], role: String): Option[AccountGroupAlarmNotificationDeliveryRule] = rules match {
    case Some(groupAccountRules) => groupAccountRules.find(rule => rule.userRole == role)
    case _ => None
  }

  def getUserIdsWithoutDrs(userIds: Set[String], userRules: ParSet[UserAlarmNotificationDeliveryRules]): Set[String] = {
    var usersWithoutDrs = Set[String]()
    userIds.foreach(id => {
      if (!userRules.exists(userDR => userDR.userId == id))
        usersWithoutDrs.+=(id)
    })
    usersWithoutDrs
  }


  /**
    * This is a combinator function it creates a temporary UserAlarmNotificationDeliveryRules for users that have not
    * created one yet. It uses the alarm notification delivery rules as a base to create the temporary
    * UserAlarmNotificationDeliveryRules, so it is easier to run in parallel. NOTE: these objects do not et persisted to
    * DB and are only available in the scope this function is called.
    */
  def UsersAlarmNotificationRuleDeliveryPreferencesGenerator(userIds: Set[String], iCDAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules, userAlarmNotificationDeliveryRules: Set[UserAlarmNotificationDeliveryRules], icd: ICD, accountGroupDR: Option[Set[AccountGroupAlarmNotificationDeliveryRule]], landLordUserIds: Set[String], propertyManagersId: Set[String], isManage: Boolean): Option[ParSet[UserAlarmNotificationDeliveryRules]] = {
    var userAlarmNotificationDeliveryRulesP = ParSet[UserAlarmNotificationDeliveryRules]()

    userAlarmNotificationDeliveryRules.foreach((rule) => {
      userAlarmNotificationDeliveryRulesP += userAlarmNotificationDeliveryRulesReviser(rule, iCDAlarmNotificationDeliveryRules)
    })
    val landlordDR = getGroupAccountDRByRole(accountGroupDR, UserGroupAccountRoles.LANDLORD)
    val propertyManagerDR = getGroupAccountDRByRole(accountGroupDR, UserGroupAccountRoles.PROPERTY_MANAGER)
    val usersWithoutDrsIds = getUserIdsWithoutDrs(userIds, userAlarmNotificationDeliveryRulesP)

    userAlarmNotificationDeliveryRulesP = userAlarmNotificationDeliveryRulesP ++ getUserALarmNotificationDeliveryRuleForUsersForAll(landlordDR, propertyManagerDR, iCDAlarmNotificationDeliveryRules, icd, landLordUserIds, propertyManagersId, usersWithoutDrsIds)
    Some(userAlarmNotificationDeliveryRulesP)
  }

  private def getUserALarmNotificationDeliveryRuleForUsersForAll(landlordDR: Option[AccountGroupAlarmNotificationDeliveryRule], propertyManagerDR: Option[AccountGroupAlarmNotificationDeliveryRule], iCDAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules, iCD: ICD, landLordUserIds: Set[String], propertyManagersId: Set[String], userIds: Set[String]): ParSet[UserAlarmNotificationDeliveryRules] = {

    val landlords = getUserAlarmNotificationDeliveryRuleForUsersByGroupAccountRole(landLordUserIds, iCD, iCDAlarmNotificationDeliveryRules, landlordDR, UserGroupAccountRoles.LANDLORD)
    val propertyManagers = getUserAlarmNotificationDeliveryRuleForUsersByGroupAccountRole(propertyManagersId, iCD, iCDAlarmNotificationDeliveryRules, propertyManagerDR, UserGroupAccountRoles.PROPERTY_MANAGER)
    val users = getUserAlarmNotificationDeliveryRuleForUsers(userIds, iCD, iCDAlarmNotificationDeliveryRules)

    landlords ++ users ++ propertyManagers
  }

  private def getUserAlarmNotificationDeliveryRuleForUsersByGroupAccountRole(userIds: Set[String], icd: ICD, iCDAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules, groupAccountDR: Option[AccountGroupAlarmNotificationDeliveryRule], role: String): ParSet[UserAlarmNotificationDeliveryRules] = {
    var userAlarmNotificationDeliveryRulesP = ParSet[UserAlarmNotificationDeliveryRules]()
    userIds.foreach((id) => {

      userAlarmNotificationDeliveryRulesP += new UserAlarmNotificationDeliveryRules(
        userId = id,
        locationId = icd.locationId.get,
        alarmId = iCDAlarmNotificationDeliveryRules.alarmId,
        systemMode = iCDAlarmNotificationDeliveryRules.systemMode,
        severity = iCDAlarmNotificationDeliveryRules.severity,
        mandatory = None,
        optional = getGroupAccountDRMediums(groupAccountDR),
        filterSettings = groupAccountDR match {
          case Some(landlord) => Some(landlord.filterSettings)
          case _ => iCDAlarmNotificationDeliveryRules.filterSettings
        },
        graveyardTime = groupAccountDR match {
          case Some(landlord) => Some(landlord.graveyardTime)
          case _ => iCDAlarmNotificationDeliveryRules.graveyardTime
        },
        internalId = iCDAlarmNotificationDeliveryRules.internalId,
        isMuted = Some(false)
      )

    })
    userAlarmNotificationDeliveryRulesP
  }

  private def getUserAlarmNotificationDeliveryRuleForUsers(userIds: Set[String], icd: ICD, iCDAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules): ParSet[UserAlarmNotificationDeliveryRules] = {
    var userAlarmNotificationDeliveryRulesP = ParSet[UserAlarmNotificationDeliveryRules]()
    userIds.foreach((id) => {

      userAlarmNotificationDeliveryRulesP += new UserAlarmNotificationDeliveryRules(
        userId = id,
        locationId = icd.locationId.get,
        alarmId = iCDAlarmNotificationDeliveryRules.alarmId,
        systemMode = iCDAlarmNotificationDeliveryRules.systemMode,
        severity = iCDAlarmNotificationDeliveryRules.severity,
        mandatory = None,
        optional = iCDAlarmNotificationDeliveryRules.mandatory,
        filterSettings = iCDAlarmNotificationDeliveryRules.filterSettings,
        graveyardTime = iCDAlarmNotificationDeliveryRules.graveyardTime,
        internalId = iCDAlarmNotificationDeliveryRules.internalId,
        isMuted = Some(false)
      )

    })
    userAlarmNotificationDeliveryRulesP
  }


  /**
    * This method is used to  add the defaul ICDAlarmNotificationDeliveryRules's graveyard time and filter settings to
    * the USER ICD ALARM NOTIFICATION DELIVERY RULES in case they do not have it.
    */
  def userAlarmNotificationDeliveryRulesReviser(uRule: UserAlarmNotificationDeliveryRules, icdRule: ICDAlarmNotificationDeliveryRules): UserAlarmNotificationDeliveryRules = {
    new UserAlarmNotificationDeliveryRules(
      userId = uRule.userId,
      locationId = uRule.locationId,
      alarmId = uRule.alarmId,
      systemMode = uRule.systemMode,
      severity = uRule.severity,
      mandatory = None,
      optional = if (!icdRule.isUserOverwritable) icdRule.mandatory else uRule.optional,
      filterSettings = if (uRule.filterSettings.isEmpty || !icdRule.isUserOverwritable) icdRule.filterSettings else uRule.filterSettings,
      graveyardTime = if (uRule.graveyardTime.isEmpty || !icdRule.isUserOverwritable) icdRule.graveyardTime else uRule.graveyardTime,
      internalId = if (uRule.internalId < 1) icdRule.internalId else uRule.internalId,
      isMuted = if (uRule.isMuted.isDefined && uRule.isMuted.nonEmpty) uRule.isMuted else Some(false)
    )
  }

  /**
    * For record keeping we store some user data info to the incendent logs this functions transalates full user objects
    * compact user objects to use with the incident logs.
    */
  def ICDAlarmIncidentRegistryUserGenerator(preferences: Option[ParSet[UserAlarmNotificationDeliveryRules]]): Option[Set[ICDAlarmIncidentRegistryUser]] = preferences match {
    case Some(userPreferences) =>
      var icdAlarmIncidentUsers = Set[ICDAlarmIncidentRegistryUser]()

      userPreferences.foreach((p) => {

        icdAlarmIncidentUsers += ICDAlarmIncidentRegistryUser(
          p.userId,
          deliveryPreferences = {
            p.optional.getOrElse(Set[Int]())
          }
        )
      })
      Some(icdAlarmIncidentUsers)
    case None =>
      throw new IllegalArgumentException("No users related to the icd in notification were found")
  }

  def getUserAlarmFilterSettings(userFilterSettings: Option[ICDAlarmNotificationFilterSettings], icdFilterSettings: Option[ICDAlarmNotificationFilterSettings], alarmId: Int, systemMode: Int): ICDAlarmNotificationFilterSettings = userFilterSettings match {
    case Some(userSettings) => userSettings
    case _ => icdFilterSettings.getOrElse(throw new Exception(s"No Filter Settings found for $alarmId systemMode: $systemMode"))
  }

  /**
    * Temporary way to inject different email templates to properties
    */
  def getLandlordRulesFromRegularRules(iCDAlarmNotificationDeliveryRules: ICDAlarmNotificationDeliveryRules): ICDAlarmNotificationDeliveryRules = iCDAlarmNotificationDeliveryRules.severity match {
    case AlarmSeverity.HIGH =>
      iCDAlarmNotificationDeliveryRules.copy(messageTemplates = iCDAlarmNotificationDeliveryRules.messageTemplates.copy(emailProperties = iCDAlarmNotificationDeliveryRules.messageTemplates.emailProperties.copy(templateId = "tem_TjJcFrWkGCPFMkQBRpygYGFP")))
    case AlarmSeverity.MEDIUM =>
      iCDAlarmNotificationDeliveryRules.copy(messageTemplates = iCDAlarmNotificationDeliveryRules.messageTemplates.copy(emailProperties = iCDAlarmNotificationDeliveryRules.messageTemplates.emailProperties.copy(templateId = "tem_CwpGGvCdqRcKPt6wyTddtQCb")))
    case AlarmSeverity.LOW =>
      iCDAlarmNotificationDeliveryRules.copy(messageTemplates = iCDAlarmNotificationDeliveryRules.messageTemplates.copy(emailProperties = iCDAlarmNotificationDeliveryRules.messageTemplates.emailProperties.copy(templateId = "tem_qQfDvFByHTkKwMRbJVhxcgGB")))
    case _ =>
      iCDAlarmNotificationDeliveryRules.copy(messageTemplates = iCDAlarmNotificationDeliveryRules.messageTemplates.copy(emailProperties = iCDAlarmNotificationDeliveryRules.messageTemplates.emailProperties.copy(templateId = "tem_qQfDvFByHTkKwMRbJVhxcgGB")))
  }


}
