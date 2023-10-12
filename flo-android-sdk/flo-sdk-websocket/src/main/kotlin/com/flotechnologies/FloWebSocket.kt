package com.flotechnologies

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import com.tinder.scarlet.WebSocket
import com.tinder.scarlet.ws.Receive
import com.tinder.scarlet.ws.Send
import io.reactivex.Flowable
import java.util.*


/**
 * TODO: default content-type and persist authentication token
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/57704450/WebSocket+API
 */
interface FloWebSocket {
    @Send
    fun send(payload: FloWebSocketParamsPayload)

    @Send
    fun send(payload: FloWebSocketPayload)

    @Receive
    fun receive(): Flowable<FloWebSocketResponse>

    @Send
    //fun login(payload: FloWebSocketLoginPayload): Flowable<FloWebSocketLoginResponse>
    fun login(payload: FloWebSocketParamsPayload)

    @Receive
    fun onLogin(): Flowable<FloWebSocketLoginResponse>

    @Send
    fun scanWifi(payload: FloWebSocketPayload)
    //fun scanWifi(payload: FloWebSocketScanWifiPayload): Flowable<FloWebSocketScanWifiResponse>

    @Receive
    fun onScanWifi(): Flowable<FloWebSocketScanWifiResponse>
}

@JsonClass(generateAdapter = true)
data class FloWebSocketCertificatesPayload(
        val encoded_ca_cert: String,
        val encoded_client_cert: String,
        val encoded_client_key: String
)

//fun FloWebSocket.login(token: String) = login(FloWebSocketLoginPayload(params=LoginParams(token=token)))
fun FloWebSocket.login(token: String): Flowable<FloWebSocketLoginResponse> {
    val id = "login".hashCode()
    return onLogin().startWith {
        println(FloWebSocketParamsPayload(method = "login", params=hashMapOf("token" to token), id = id))
        login(FloWebSocketParamsPayload(method = "login", params=hashMapOf("token" to token), id = id))
        it.onComplete()
    }
    .filter { it.id == id }
}

fun FloWebSocket.scanWifi(): Flowable<FloWebSocketScanWifiResponse> {
    val id = "scan_wifi_ap".hashCode()
    return onScanWifi().startWith {
        scanWifi(FloWebSocketPayload(method = "scan_wifi_ap", id = id))
        it.onComplete()
    }.filter { it.id == id }
}

fun FloWebSocket.setCertificates(ca: String, clientCert: String, clientKey: String): Flowable<FloWebSocketResponse> {
    val id = "set_certificates".hashCode()
    return receive().startWith {
        send(FloWebSocketParamsPayload(method = "set_certificates", params = hashMapOf(
            "encoded_ca_cert" to ca,
            "encoded_client_cert" to clientCert,
            "encoded_client_key" to clientKey
        ), id = id))
        it.onComplete()
    }.filter { it.id == id }
}

@JsonClass(generateAdapter = true)
data class FloWebSocketLoginPayload(
        val params: LoginParams,
        val method: String = "login",
        val jsonrpc: String = "2.0",
        val id: Int = 0
)

@JsonClass(generateAdapter = true)
data class FloWebSocketScanWifiPayload(
        val method: String = "scan_wifi_ap",
        val jsonrpc: String = "2.0",
        val id: Int = 0
)

@JsonClass(generateAdapter = true)
data class FloWebSocketPayload(
        val method: String,
        val jsonrpc: String = "2.0",
        val id: Int = 0
)

@JsonClass(generateAdapter = true)
data class LoginParams(val token: String)

@JsonClass(generateAdapter = true)
data class FloWebSocketParamsPayload(
    val method: String,
    val params: Map<String, String> = emptyMap(),
    val id: Int = 0,
    val jsonrpc: String = "2.0"
)

@JsonClass(generateAdapter = true)
data class FloWebSocketResponse(
        @Json(name = "from_method")
        val method: String,
        @Json(name = "from_params")
        val params: Map<String, String> = emptyMap(),
        val id: Int = 0,
        val jsonrpc: String = "2.0"
)

@JsonClass(generateAdapter = true)
data class FloWebSocketResponseTyped<T>(
        @Json(name = "from_method")
        val method: String,
        @Json(name = "from_params")
        val params: Map<String, String> = emptyMap(),
        val id: Int = 0,
        val jsonrpc: String = "2.0",
        val result: T? = null
)

@JsonClass(generateAdapter = true)
data class FloWebSocketLoginResponse(
        @Json(name = "from_method")
        val method: String,
        @Json(name = "from_params")
        val params: Map<String, String> = emptyMap(),
        val id: Int = 0,
        val jsonrpc: String = "2.0",
        @Json(name = "result")
        val result: Boolean
)

@JsonClass(generateAdapter = true)
data class FloWebSocketScanWifiResponse(
        @Json(name = "from_method")
        val method: String,
        @Json(name = "from_params")
        val params: Map<String, String> = emptyMap(),
        val id: Int = 0,
        val jsonrpc: String = "2.0",
        @Json(name = "result")
        val result: List<FloWebSocketScanWifiResult> = emptyList()
)

@JsonClass(generateAdapter = true)
data class FloWebSocketScanWifiResult(
        val signal: Int,
        val encryption: String,
        val ssid: String
)
