package flo.directive.router.utils

trait IMQTTClient {
  def send[T <: AnyRef](topic: String, message: T, serializer: T => String): Unit
}
