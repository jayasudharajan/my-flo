package com.flo.push.aws.sns

import com.amazonaws.regions.Regions
import com.amazonaws.services.sns.{AmazonSNS, AmazonSNSClientBuilder}
import com.flo.push.core.api.{PushNotificationSender, ResourceName, ResourceNameRegistrator}
import com.flo.push.conf._
import com.flo.push.sdk.ResourceNameService
import com.typesafe.config.Config

import scala.concurrent.ExecutionContext

trait Module {
  // Requires
  def appConfig: Config
  def resourceNameService: ResourceNameService
  def blockableExecutionContext: ExecutionContext

  // Private
  private val snsClientBuilder: AmazonSNSClientBuilder = AmazonSNSClientBuilder.standard()
  snsClientBuilder.setRegion(Regions.DEFAULT_REGION.getName)

  private val snsClient: AmazonSNS = snsClientBuilder.build()

  // Provides
  val registerResourceName: ResourceNameRegistrator = new RegisterResourceName(resourceNameService, snsClient)(blockableExecutionContext)

  val androidResourceName: ResourceName = appConfig.as[String]("sns.android-arn")
  val iosResourceName: ResourceName = appConfig.as[String]("sns.ios-arn")

  val sendAndroidPushNotification: PushNotificationSender = new SendAndroidPushNotification(snsClient)(blockableExecutionContext)
  val sendIosPushNotification: PushNotificationSender = new SendIosPushNotification(snsClient)(blockableExecutionContext)
}
