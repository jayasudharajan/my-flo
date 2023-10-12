package com.flotechnologies

import com.jakewharton.retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import com.tinder.scarlet.Scarlet
import com.tinder.scarlet.messageadapter.moshi.MoshiMessageAdapter
import com.tinder.scarlet.streamadapter.rxjava2.RxJava2StreamAdapterFactory
import com.tinder.scarlet.websocket.okhttp.newWebSocketFactory
import io.reactivex.Maybe
import io.reactivex.rxkotlin.toMaybe
import kotlinx.serialization.json.Json
import okhttp3.ConnectionSpec
import okhttp3.MediaType
import okhttp3.OkHttpClient
import okhttp3.TlsVersion
import okhttp3.logging.HttpLoggingInterceptor
import org.jetbrains.spek.api.Spek
import retrofit2.Retrofit
import java.io.IOException
import java.io.InputStream
import java.net.InetAddress
import java.net.Socket
import java.net.UnknownHostException
import java.security.GeneralSecurityException
import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.util.*
import java.util.concurrent.TimeUnit
import javax.net.ssl.*

class FloWebSocketIntegrationSpec : Spek({
    fun base64decode(text: String): ByteArray {
        return Base64.getDecoder().decode(text)
    }

    describe("FloWebSocketIntegrationSpec") {
        on("dev") {
            val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
            val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
            val username = System.getenv("FLO_USERNAME")
            val password = System.getenv("FLO_PASSWORD")

            val flo = Retrofit.Builder()
                    .client(OkHttpClient.Builder()
                            .addInterceptor(HttpLoggingInterceptor().apply {
                                level = HttpLoggingInterceptor.Level.BODY
                            })
                            .addInterceptor { chain ->
                                chain.proceed(chain.request()
                                        .newBuilder()
                                        .addHeader("User-Agent", "Flo-Android")
                                        .build())
                            }
                            .build())
                    .addCallAdapterFactory(RxJava2CallAdapterFactory.create())
                    .addConverterFactory(Json.nonstrict.asConverterFactory(MediaType.parse("application/json")!!))
                    .baseUrl(baseUrl)
                    .build().create(Flo::class.java)

            val oauth = Oauth()
            oauth.username = username
            oauth.password = password
            oauth.clientId = clientId
            oauth.clientSecret = oauth.clientId
            oauth.grantType = "password" // FIXME constant
            val floTokenObs = flo.oauth(oauth)
                    .singleElement()
                    .map { it.accessToken!! }
                    .map { "Bearer ${it}" }
                    .cache()

            it("should return login websocket") {
                val cert = LoganSquare.parse(javaClass.classLoader.getResourceAsStream("a.json")!!.reader().readText(), Certificate::class.java)

                Maybe.just(cert)
                        .flatMap { certificate ->
                            val certificateFactory = CertificateFactory.getInstance("X.509")
                            val cert = certificateFactory.generateCertificates(
                                            base64decode(certificate.websocketCert!!).inputStream()).toList()[0]
                            val certDer = certificateFactory.generateCertificates(base64decode(certificate.websocketCertDer!!).inputStream()).toList()[0]
                            val trustManager = x509TrustManager(base64decode(certificate.websocketCertDer!!).inputStream())
                            val socketFactory = TlsSocketFactory(tlsSocketFactory(arrayOf(trustManager)))
                            val floWebSocket = Scarlet.Builder()
                                    .webSocketFactory(OkHttpClient.Builder()
                                            .hostnameVerifier { _, _ -> true }
                                            .addInterceptor(HttpLoggingInterceptor().apply {
                                                level = HttpLoggingInterceptor.Level.BODY
                                            })
                                            .connectionSpecs(listOf(ConnectionSpec.Builder(ConnectionSpec.MODERN_TLS).tlsVersions(TlsVersion.TLS_1_2).build(),
                                                    ConnectionSpec.COMPATIBLE_TLS,
                                                    ConnectionSpec.CLEARTEXT))
                                            .addInterceptor { chain ->
                                                chain.proceed(chain.request()
                                                        .newBuilder()
                                                        .addHeader("User-Agent", "Flo-Android")
                                                        .build())
                                            }
                                            .sslSocketFactory(socketFactory, trustManager)
                                            .build()
                                            .newWebSocketFactory("wss://flodevice:8000/"))
                                    .addMessageAdapterFactory(MoshiMessageAdapter.Factory())
                                    .addStreamAdapterFactory(RxJava2StreamAdapterFactory())
                                    .build()
                                    .create<FloWebSocket>()

                            floWebSocket.login(certificate.token!!)
                            floWebSocket.onLogin()
                                    .lastElement()
                        }
                        .doOnError { e ->
                            //println(e)
                            e.printStackTrace()
                        }
                        .test()
                        .awaitDone(10, TimeUnit.SECONDS)
                        .assertValue(assert {
                            println(it)
                            true
                        })
            }
        }
    }
})

