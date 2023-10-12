package flo.services

import com.flo.notification.sdk.service.exception.ValidationException
import com.twitter.finagle.http.{Request, Response}
import com.twitter.finatra.http.exceptions.ExceptionMapper
import com.twitter.finatra.http.response.ResponseBuilder
import javax.inject.{Inject, Singleton}

@Singleton
class ValidationExceptionMapper @Inject()(response: ResponseBuilder) extends ExceptionMapper[ValidationException] {
  def toResponse(request: Request, throwable: ValidationException): Response =
    response.badRequest(s"${throwable.getMessage}")
}

@Singleton
class IllegalArgumentExceptionMapper @Inject()(response: ResponseBuilder)
    extends ExceptionMapper[IllegalArgumentException] {
  def toResponse(request: Request, throwable: IllegalArgumentException): Response =
    response.badRequest(s"${throwable.getMessage}")
}
