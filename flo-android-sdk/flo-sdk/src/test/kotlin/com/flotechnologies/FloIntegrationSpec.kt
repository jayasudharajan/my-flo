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

class FloIntegrationSpec : Spek({
    describe("FloIntegrationSpec") {
        val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
        val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
        val username = System.getenv("FLO_USERNAME")
        val password = System.getenv("FLO_PASSWORD")
        val login = Login()
        val FAKE_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjbGllbnRfaWQiOiJmZmZmZmZmZi1mZmZmLTRmZmYtOGZmZi1mZmZmZmZmZmZmZmYiLCJ1c2VyX2lkIjoiZmZmZmZmZmYtZmZmZi00ZmZmLThmZmYtZmZmZmZmZmZmZmZmIiwiaWF0IjoxNTQ4NzQ0ODg2LCJleHAiOjE1NDg4MzEyODYsImp0aSI6ImZmZmZmZmZmLWZmZmYtNGZmZi04ZmZmLWZmZmZmZmZmZmZmZiJ9.Xh7tDNBCHUZBr_oqolwYUJVkSBm3BGiXli76qjldZD8"
        login.username = username
        login.password = password
        if (username == null) return@describe
        if (password == null) return@describe

        val converter = Json.nonstrict.asConverterFactory(MediaType.parse("application/json")!!)
        val adapter = RxJava2CallAdapterFactory.create()
        val client = OkHttpClient.Builder().build()
        var token: String? = null

        // It's testing connection with real flo api dev server
        // Maybe slow down testing process
        // Make sure api server online
        on("dev") {
            val interceptor = HttpLoggingInterceptor()
            interceptor.level = HttpLoggingInterceptor.Level.BODY
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
            val floDev2 = Retrofit.Builder()
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

            it("should response token") {
                floDev.auth(login).singleElement().test().assertValue(assert {
                    println(it.token)
                    it.token `should not equal` ""
                    it.token `should not equal` null
                })
            }
            it("should be put first_name successfully") {
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            val user = UserProfile()
                            user.firstName = "Cookie "

                            floDev.userDetails(token, user)
                        }
                        .singleElement().test().assertValue(assert { it ->
                            it.attributes!!.firstName `should not equal` ""
                            it.attributes!!.firstName `should not equal` null
                        })
            }
            // TODO
            it("should be put user-id failure") {
                //floDev.auth(login)
                //    .map { it.token!! }
                //    .flatMap { token ->
                //        val user = UserProfile()
                //        user.userId = "ffffffff-ffff-ffff-ffff-ffffffffffff"
                //        floDev.userDetails(token, user)
                //    }
                //    .singleElement().test().assertError { true }
            }
            it("should be put location (home profile) successfully") {
                //val randomString = Gen.string().generate()
                val randomString = "123"
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            val home = HomeProfile()
                            home.address = "6633, Yucca St. ${randomString}"

                            floDev.locations(token, home)
                        }
                        .singleElement().test().assertValue(assert { it ->
                            it.attributes!!.address `should not equal` ""
                            it.attributes!!.address `should not equal` null
                        }).await()
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token -> floDev.locations(token) }
                        .singleElement().test().assertValue(assert { it ->
                            it.address `should equal` "6633, Yucca St. ${randomString}"
                        })
            }
            it("should response forgot password message successfully") {
                val forgotPassword = ForgotPassword()
                forgotPassword.email = "andrew+reset@flotechnologies.com"
                floDev.resetUser(forgotPassword).singleElement().test()
                        .assertValue(assert {
                            assertThat(it.message).contains(forgotPassword.email)
                        })
            }

            // We have no registeration tokens that always successfully
            //it("should response register successfully") {
            //    val register = Register()
            //    register.token1 = "c689ee6a-b13a-4fbe-a02c-70268230a0c0"
            //    register.token2 = "3932964f-419a-4229-bc79-0d20e18a9b37"
            //    floDev.register(register.token1!!, register.token2!!).singleElement().test()
            //        .assertValue(assert {
            //            assertThat(it.token1).contains(register.token1)
            //        })
            //        .assertValue(assert {
            //            assertThat(it.token2).contains(register.token2)
            //        })
            //}

            it("should response register failure") {
                val register = Register()
                register.token1 = "649e6b32-c842-4fdd-830f-82b56b0f2ee5"
                register.token2 = "171e8dce-25d2-4c15-92b5-eea16fa016a9"

                floDev.register(register.token1!!, register.token2!!).singleElement().test()
                        //.assertValue(assert {
                        //    assertThat(it.token1).contains(register.token1)
                        //})
                        //.assertValue(assert {
                        //    assertThat(it.token2).contains(register.token2)
                        //})
                        .assertError(HttpException::class.java)
                        .assertError(assert {
                            val e = it as HttpException
                            val error = converter.responseBodyConverter(Error::class.java, emptyArray(), null)
                                    ?.convert(e.response().errorBody()) as? Error?
                            assertThat(error?.error).isEqualTo(true)
                            // "Something went wrong. Please contact Flo support"
                            //error.message `should equal` "Registration token expired."
                        })

                //floDev.register(register).singleElement().test()
                //        .assertValue(assert {
                //            assertThat(it.token1).contains(register.token1)
                //        })
                //        .assertValue(assert {
                //            assertThat(it.token2).contains(register.token2)
                //        })
            }

            // doesn't work
            //it("should response daily usage") {
            //    floDev.auth(login)
            //            .map { it.token!! }
            //            .flatMap { token ->
            //                floDev.usageDaily(token)
            //                        .doOnNext { println("$it") }
            //            }
            //            .doOnNext { println("$it") }
            //    .singleElement().test().assertComplete().await()
            //}

            it("should add push notification token") {
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            val map: HashMap<String, String> = HashMap()
                            map.put("token", "notification-token-xxx")
                            floDev2.notificationTokens(token, "me", "android-device-id-xxx", map)
                        }
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should present push notification token") {
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            floDev2.activeNotificationTokens(token, "me")
                        }
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should delete push notification token") {
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            floDev2.deleteNotificationTokens(token, "me", "android-device-id-xxx")
                        }
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should get us states without auth") {
                floDev.stateProvinces("us")
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should get uk states without auth") {
                floDev.stateProvinces("uk")
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should get de states without auth") {
                floDev.stateProvinces("de")
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should get us states") {
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            floDev.stateProvinces(token, "us")
                        }
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should get uk states") {
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            floDev.stateProvinces(token, "uk")
                        }
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should get de states") {
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            floDev.stateProvinces(token, "de")
                        }
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
            it("should return cleared alerts") {
                floDev.auth(login)
                        .map { it.token!! }
                        .flatMap { token ->
                            floDev.icds(token).flatMap { dev ->
                                floDev.clearedAlerts(authorization = token, icdId = dev.data!!, page = 1, size = 180)
                            }
                        }
                        .singleElement().test()
                        .assertValue(assert { it ->
                            println(it)
                        })
            }
        }
    }
})

