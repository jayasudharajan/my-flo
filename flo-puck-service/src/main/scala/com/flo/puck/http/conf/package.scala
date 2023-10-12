package com.flo.puck.http

package object conf {
  private[http] case class HttpConfig(
    deviceApi: DeviceApiConfig,
    notificationApi: NotificationApiConfig,
    publicGateway: PublicGatewayConfig
  )

  private[http] trait ApiConfig {
    val baseUri: String
  }

  private[http] case class DeviceApiConfig(
    baseUri: String,
    endpoints: DeviceEndpointsConfig
  ) extends ApiConfig

  private[http] case class NotificationApiConfig(
    baseUri: String,
    endpoints: NotificationEndpointsConfig
  ) extends ApiConfig

  private[http] case class PublicGatewayConfig(
    baseUri: String,
    accessToken: String,
    endpoints: PublicGatewayEndpoints
  ) extends ApiConfig

  private[http] case class DeviceEndpointsConfig(
    fwProperties: String,
    actionRules: String
  )

  private[http] case class NotificationEndpointsConfig(events: String)

  private[http] case class PublicGatewayEndpoints(devices: String, devicesById: String)
}
