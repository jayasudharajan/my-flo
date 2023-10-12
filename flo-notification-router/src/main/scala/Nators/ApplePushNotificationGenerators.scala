package Nators

import MicroService.DecisionEngineService
import Models.Mediums.{AppleMobileDeviceMessage, PushNotificationChoreographerMessage}
import com.flo.Models.ICD
import com.flo.Models.Locale.MeasurementUnitSystem

class ApplePushNotificationGenerators(unitSystem: MeasurementUnitSystem) {
  private lazy val decisionEngineService = new DecisionEngineService(unitSystem)

  def appleMobileDeviceMessageFromChoreographerMessage(msg: PushNotificationChoreographerMessage): AppleMobileDeviceMessage = {
    val snapshot = msg.icdAlarmIncidentMessage.data.snapshot
    AppleMobileDeviceMessage(
      notificationInfo = decisionEngineService.AppDeviceInfoGetNonDeleted(
        msg.appDeviceInfo
      ),
      applePushNotification = decisionEngineService.ApplePushNotificationObjectGenerator(
        msg.icdAlarmNotificationDeliveryRules,
        iCDAlarmIncidentRegistry = msg.createIcdIncidentRegistryRecord.get,
        icd = ICD(
          deviceId = Some(msg.icdAlarmIncidentMessage.deviceId),
          timeZone = snapshot.timeZone,
          systemMode = snapshot.systemMode,
          localTime = snapshot.localTime,
          id = msg.iCD.get.id,
          locationId = msg.iCD.get.locationId
        ),
        loc = msg.location.get,
        postAutoResolutionInfo = msg.icdAlarmIncidentMessage.postAutoResolutionInfo
      ),
      notificationTokens = msg.notificationTokens,
      icdId = msg.iCD.get.id,
      icdAlarmIncidentRegistryId = Some(msg.icdAlarmIncidentMessage.id)
    )

  }
}
