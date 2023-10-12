package com.flo.puck.core.api

sealed trait SystemMode
case object Home    extends SystemMode
case object Away    extends SystemMode
case object Sleep   extends SystemMode
case object Unknown extends SystemMode
