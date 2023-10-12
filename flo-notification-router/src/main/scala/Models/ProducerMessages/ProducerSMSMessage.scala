package Models.ProducerMessages

import com.flo.Models.KafkaMessages.SmsMessage

/**
	* Created by Francisco on 7/8/2016.
	*/
case class ProducerSMSMessage(
	                             sMSMessage: SmsMessage,
	                             icdAlarmIncidentRegistryId: String,
	                             userId: String
                             ) {}
