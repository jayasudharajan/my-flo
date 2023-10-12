package flo.models.http

import com.flo.notification.sdk.model.{
  Action,
  Alarm,
  AlarmSystemModeSettings,
  AlertFeedbackFlow,
  Severity,
  SupportOption,
  SystemMode,
  UserFeedbackOptions
}
import flo.services.DisplayNameAndDescription

case class Id(id: Int)

case class AlarmDefaultSettings(systemMode: String, enabled: Boolean, supported: Boolean)

case class DeliveryMediumSetting(supported: Boolean, defaultSettings: Seq[AlarmDefaultSettings])

case class DeliveryMediumConfig(userConfigurable: Boolean,
                                sms: DeliveryMediumSetting,
                                email: DeliveryMediumSetting,
                                push: DeliveryMediumSetting,
                                call: DeliveryMediumSetting)

case class UserActions(displayTitle: String, displayDescription: String, actions: List[Action])

case class AlarmResponse(
    id: Int,
    name: String,
    displayName: String,
    description: String,
    severity: String,
    isInternal: Boolean,
    isShutoff: Boolean,
    sendWhenValveIsClosed: Boolean,
    triggersAlarm: Option[Id],
    triggeredBy: Option[Seq[Id]],
    userActions: UserActions,
    actions: List[Action],
    supportOptions: List[SupportOption],
    active: Boolean,
    parent: Option[Id],
    children: Set[Id],
    deliveryMedium: DeliveryMediumConfig,
    tags: Set[String],
    userFeedbackFlow: Option[Seq[AlertFeedbackFlow]],
    feedbackOptions: Option[UserFeedbackOptions]
)

object AlarmResponse {
  def example: AlarmResponse = AlarmResponse(
    1,
    "high pressure",
    "High Pressure Alarm",
    "some description",
    "Critical",
    true,
    false,
    false,
    None,
    None,
    UserActions("", "", Nil),
    Nil,
    Nil,
    true,
    None,
    Set(Id(2)),
    DeliveryMediumConfig(
      userConfigurable = true,
      sms = DeliveryMediumSetting(true, Seq()),
      email = DeliveryMediumSetting(true, Seq()),
      push = DeliveryMediumSetting(true, Seq()),
      call = DeliveryMediumSetting(true, Seq())
    ),
    Set("puck"),
    None,
    None
  )

  private val shutoffAlarms: List[Int] = List(51, 52, 53, 55, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 101)
  private val triggers: Map[Int, Int] = Map(
    10 -> 51,
    11 -> 52,
    26 -> 53,
    70 -> 80,
    71 -> 81,
    72 -> 82,
    73 -> 83,
    74 -> 84,
    75 -> 85,
    76 -> 86,
    77 -> 87,
    78 -> 88,
    79 -> 89
  )

  val triggeredBy: Map[Int, Seq[Int]] = triggers.groupBy(_._2).map {
    case (v, kvPairs) => (v, kvPairs.keys.toSeq)
  }

  def getIsShutoff(alarmId: Int): Boolean =
    shutoffAlarms.contains(alarmId)

  private def getDeliveryMediumSetting(
      systemModeSettings: Seq[AlarmSystemModeSettings],
      mediumSettingRetriever: AlarmSystemModeSettings => Option[Boolean]
  ): DeliveryMediumSetting = {
    val supported = systemModeSettings
      .find(s => s.systemMode == SystemMode.Home)
      .exists(s => mediumSettingRetriever(s).isDefined)

    DeliveryMediumSetting(
      supported,
      systemModeSettings.map(
        s =>
          AlarmDefaultSettings(
            SystemMode.toString(s.systemMode),
            mediumSettingRetriever(s).getOrElse(false),
            mediumSettingRetriever(s).isDefined
        )
      )
    )
  }

  def from(alarm: Alarm,
           userActions: UserActions,
           supportOptions: List[SupportOption],
           systemModeSettings: Seq[AlarmSystemModeSettings],
           displayNameAndDescription: DisplayNameAndDescription,
           alertFeedbackFlows: Option[Seq[AlertFeedbackFlow]],
           userFeedbackOptions: Option[UserFeedbackOptions]): AlarmResponse =
    AlarmResponse(
      alarm.id,
      alarm.name,
      displayNameAndDescription.displayName,
      displayNameAndDescription.description,
      Severity.toString(alarm.severity),
      alarm.isInternal,
      getIsShutoff(alarm.id),
      alarm.sendWhenValveIsClosed,
      triggers.get(alarm.id).map(Id),
      triggeredBy.get(alarm.id).map(_.map(Id)),
      userActions,
      userActions.actions,
      supportOptions,
      alarm.enabled,
      alarm.parentId.map(Id),
      alarm.children.map(Id),
      DeliveryMediumConfig(
        userConfigurable = alarm.userConfigurable,
        sms = getDeliveryMediumSetting(
          systemModeSettings,
          s => s.smsEnabled
        ),
        email = getDeliveryMediumSetting(
          systemModeSettings,
          s => s.emailEnabled
        ),
        push = getDeliveryMediumSetting(
          systemModeSettings,
          s => s.pushEnabled
        ),
        call = getDeliveryMediumSetting(
          systemModeSettings,
          s => s.callEnabled
        )
      ),
      alarm.tags,
      alertFeedbackFlows,
      userFeedbackOptions
    )
}
