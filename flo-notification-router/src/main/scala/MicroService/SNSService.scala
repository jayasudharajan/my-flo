package MicroService

import com.amazonaws.regions.{Region, Regions}
import com.amazonaws.services.sns.AmazonSNSClient
import com.amazonaws.services.sns.model.{CreatePlatformEndpointRequest, DeleteEndpointRequest, PublishRequest, PublishResult}
import com.typesafe.scalalogging.LazyLogging

/**
	* Created by Francisco on 2/28/2017.
	*/
class SNSService(defaultArn: String) extends LazyLogging {
	private val AWS_SNS_CLIENT: AmazonSNSClient = new AmazonSNSClient()

	AWS_SNS_CLIENT.setRegion(
		if (Regions.getCurrentRegion == null)
			Region.getRegion(Regions.DEFAULT_REGION)
		else Region.getRegion(Regions.DEFAULT_REGION))

	/**
		* using the user registration token it enrolls that particular user in AWS SNS it returns the ARNenpoint for that token, it returns an AWS exception otherwise.
		**/

	///TODO: Metric timer
	def matriculateDevice(token: String): Option[String] = {
		val result = AWS_SNS_CLIENT.createPlatformEndpoint(
			new CreatePlatformEndpointRequest()
				.withPlatformApplicationArn(defaultArn)
				.withToken(token)
		)
		Some(result.getEndpointArn)
	}

	/**
		* Deletes the especified ARN enpoint from AWS SNS
		**/

	///TODO: Metric timer
	def expulseDevice(endpointARN: String): Unit = {
		try {
			val result = AWS_SNS_CLIENT.deleteEndpoint(
				new DeleteEndpointRequest()
					.withEndpointArn(endpointARN)
			)
			logger.info(s"deleted sns ARNendpoint: $endpointARN")
		}
		catch {
			case e: Throwable =>
				logger.error(s"The following exception happened trying to delete endpoint ARN: $endpointARN ex: ${e.toString}")
		}
	}

	///TODO: Metric timer
	def publishPushNotification(aRNEndpoint: Option[String], pushNotificationJson: String): PublishResult = {
		AWS_SNS_CLIENT.publish(new PublishRequest()
			.withTargetArn(aRNEndpoint.get)
			.withMessage(pushNotificationJson)
			.withMessageStructure("json")
		)
	}


}