fun <T> assert(consumer: (T) -> Unit): (T) -> Boolean {
    return {
        consumer.invoke(it)
        true
    }
}

@Throws(GeneralSecurityException::class)
private fun emptyKeyStore(password: CharArray): KeyStore {
    try {
        val keyStore = KeyStore.getInstance(KeyStore.getDefaultType())
        val certificate: InputStream? = null // By convention, 'null' creates an empty key store.
        keyStore.load(certificate, password)
        return keyStore
    } catch (e: IOException) {
        throw AssertionError(e)
    }
}

@Throws(GeneralSecurityException::class)
fun x509TrustManager(input: InputStream): X509TrustManager {
    val certificateFactory = CertificateFactory.getInstance("X.509")
    val certificates = certificateFactory.generateCertificates(input)
    input.close()
    if (certificates.isEmpty()) {
        throw IllegalArgumentException("expected non-empty set of trusted certificates")
    }

    // Put the certificates a key store.
    val password = "password".toCharArray() // Any password will work.
    val keyStore = emptyKeyStore(password)
    var index = 0
    for (certificate in certificates) {
        val certificateAlias = Integer.toString(index++)
        keyStore.setCertificateEntry(certificateAlias, certificate)
    }

    // Use it to build an X509 trust manager.
    val keyManagerFactory = KeyManagerFactory.getInstance(
            KeyManagerFactory.getDefaultAlgorithm())
    keyManagerFactory.init(keyStore, password)
    val trustManagerFactory = TrustManagerFactory.getInstance(
            TrustManagerFactory.getDefaultAlgorithm())
    trustManagerFactory.init(keyStore)
    val trustManagers = trustManagerFactory.trustManagers
    if (trustManagers.isEmpty() || trustManagers[0] !is X509TrustManager) {
        throw IllegalStateException("Unexpected default trust managers:" + Arrays.toString(trustManagers))
    }
    return trustManagers[0] as X509TrustManager
}

fun tlsSocketFactory(trustManagers: Array<TrustManager>, keyManagers: Array<KeyManager>? = null, protocol: String = "TLSv1.2"): SSLSocketFactory {
    val context = SSLContext.getInstance(protocol)
    context.init(keyManagers, trustManagers, null)

    return context.socketFactory
}

class TlsSocketFactory : SSLSocketFactory {

    private val mSocketFactory: SSLSocketFactory
    private val mProtocols: Array<String>

    constructor(protocol: String = "TLSv1.2", protocols: Array<String> = arrayOf("TLSv1.1", "TLSv1.2")) {
        val context = SSLContext.getInstance(protocol)
        context.init(null, null, null)
        mSocketFactory = context.socketFactory
        mProtocols = protocols
    }

    constructor(socketFactory: SSLSocketFactory, protocols: Array<String> = arrayOf("TLSv1.1", "TLSv1.2")) {
        mSocketFactory = socketFactory
        mProtocols = protocols
    }

    override fun getDefaultCipherSuites(): Array<String> {
        return mSocketFactory.defaultCipherSuites
    }

    override fun getSupportedCipherSuites(): Array<String> {
        return mSocketFactory.supportedCipherSuites
    }

    // java.net.SocketException: Unconnected is not implemented
    @Throws(IOException::class)
    override fun createSocket(): Socket {
        return enableProtocols(mSocketFactory.createSocket(), mProtocols)
    }

    @Throws(IOException::class)
    override fun createSocket(s: Socket, host: String, port: Int, autoClose: Boolean): Socket {
        return enableProtocols(mSocketFactory.createSocket(s, host, port, autoClose), mProtocols)
    }

    @Throws(IOException::class, UnknownHostException::class)
    override fun createSocket(host: String, port: Int): Socket {
        return enableProtocols(mSocketFactory.createSocket(host, port), mProtocols)
    }

    @Throws(IOException::class, UnknownHostException::class)
    override fun createSocket(host: String, port: Int, localHost: InetAddress, localPort: Int): Socket {
        return enableProtocols(mSocketFactory.createSocket(host, port, localHost, localPort), mProtocols)
    }

    @Throws(IOException::class)
    override fun createSocket(host: InetAddress, port: Int): Socket {
        return enableProtocols(mSocketFactory.createSocket(host, port), mProtocols)
    }

    @Throws(IOException::class)
    override fun createSocket(address: InetAddress, port: Int, localAddress: InetAddress, localPort: Int): Socket {
        return enableProtocols(mSocketFactory.createSocket(address, port, localAddress, localPort), mProtocols)
    }

    fun enableProtocols(socket: Socket, protocols: Array<String>): Socket {
        if (socket is SSLSocket) {
            socket.enabledProtocols = protocols
        }
        return socket
    }
}

