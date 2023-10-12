package flo.models.http

// TODO: Make this work with generics an a type of Examplable
case class ItemsResponse(
    items: List[AlarmResponse]
)

object ItemsResponse {
  def example: ItemsResponse = ItemsResponse(List(AlarmResponse.example))
}
