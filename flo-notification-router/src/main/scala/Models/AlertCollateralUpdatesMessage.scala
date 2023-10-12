package Models

/**
	* Created by Francisco on 6/26/2017.
	*/
case class AlertCollateralUpdatesMessage(
                                   internalAlarmId:Int,
                                   icdId:String,
                                   incidentId:Option[String]

                                   )
