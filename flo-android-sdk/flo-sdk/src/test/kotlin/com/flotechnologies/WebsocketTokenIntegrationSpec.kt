package com.flotechnologies;

import com.jakewharton.retrofit2.adapter.rxjava2.HttpException
import com.jakewharton.retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import kotlinx.serialization.json.Json
import okhttp3.MediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import org.amshove.kluent.`should equal`
import org.amshove.kluent.`should not equal`
import org.assertj.core.api.Assertions.assertThat
import org.jetbrains.spek.api.Spek
import retrofit2.Retrofit

class WebsocketTokenIntegrationSpecSpec : Spek({
    describe("WebsocketTokenIntegrationSpecSpec") {
        val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
        val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
        val username = System.getenv("FLO_USERNAME")
        val password = System.getenv("FLO_PASSWORD")
        if (username == null) return@describe
        if (password == null) return@describe
        val admin = Login()
        admin.username = System.getenv("FLO_ADMIN_USERNAME")
        admin.password = System.getenv("FLO_ADMIN_PASSWORD")

        val converter = Json.asConverterFactory(MediaType.parse("application/json")!!)
        val adapter = RxJava2CallAdapterFactory.create()

        val interceptor = HttpLoggingInterceptor()
        interceptor.level = HttpLoggingInterceptor.Level.BODY
        val floDev = Retrofit.Builder()
                .client(OkHttpClient.Builder()
                    .addInterceptor(interceptor)
                    .build())
                .addCallAdapterFactory(adapter)
                .addConverterFactory(converter)
                .baseUrl(baseUrl)
                .build().create(Flo::class.java)

        it("should response websocket token") {
            floDev.auth(admin).flatMap { credential ->
                floDev.websocketToken(credential.token!!, "8cc7aa027840")
            }.singleElement().test().assertValue(assert { token ->
                assertThat(token.token!!).startsWith("225d")
            })
        }
    }
})
