package com.flotechnologies

import kotlinx.serialization.Optional
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Created by yongjhih on 12/21/16.
 */

@Serializable
data class Faq (
    @Optional
    @SerialName("created")
    var created: String? = null,
    @Optional
    @SerialName("id")
    var id: String? = null,
    @Optional
    @SerialName("questions")
    var questions: List<Question>? = null,
    @Optional
    @SerialName("updated")
    var updated: String? = null,
    @Optional
    @SerialName("version")
    var version: String? = null
)
