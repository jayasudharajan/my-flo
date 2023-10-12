package flo.models.http

case class ListAlertEventsResponse(
    items: List[AlertEventResponse],
    page: Int,
    total: Int
)

object ListAlertEventsResponse {
  val example = ListAlertEventsResponse(
    List(AlertEventResponse.example),
    1,
    200
  )
}
