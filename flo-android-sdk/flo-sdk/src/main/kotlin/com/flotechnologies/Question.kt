package com.flotechnologies

import kotlinx.serialization.Optional
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Created by yongjhih on 12/21/16.
 */

@Serializable
data class Question (
    @Optional
    @SerialName("answers")
    var answers: List<String>? = null,
    @Optional
    @SerialName("question")
    var question: String? = null
)
