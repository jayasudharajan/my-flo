package Models

import com.flo.Models.KafkaMessages.ICDAlarmIncidentStatus
import com.flo.Models.Logs.ICDAlarmIncidentRegistry

/**
	* Created by Francisco on 7/6/2017.
	*/
case class PostResolutionAlertMessage(
	                                     originalAlert: ICDAlarmIncidentRegistry,
	                                     autoResolveIncident: ICDAlarmIncidentStatus
                                     ) {}
