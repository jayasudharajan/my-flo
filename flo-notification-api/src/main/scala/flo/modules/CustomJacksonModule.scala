package flo.modules

import java.time.LocalDateTime

import com.fasterxml.jackson.databind.PropertyNamingStrategy
import com.fasterxml.jackson.databind.module.SimpleModule
import com.flo.notification.sdk.model.{AlertFeedbackFlow, FeedbackOptionType, FilterStateType}
import com.twitter.finatra.json.modules.FinatraJacksonModule
import flo.serializer.{
  AlertFeedbackFlowSerializer,
  FeedbackOptionTypeSerializer,
  FilterStateTypeSerializer,
  LocalDateTimeDeserializer,
  LocalDateTimeSerializer
}

object CustomJacksonModule extends FinatraJacksonModule {
  override val propertyNamingStrategy = PropertyNamingStrategy.LOWER_CAMEL_CASE

  override val additionalJacksonModules = Seq(
    new SimpleModule() {
      addSerializer(classOf[LocalDateTime], new LocalDateTimeSerializer())
      addSerializer(classOf[AlertFeedbackFlow], new AlertFeedbackFlowSerializer())
      addSerializer(classOf[FilterStateType], new FilterStateTypeSerializer())
      addSerializer(classOf[FeedbackOptionType], new FeedbackOptionTypeSerializer())
      addDeserializer(classOf[LocalDateTime], new LocalDateTimeDeserializer())
    }
  )
}
