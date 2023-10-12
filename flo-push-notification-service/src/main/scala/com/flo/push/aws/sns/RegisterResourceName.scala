package com.flo.push.aws.sns

import com.amazonaws.services.sns.AmazonSNS
import com.amazonaws.services.sns.model._
import com.flo.push.core.api.ResourceNameRegistrator
import com.flo.push.sdk.ResourceNameService

import collection.JavaConverters._
import scala.concurrent.{ExecutionContext, Future}
import scala.util.Try

class RegisterResourceName(resourceNameService: ResourceNameService, snsClient: AmazonSNS)
                          (implicit ec: ExecutionContext) extends ResourceNameRegistrator {

  private val errorPattern = ".*Endpoint (arn:aws:sns[^ ]+) already exists with the same Token.*".r

  override def apply(userId: String, deviceId: String, platformArn: String, token: String): Future[String] = {
    resourceNameService.retrieveEndpoint(userId, deviceId, token).flatMap { maybeEndpointArn =>
      val eventualEndpointArn = maybeEndpointArn match {
        case Some(endpoint) => Future.successful(endpoint)
        case None           => createEndpoint(userId, deviceId, platformArn, token)
      }

      eventualEndpointArn.flatMap { endpointArn =>
        // Look up the endpoint and make sure the data in it is current, even if it was just created
        Try {
          val getAttributesResponse =
            snsClient.getEndpointAttributes(new GetEndpointAttributesRequest().withEndpointArn(endpointArn))

          val updateNeeded = !getAttributesResponse.getAttributes.get("Token").equals(token) ||
            !getAttributesResponse.getAttributes.get("Enabled").equalsIgnoreCase("true")

          if (updateNeeded) {
            // endpoint is out of sync with the current data update the token and enable it.
            val attributes = Map(
              "Token" -> token,
              "Enabled" -> "true"
            )

            val saeReq = new SetEndpointAttributesRequest()
              .withEndpointArn(endpointArn)
              .withAttributes(attributes.asJava)

            snsClient.setEndpointAttributes(saeReq)
          }

          Future.successful(endpointArn)

        }.recover {
          case _: NotFoundException =>
            // we had an ARN stored, but the endpoint associated with it disappeared. Recreate it.
            createEndpoint(userId, deviceId, platformArn, token)
        }.get
      }
    }
  }

  private def createEndpoint(userId: String, deviceId: String, platformArn: String, token: String): Future[String] = {
    val endpointArn: String = Try {
      val cpeReq = new CreatePlatformEndpointRequest()
        .withPlatformApplicationArn(platformArn)
        .withToken(token)

      val cpeRes = snsClient
        .createPlatformEndpoint(cpeReq)

      cpeRes.getEndpointArn
    }.recover {
      case error: InvalidParameterException => getEndpointArnFromError(error)
    }.get

    resourceNameService.storeEndpoint(userId, deviceId, platformArn, endpointArn, token).map { _ =>
      endpointArn
    }
  }

  private def getEndpointArnFromError(error: InvalidParameterException): String = {
    error.getErrorMessage match {
      case errorPattern(endpointArn) =>
        // the endpoint already exists for this token, but with additional custom data that
        // CreateEndpoint doesn't want to overwrite. Just use the existing endpoint.
        endpointArn

      case _ =>
        // rethrow exception, the input is actually bad
        throw error
    }
  }
}
