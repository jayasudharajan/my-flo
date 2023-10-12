package com.flo.puck.http.circe

import com.flo.puck.http.circe
import com.flo.puck.http.device.ActionRulesResponse
import io.circe.parser.decode

final private[http] class DeserializeActionRules extends (String => ActionRulesResponse) {
  override def apply(actionRulesStr: String): ActionRulesResponse = {

    import circe._

    decode[ActionRulesResponse](actionRulesStr) match {
      case Right(actionRules)     => actionRules
      case Left(error)            => throw error
    }
  }
}
