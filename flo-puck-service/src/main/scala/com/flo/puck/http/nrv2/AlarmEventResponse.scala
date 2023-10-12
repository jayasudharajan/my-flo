package com.flo.puck.http.nrv2

import com.flo.puck.core.api.AlarmEvent

case class AlarmEventResponse(
  items: List[AlarmEvent]
)