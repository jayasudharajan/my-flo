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

class FloAccountIntegrationSpec : Spek({
    describe("FloAccountIntegrationSpec") {
        val converter = Json.nonstrict.asConverterFactory(MediaType.parse("application/json")!!)
        val adapter = RxJava2CallAdapterFactory.create()
        val interceptor = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }

        on("dev") {
            //val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api.meetflo.com/api/v1/"
            //val clientId = System.getenv("FLO_CLIENT_ID") ?: "3baec26f-0e8b-4e1d-84b0-e178f05ea0a5"
            val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
            val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
            val username = System.getenv("FLO_USERNAME")
            val password = System.getenv("FLO_PASSWORD")
            val login = Login()
            if (username == null) return@on
            if (password == null) return@on
            login.username = username
            login.password = password

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

            val oauth = Oauth()
            oauth.username = username
            oauth.password = password
            oauth.clientId = clientId
            oauth.clientSecret = oauth.clientId
            oauth.grantType = "password" // FIXME constant
            val floTokenObs = floDev.oauth(oauth)
                    .map { it.accessToken!! }
                    .map { "Bearer ${it}" }
                    .cache()

            it("should return user info") {
                floTokenObs
                        .doOnNext { println(it) }
                        .flatMap { token ->
                            floDev.userId(token)
                                    .flatMap { userId ->
                                        floDev.getUserInfo(token, userId)
                                    }
                        }
                        .doOnNext { println(it) }
                        .singleElement().test()
                        .assertValue(assert {
                            true
                        })
            }
            it("should return account") {
                floTokenObs
                        .doOnNext { println(it) }
                        .flatMap { token ->
                            floDev.accountId(token)
                                    .flatMap { accountId ->
                                        floDev.getAccount(token, accountId=accountId)
                                    }
                        }
                        .doOnNext { println(it) }
                        .doOnNext { println(it.string()) }
                        .singleElement().test()
                        .assertValue(assert {
                            true
                        })
            }
            it("should return my account") {
                floTokenObs
                        .doOnNext { println(it) }
                        .flatMap { token ->
                            floDev.getMyAccount(token)
                        }
                        .doOnNext { println(it) }
                        .doOnNext { println(it.string()) }
                        .singleElement().test()
                        .assertValue(assert {
                            true
                        })
            }
            it("should return groupId") {
                floTokenObs
                        .doOnNext { println(it) }
                        .flatMap { token ->
                            floDev.groupId(token)
                        }
                        .doOnNext { println("groupId: ${it}") }
                        .singleElement().test()
                        .assertValue(assert {
                            assertThat(it).isEqualTo("")
                        })
            }
        }
    }
})
