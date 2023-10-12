package com.flotechnologies

/**
 * Created by yongjhih on 12/21/16.
 */
import kotlinx.serialization.Optional
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * <pre>
 * {
 *     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7InVzZXJfaWQiOiI1NTljYmEyYi02YjBiLTQ5NGEtOGZkMS02NGExZjVjZTk2OWQiLCJlbWFpbCI6ImZsb3RlYW0yMDE1K2RldkBnbWFpbC5jb20ifSwidGltZXN0YW1wIjoxNDgyNDU3MjgyLCJpYXQiOjE0ODI0NTcyODEsImV4cCI6MTQ4MjU0MzY4MX0.utK8mYk3bJ8CjKJIBJVQX-sZx1oaFHoPzFUL0ooGZj0",
 *     "tokenPayload": {
 *         "user": {
 *             "user_id": "559cba2b-6b0b-494a-8fd1-64a1f5ce969d",
 *             "email": "floteam2015+dev@gmail.com"
 *          },
 *          "timestamp": 1482457282
 *      },
 *     "tokenExpiration": 86400,
 *     "timeNow": 1482457282
 * }
 * </pre>
 */
@Serializable
data class Credential (
    @Optional
    @SerialName("token")
    var token: String? = null,
    @Optional
    @SerialName("tokenPayload")
    var tokenPayload: TokenPayload? = null,
    @Optional
    @SerialName("tokenExpiration")
    var tokenExpiration: Long? = null,
    @Optional
    @SerialName("timeNow")
    var timeNow: Long? = null
)

@Serializable
data class TokenPayload (
    @Optional
    @SerialName("user")
    var user: User? = null,
    @Optional
    @SerialName("timestamp")
    var timestamp: Long? = null
)

@Serializable
data class User (
    @Optional
    @SerialName("user_id")
    var id: String? = null,
    @Optional
    @SerialName("email")
    var email: String? = null
)
