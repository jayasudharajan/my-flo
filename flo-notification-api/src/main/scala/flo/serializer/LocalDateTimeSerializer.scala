package flo.serializer

import java.time.format.DateTimeFormatter
import java.time.{LocalDateTime, ZoneOffset, ZonedDateTime}

import com.fasterxml.jackson.core.{JsonGenerator, JsonParser}
import com.fasterxml.jackson.databind.{DeserializationContext, JsonDeserializer, JsonSerializer, SerializerProvider}
import com.flo.notification.sdk.model.{AlertFeedbackFlow, FeedbackOptionType, FilterStateType}
import org.json4s.Extraction
import org.json4s.jackson.JsonMethods._

class LocalDateTimeSerializer extends JsonSerializer[LocalDateTime] {
  override def serialize(value: LocalDateTime, gen: JsonGenerator, serializers: SerializerProvider): Unit =
    gen.writeString(value.format(DateTimeFormatter.ISO_DATE_TIME))
}

class LocalDateTimeDeserializer extends JsonDeserializer[LocalDateTime] {
  override def deserialize(p: JsonParser, ctxt: DeserializationContext): LocalDateTime =
    ZonedDateTime
      .parse(p.getValueAsString, DateTimeFormatter.ISO_DATE_TIME)
      .withZoneSameInstant(ZoneOffset.UTC)
      .toLocalDateTime
}

class AlertFeedbackFlowSerializer extends JsonSerializer[AlertFeedbackFlow] {
  override def serialize(value: AlertFeedbackFlow, gen: JsonGenerator, serializers: SerializerProvider): Unit = {

    implicit val formats = org.json4s.DefaultFormats
    gen.writeRawValue(compact(render(Extraction.decompose(value))))
  }
}

class FilterStateTypeSerializer extends JsonSerializer[FilterStateType] {
  override def serialize(value: FilterStateType, gen: JsonGenerator, serializers: SerializerProvider): Unit =
    gen.writeString(FilterStateType.toString(value))

}

class FeedbackOptionTypeSerializer extends JsonSerializer[FeedbackOptionType] {
  override def serialize(value: FeedbackOptionType, gen: JsonGenerator, serializers: SerializerProvider): Unit =
    gen.writeString(value.toString)
}
