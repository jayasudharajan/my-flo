package com.flo.services.email.actors

import akka.actor.{Actor, ActorLogging, ActorSystem}
import akka.http.scaladsl.Http
import argonaut._
import argonaut.Argonaut._
import akka.http.scaladsl.model._
import akka.http.scaladsl.model.headers.BasicHttpCredentials
import akka.stream.ActorMaterializer
import com.flo.services.email.models.SendWithUs.{PostRequestInfo, Response}
import com.flo.services.email.utils.ApplicationSettings
import scala.concurrent.Future
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

class SendWithUsActor(actorSystem: ActorSystem, actorMaterializer: ActorMaterializer) extends Actor with ActorLogging {
	private  val token = ApplicationSettings.sendWithUs.apiKey
	private  val apiUrl = "https://api.sendwithus.com/api/v1/send"
	private  val TIME_OUT_FINATE_DURATION_IN_SENCONDS = 10 seconds
	private  val authorization = headers.Authorization(
		BasicHttpCredentials(token, "")
	)
	private implicit val as = actorSystem
	private implicit val am = actorMaterializer

	def receive = {
		case postBodyRequest: PostRequestInfo =>
			log.info(s"processing: ${postBodyRequest.metaInfo.asJson.nospaces.toString}")
			val results = Future {
				Http(actorSystem).singleRequest(HttpRequest(
					method = HttpMethods.POST,
					uri = apiUrl,
					entity = HttpEntity(ContentTypes.`application/json`, postBodyRequest.postBody),

					headers = List(authorization)
				)).flatMap {
					response =>
						if (response.status == StatusCodes.OK) {
							response.entity.toStrict(TIME_OUT_FINATE_DURATION_IN_SENCONDS).map((json) =>
								Parse.decodeOption[Response](json.data.utf8String)

							)
						}
						else throw new Exception(response.toString())
				}


			}
			results.flatMap(s => s).onComplete {
				case Success(s) =>
					log.info(s"results ${s.get.asJson.toString()}")
				case Failure(ex) =>
					log.error(ex, "error sending email")
			}
	}

}
