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

class NotificationIntegrationSpec : Spek({
    describe("NotificationIntegrationSpec") {
        val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
        val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
        val username = System.getenv("FLO_USERNAME")
        val password = System.getenv("FLO_PASSWORD")
        val tester = Login()
        if (username == null) return@describe
        if (password == null) return@describe
        tester.username = username
        tester.password = password
        val admin = Login()
        admin.username = System.getenv("FLO_ADMIN_USERNAME")
        admin.password = System.getenv("FLO_ADMIN_PASSWORD")

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

        it("should response tokens") {
            floDev.auth(tester).singleElement().test().assertValue(assert {
                println(it.token)
                it.token `should not equal` ""
                it.token `should not equal` null
            })
        }

        it("should addtoken successfully") {
            val notificationToken = UserToken()
            notificationToken.token = "yo"
            notificationToken.deviceType = "android" // TODO: In the future, this maybe unnecessary. User-Agent instead.
            // TODO: Support remaining tasks, put into job queue, resend it while internet available
            floDev.auth(tester).flatMap { credential ->
                floDev.addToken(credential.token!!, notificationToken)
            }.test().assertNoErrors().assertValue(assert {
                println("${it.string()}")
            })
        }

        it("should response yo within notification tokens") {
            floDev.auth(admin).flatMap { credential ->
                floDev.auth(tester).flatMap { testerCredential ->
                    println("${credential.tokenPayload!!.user!!.id!!}")
                    println("${testerCredential.tokenPayload!!.user!!.id!!}")
                    floDev.notificationTokens(credential.token!!, testerCredential.tokenPayload!!.user!!.id!!)
                }
            }.singleElement().test().assertValue(assert { tokens ->
                assertThat(tokens.androidTokens).contains("yo")
            })
        }

        it("should response yo2 within notification tokens") {
            val notificationToken2 = UserToken()
            notificationToken2.token = "yo2"
            notificationToken2.deviceType = "android" // TODO: In the future, this maybe unnecessary. User-Agent instead.
            // TODO: Support remaining tasks, put into job queue, resend it while internet available
            floDev.auth(tester).flatMap { credential ->
                floDev.addToken(credential.token!!, notificationToken2)
            }.test().assertNoErrors().assertValue(assert {
                println("${it.string()}")
            })
            floDev.auth(admin).flatMap { credential ->
                floDev.auth(tester).flatMap { testerCredential ->
                    println("${credential.tokenPayload!!.user!!.id!!}")
                    println("${testerCredential.tokenPayload!!.user!!.id!!}")
                    floDev.notificationTokens(credential.token!!, testerCredential.tokenPayload!!.user!!.id!!)
                }
            }.singleElement().test().assertValue(assert { tokens ->
                assertThat(tokens.androidTokens).contains("yo2")
            })
        }

        it("should exist yo2 notification token after logout with yo token") {
            floDev.auth(tester).flatMap { testerCredential ->
                val logout = Logout()
                logout.notificationToken = "yo"
                floDev.logout(testerCredential.token!!, logout)
            }.singleElement().test().assertNoErrors()

            floDev.auth(admin).flatMap { credential ->
                floDev.auth(tester).flatMap { testerCredential ->
                    println("${credential.tokenPayload!!.user!!.id!!}")
                    println("${testerCredential.tokenPayload!!.user!!.id!!}")
                    floDev.notificationTokens(credential.token!!, testerCredential.tokenPayload!!.user!!.id!!)
                }
            }.singleElement().test().assertValue(assert { tokens ->
                assertThat(tokens.androidTokens).doesNotContain("yo")
                assertThat(tokens.androidTokens).contains("yo2")
            })
        }

        it("should empty notification token after logout with yo and yo2 tokens") {
            floDev.auth(tester).flatMap { testerCredential ->
                val logout = Logout()
                logout.notificationToken = "yo2"
                floDev.logout(testerCredential.token!!, logout)
            }.singleElement().test().assertNoErrors()

            floDev.auth(admin).flatMap { credential ->
                floDev.auth(tester).flatMap { testerCredential ->
                    println("${credential.tokenPayload!!.user!!.id!!}")
                    println("${testerCredential.tokenPayload!!.user!!.id!!}")
                    floDev.notificationTokens(credential.token!!, testerCredential.tokenPayload!!.user!!.id!!)
                }
            }.singleElement().test().assertValue(assert { tokens ->
                assertThat(tokens.androidTokens).isEmpty()
            })
        }
    }
})
