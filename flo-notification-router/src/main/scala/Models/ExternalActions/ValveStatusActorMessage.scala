package Models.ExternalActions

import com.flo.Models.TelemetryCompact

/**
	* Created by Francisco on 1/12/2017.
	*/
case class ValveStatusActorMessage (
                                   telemetry:Option[TelemetryCompact]
                                   ) {}
