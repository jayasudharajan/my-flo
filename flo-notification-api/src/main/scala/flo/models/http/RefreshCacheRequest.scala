package flo.models.http

import java.util.UUID

case class RefreshCacheRequest(deviceIds: Set[UUID])
