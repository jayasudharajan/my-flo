package Models.ProducerMessages

import com.flo.Models.KafkaMessages.Floice.FloiceMessage

case class ProducerVoiceMessage(
                               floiceMessage: FloiceMessage,
                               incidentId:String,
                               userId:String
                               ) {

}
