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
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.MockResponse

class FloDetectSpec : Spek({
    describe("FloDetectSpec") {
        val login = Login()
        val server = MockWebServer()
        server.start()

        val converter = Json.nonstrict.asConverterFactory(MediaType.parse("application/json")!!)
        val adapter = RxJava2CallAdapterFactory.create()
        val flo = Retrofit.Builder()
                .client(OkHttpClient.Builder()
                        .addInterceptor { chain ->
                            chain.proceed(chain.request()
                                    .newBuilder()
                                    .addHeader("User-Agent", "Flo-Android")
                                    .build())
                        }
                        .build())
                .addCallAdapterFactory(adapter)
                .addConverterFactory(converter)
                .baseUrl(server.url("/").toString())
                .build().create(Flo::class.java)
        var token: String? = null

        it("should return flodetect local") {
            server.enqueue(MockResponse().setResponseCode(202).setBody(javaClass.classLoader.getResourceAsStream("flodetect/latest/fff/3600.json")!!.reader().readText()))
            flo.getFloDetect(authorization = "",
                    deviceId = "fff",
                    seconds = 3600L)
                    .singleElement()
                    .test()
                    .assertValue(assert {
                        assertThat(it.request_id).isNotNull()
                        assertThat(it.request_id).isEqualTo("7d9fb4ab-9034-482c-a4e7-84a7bef91997")
                    })

        }
        it("should return flow events local") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("flodetect/latest/fff/3600.json")!!.reader().readText()))
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("flodetect/event/fff/7d9fb4ab-9034-482c-a4e7-84a7bef91997.json")!!.reader().readText()))
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("flodetect/event/fff/7d9fb4ab-9034-482c-a4e7-84a7bef91997.json")!!.reader().readText()))
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("flodetect/event/fff/7d9fb4ab-9034-482c-a4e7-84a7bef91997.json")!!.reader().readText()))
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("flodetect/event/fff/7d9fb4ab-9034-482c-a4e7-84a7bef91997-2.json")!!.reader().readText()))
            flo.getFlowEventsPaged("", "fff", 7, TimeUnit.DAYS)
                    .count()
                    .test()
                    .assertValue(assert {
                        assertThat(it).isEqualTo(302)
                    })
        }

        it("feedback() should return flowEvent local") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("flodetect/event/fff/7d9fb4ab-9034-482c-a4e7-84a7bef91997-single.json")!!.reader().readText()))
            flo.feedback("", "fff", "","", FlowFeedback().apply {
                cases = 0
                correctFixture = "faucet"
            })
                .test()
                .assertValue(assert {
                    assertThat(it.feedback?.correctFixture).isEqualTo("faucet")
                    assertThat(it.feedback?.cases).isEqualTo(0)
                })
        }
    }
})
