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

/**
 * require a user has a ICD at least
 */
class NotificationsIntegrationSpecSpec : Spek({
    describe("NotificationsIntegrationSpecSpec") {
        val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
        val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
        val username = System.getenv("FLO_USERNAME")
        val password = System.getenv("FLO_PASSWORD")
        val tester = Login()
        if (username == null) return@describe
        if (password == null) return@describe
        tester.username = username
        tester.password = password

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

        it("should response alarms") {
            floDev.auth(tester)
                    .flatMap { credential ->
                        floDev.icds(credential.token!!)
                                .flatMap { dev ->
                                    floDev.notifications(credential.token!!, dev.data!!)
                                }
                    }
                    .doOnNext {
                        println("$it")
                        it.items?.forEach {
                            println("$it")
                        }
                    }
                    .test()
                    .assertNoErrors()
        }
        //it("should get alerts") {
        //    floDev.auth(login)
        //            .map { it.token!! }
        //            .flatMap { token ->
        //                floDev.icds(token).flatMap { dev ->
        //                    floDev.alerts(authorization = token, icdId = dev.data!!, page = 1, size = 180)
        //                }
        //            }
        //            .singleElement().test()
        //            .assertValue(assert { it ->
        //                println(it)
        //            })
        //}
    }
})
