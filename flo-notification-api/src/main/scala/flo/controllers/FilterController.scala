package flo.controllers

import java.util.UUID

import com.flo.notification.sdk.model.{FilterState, FilterStateType}
import com.flo.notification.sdk.service.NotificationService
import com.jakehschwartz.finatra.swagger.SwaggerController
import com.twitter.bijection.Conversion.asMethod
import com.twitter.util.{Future => TwitterFuture}
import com.twitter.bijection.twitter_util.UtilBijections
import flo.models.http.{ByDeviceIdRequest, ByUUIDIdRequest, CreateFilterRequest, FilterStates}
import io.swagger.models.Swagger
import javax.inject.{Inject, Singleton}

import scala.concurrent.ExecutionContext

@Singleton
class FilterController @Inject()(s: Swagger, notificationService: NotificationService)(implicit ec: ExecutionContext)
    extends SwaggerController
    with UtilBijections {

  implicit protected val swagger: Swagger = s

  postWithDoc("/filters") { o =>
    o.summary(
        "Creates a Filter State record"
      )
      .tag("Filters")
      .bodyParam[CreateFilterRequest](
        "Filter State data",
        "Filter State data."
      )
      .responseWith(
        200
      )
  } { request: CreateFilterRequest =>
    FilterStateType
      .fromString(request.`type`)
      .map { filterStateType =>
        val filterState = FilterState(
          request.id.map(UUID.fromString),
          request.alarmId,
          filterStateType,
          request.deviceId.map(UUID.fromString),
          request.incidentId.map(UUID.fromString),
          request.locationId.map(UUID.fromString),
          request.userId.map(UUID.fromString),
          request.expiration,
          None
        )

        notificationService
          .createFilterState(filterState)
          .as[TwitterFuture[FilterState]]
      }
      .getOrElse {
        TwitterFuture(
          response.badRequest.jsonError(
            "Invalid filter state type."
          )
        )
      }
  }

  getWithDoc("/filters/:id") { o =>
    o.summary(
        "Retrieves a filter with the given ID"
      )
      .tag("Filters")
      .routeParam[Int]("id", "The Filter State ID to be retrieved")
      .responseWith(200)
  } { request: ByUUIDIdRequest =>
    notificationService
      .getFilterState(UUID.fromString(request.id))
      .as[TwitterFuture[Option[FilterState]]]
      .map {
        case Some(filter) =>
          response.ok.json(filter)

        case None =>
          response.notFound.jsonError
      }
  }

  getWithDoc("/filters") { o =>
    o.summary(
        "Retrieves filters associated to the given Device IDs"
      )
      .tag("Filters")
      .queryParam[String]("deviceId", "Device ID", true)
      .responseWith(200)
  } { request: ByDeviceIdRequest =>
    notificationService
      .getFilterStateByDeviceId(UUID.fromString(request.deviceId))
      .as[TwitterFuture[Seq[FilterState]]]
      .map { filters =>
        response.ok.json(FilterStates(filters))
      }
  }

  deleteWithDoc("/filters/:id") { o =>
    o.summary(
        "Deletes a filter with the given ID"
      )
      .tag("Filters")
      .routeParam[String]("id", "Filter ID to be removed")
      .responseWith(
        204
      )
  } { request: ByUUIDIdRequest =>
    notificationService
      .deleteFilterState(UUID.fromString(request.id))
      .as[TwitterFuture[Boolean]]
      .map {
        case true  => response.noContent
        case false => response.notFound
      }
  }
}
