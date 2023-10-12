package MicroService

import Models.SubscriptionInfo
import Utils.ApplicationSettings
import com.flo.Enums.Subscription.SubscriptionStatuses
import com.flo.Models.ICDAlarmNotificationDeliveryRules
import com.flo.Models.KafkaMessages.EmailMessage
import com.flo.Models.Users.UserContactInformation

class CSMicroService {


  /**
    * CS emailgenerator
    **/
  def csEmailGenerator(em: EmailMessage, subscriptionInfo: Option[SubscriptionInfo]): EmailMessage = {
    val name = appendFloSenseIfDeviceHasIt(em.icd.get.deviceId.get, em.notification.get.messageTemplates.name)

    EmailMessage(
      id = em.id,
      ts = em.ts,
      notificationTime = em.notificationTime,
      notification = Some(em.notification.get.copy(messageTemplates = em.notification.get.messageTemplates.copy(
        friendlyName = friendlyNameGenerator(em.icd.get.deviceId.get, name, subscriptionInfo),
        name = friendlyNameGenerator(em.icd.get.deviceId.get, name, subscriptionInfo)
      ))),
      icd = em.icd,
      telemetry = em.telemetry,
      userContactInformation = csContactInformationGenerator(em.userContactInformation.get),
      location = em.location,
      statusCallback = em.statusCallback,
      friendlyDescription = em.friendlyDescription,
      None
    )

  }

  private def appendFloSenseIfDeviceHasIt(did: String, name: String): String = {
    if (ApplicationSettings.flo.floSenseDevices.contains(did.trim))
      s"[FS] $name"
    else
      name
  }

  private def friendlyNameGenerator(did: String, name: String, subscriptionInfo: Option[SubscriptionInfo]): String = subscriptionInfo match {
    case Some(sub) => s"$name (${did.toLowerCase}) [${getSubscriptionStatus(subscriptionInfo).toLowerCase}]"
    case _ => s"$name (${did.toLowerCase()}) [${getSubscriptionStatus(subscriptionInfo).toLowerCase}]"
  }

  private def getSubscriptionStatus(subscriptionInfo: Option[SubscriptionInfo]): String = subscriptionInfo match {
    case Some(sub) => reduceSubscriptionStatus(sub.subscription.status)
    case _ => "NS"
  }

  private def reduceSubscriptionStatus(status: String): String = status match {
    case SubscriptionStatuses.ACTIVE => "A"
    case SubscriptionStatuses.CANCELED => "C"
    case SubscriptionStatuses.PAST_DUE => "PD"
    case SubscriptionStatuses.TRAILING => "T"
    case SubscriptionStatuses.UNPAID => "UP"
    case _ => "NA"
  }

  /**
    * This method will modify the user's contact info by changing the email address to Flo's costumer service email address
    * it is a quick hack to send alarms users receive to zendesk.
    **/
  private def csContactInformationGenerator(c: UserContactInformation): Option[UserContactInformation] = {

    Some(
      UserContactInformation(
        userId = c.userId,
        prefixName = c.prefixName,
        firstName = c.firstName,
        middleName = c.middleName,
        lastName = c.lastName,
        suffixName = c.suffixName,
        phonePrimary = c.phonePrimary,
        phoneHome = c.phoneHome,
        phoneMobile = c.phoneMobile,
        phoneWork = c.phoneWork,
        email = Some("support@meetflo.zendesk.com"),
        unitSystem = c.unitSystem
      )
    )

  }


}
