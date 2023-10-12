package com.flo.notification.sdk

package object conf {

  private[sdk] case class SmsConfig(deliveryCallback: String, postDeliveryCallback: String)

  private[sdk] case class SslConfig(awsConfigBucket: String,
                                    clientCert: String,
                                    clientKey: String,
                                    brokerCaCertificate: String)
  private[sdk] case class MqttConfig(broker: String, qos: Int, clientId: String, sslConfiguration: SslConfig)

}
