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
import java.util.*
import java.util.concurrent.TimeUnit

class FloDetectIntegrationSpec : Spek({
    describe("FloDetectIntegrationSpec") {
        val converter = Json.nonstrict.asConverterFactory(MediaType.parse("application/json")!!)
        val adapter = RxJava2CallAdapterFactory.create()
        val interceptor = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }

        on("dev") {
            val login = Login()
            val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
            val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
            val username = System.getenv("FLO_USERNAME")
            val password = System.getenv("FLO_PASSWORD")
            if (username == null) return@on
            if (password == null) return@on

            // It's testing connection with real flo api dev server
            // Maybe slow down testing process
            // Make sure api server online
            val floDev = Retrofit.Builder()
                    .client(OkHttpClient.Builder()
                            .addInterceptor(interceptor)
                            .addInterceptor { chain ->
                                chain.proceed(chain.request()
                                        .newBuilder()
                                        .addHeader("User-Agent", "Flo-Android")
                                        .build())
                            }
                            .build())
                    .addCallAdapterFactory(adapter)
                    .addConverterFactory(converter)
                    .baseUrl(baseUrl)
                    .build().create(Flo::class.java)
            var token: String? = null

            it("should return flodetect") {
                floDev.auth(login)
                        .map { it.token!! }
                        .doOnNext {
                            token = it
                        }
                        .flatMap {
                            floDev.icds(token!!)
                        }
                        .map { floDevice -> floDevice.deviceId!! }
                        .flatMap { deviceId ->
                            floDev.getFloDetect(token!!, deviceId, 24 * 60 * 60 * 1L)
                                    .flatMap {
                                        floDev.getFlowEventsPaged(token!!, deviceId, it.request_id!!)
                                    }
                        }
                        .singleElement().test()
                        .assertValue(assert {
                            println(it)
                        })
            }
            it("should return paged flodetect") {
                floDev.auth(login)
                        .map { it.token!! }
                        .doOnNext {
                            token = it
                        }
                        .flatMap {
                            floDev.icds(token!!)
                        }
                        .map { floDevice -> floDevice.deviceId!! }
                        .flatMap { deviceId ->
                            floDev.getFloDetect(token!!, deviceId, 24 * 60 * 60 * 7L)
                                    .flatMap {
                                        floDev.getFlowEventsPaged(authorization = token!!, deviceId = deviceId, requestId = it.request_id!!, size = 100, start = "2018-07-18T20:39:19")
                                    }
                        }
                        .singleElement().test()
                        .assertValue(assert {
                            println(it)
                            println("${it.size}")
                        })
            }
            it("should return flow events") {
                floDev.auth(login)
                        .map { it.token!! }
                        .doOnNext { token = it }
                        .flatMap { floDev.icds(token!!) }
                        .map { floDevice -> floDevice.deviceId!! }
                        .flatMap { deviceId -> floDev.getFloDetect(token!!, deviceId, 1, TimeUnit.DAYS) }
                        .count()
                        .test()
                        .assertValue(assert {
                            println(it)
                        })
            }
            it("dev: feedback should return flow event") {
                var deviceId: String? = null
                var requestId: String? = null

                floDev.auth(login)
                        .map { it.token!! }
                        .doOnNext { token = it }
                        .flatMap { floDev.icds(it) }
                        .map { it.deviceId!! }
                        .doOnNext { deviceId = it }
                        .flatMap { deviceId -> floDev.getFloDetect(token!!, deviceId, 1, TimeUnit.DAYS) }
                        .map { it.request_id!! }
                        .doOnNext { requestId = it }
                        .flatMap { floDev.getFlowEventsPages(token!!, deviceId = deviceId!!, requestId = it, size = 1).take(1) }
                        .flatMap {
                            floDev.feedback(authorization = token!!, deviceId=deviceId!!, requestId=requestId!!, start=it.start!!, feedback=FlowFeedback().apply {
                                cases = 0
                                correctFixture = it.fixture!!
                            })
                        }
                        .test()
                        .assertValue(assert {
                            println(it)
                        })
            }
        }
    }
})
