package flo.models.http

import com.flo.notification.sdk.model.{ActionSupport, ActionType}
import com.flo.notification.sdk.service.IncidentStatus

case class ActionResponse(id: Int, name: String, text: String, displayOnStatus: String, sort: Int)

case class SupportOptionResponse(id: Int, alarmId: Int, actionPath: String, actionType: String, sort: Int, text: String)

case class UserActionsResponse(displayTitle: String, displayDescription: String, actions: List[ActionResponse])

case class ActionSupportResponse(alarmId: Int,
                                 userActions: UserActionsResponse,
                                 actions: List[ActionResponse],
                                 supportOptions: List[SupportOptionResponse])

case class ActionsSupportResponse(items: List[ActionSupportResponse])

object ActionsSupportResponse {
  val actionsResponse = List(
    ActionResponse(
      1,
      "Closed Valve",
      "Valve has been closed",
      IncidentStatus.toString(IncidentStatus.Filtered),
      3
    )
  )
  val example = ActionsSupportResponse(
    List(
      ActionSupportResponse(
        1,
        UserActionsResponse(
          "Clear this Alert",
          "Do you want to ignore this alert if it happens again?",
          actionsResponse
        ),
        actionsResponse,
        List(SupportOptionResponse(1, 1, "action path", ActionType.toString(ActionType.WebLink), 1, "text"))
      )
    )
  )

  def apply(actionsSupport: => List[ActionSupport]): ActionsSupportResponse =
    ActionsSupportResponse(actionsSupport.map { actionSupport =>
      val actions = actionSupport.actions.map { action =>
        ActionResponse(
          action.id,
          action.name,
          action.text,
          IncidentStatus.toString(action.displayOnStatus),
          action.sort
        )
      }
      val supportOptions = actionSupport.supportOptions.map { supportOption =>
        SupportOptionResponse(
          supportOption.id,
          supportOption.alarmId,
          supportOption.actionPath,
          ActionType.toString(supportOption.actionType),
          supportOption.sort,
          supportOption.text
        )
      }
      // TODO: Move this to Localization Service. This should be localized in the future.
      val userActions =
        UserActionsResponse("Clear this Alert", "Do you want to ignore this alert if it happens again?", actions)
      ActionSupportResponse(actionSupport.alarmId, userActions, actions, supportOptions)
    })
}
