package com.flotechnologies;

import com.jakewharton.retrofit2.adapter.rxjava2.HttpException
import com.jakewharton.retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import org.amshove.kluent.`should equal`
import org.amshove.kluent.`should not equal`
import org.assertj.core.api.Assertions.assertThat
import org.jetbrains.spek.api.Spek
import retrofit2.Retrofit

class SystemModeSpec : Spek({
    /** FIXME: cannot these test cases because we have no mock ICD under the testing user */
    describe("SystemModeSpec") {
        val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
        val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
        val username = System.getenv("FLO_USERNAME")
        val password = System.getenv("FLO_PASSWORD")
        val login = Login()
        login.username = username
        login.password = password

        /*
        val converter = Json.asConverterFactory(MediaType.parse("application/json")!!)
        val adapter = RxJava2CallAdapterFactory.create()
        var token: String? = null

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

        it("should response token") {
            floDev.auth(login).singleElement().test().assertValue(assert {
                println(it.token)
                it.token `should not equal` ""
                it.token `should not equal` null
            })
        }
        it("should set away system mode successfully") {
            floDev.auth(login).flatMap { credential ->
            floDev.icds(credential.token!!).flatMap { dev ->
                val mode = SystemMode()
                mode.id = MODE_AWAY.toLong()
                floDev.systemMode(credential.token!!, dev.deviceId!!, mode)
            }}
            .test().assertNoErrors().assertComplete().assertValue(assert {
              println("$it")
            })
        }

        it("should set home system mode successfully") {
            floDev.auth(login).flatMap { credential ->
            floDev.icds(credential.token!!).flatMap { dev ->
                val mode = SystemMode()
                mode.id = MODE_HOME.toLong()
                floDev.systemMode(credential.token!!, dev.deviceId!!, mode)
            }}
            .test().assertNoErrors().assertComplete().assertValue(assert {
              println("$it")
            })
        }
        */
    }
})
