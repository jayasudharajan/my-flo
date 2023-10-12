package Models.ProducerMessages

import com.flo.Models.KafkaMessages.EmailMessage

/**
	* Created by Francisco on 7/6/2016.
	*/
case class ProducerEmailMessage(
                               emailMessage:EmailMessage ,
                               icdAlarmIncidentRegistryId:String,
                               isCsEmail:Boolean = false
                               ) {

}
