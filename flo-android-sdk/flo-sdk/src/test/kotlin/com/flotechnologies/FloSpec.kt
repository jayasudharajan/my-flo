package com.flotechnologies;

import com.jakewharton.retrofit2.adapter.rxjava2.HttpException
import com.jakewharton.retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import kotlinx.serialization.json.Json
import okhttp3.MediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.amshove.kluent.`should equal`
import org.amshove.kluent.`should not equal`
import org.assertj.core.api.Assertions.assertThat
import org.jetbrains.spek.api.Spek
import retrofit2.Retrofit
import java.util.*

class FloSpec : Spek({
    describe("FloSpec") {
        val baseUrl = System.getenv("FLO_BASE_URL") ?: "https://api-dev.flocloud.co/api/v1/"
        val clientId = System.getenv("FLO_CLIENT_ID") ?: "199eba7e-a1cc-4b18-9821-301acc0503c9"
        val username = System.getenv("FLO_USERNAME")
        val password = System.getenv("FLO_PASSWORD")
        val login = Login()
        val FAKE_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjbGllbnRfaWQiOiJmZmZmZmZmZi1mZmZmLTRmZmYtOGZmZi1mZmZmZmZmZmZmZmYiLCJ1c2VyX2lkIjoiZmZmZmZmZmYtZmZmZi00ZmZmLThmZmYtZmZmZmZmZmZmZmZmIiwiaWF0IjoxNTQ4NzQ0ODg2LCJleHAiOjE1NDg4MzEyODYsImp0aSI6ImZmZmZmZmZmLWZmZmYtNGZmZi04ZmZmLWZmZmZmZmZmZmZmZiJ9.Xh7tDNBCHUZBr_oqolwYUJVkSBm3BGiXli76qjldZD8"
        val FAKE_UUID = "ffffffff-ffff-4fff-8fff-ffffffffffff"
        login.username = username
        login.password = password

        val server = MockWebServer()
        //server.url("/").toString()
        server.start()

        val converter = Json.nonstrict.asConverterFactory(MediaType.parse("application/json")!!)
        val adapter = RxJava2CallAdapterFactory.create()
        val client = OkHttpClient.Builder().build()

        val flo = Retrofit.Builder()
                .client(client)
                .addCallAdapterFactory(adapter)
                .addConverterFactory(converter)
                .baseUrl(server.url("/").toString())
                .build().create(Flo::class.java)

        on("auth") {
            it("should response no values") {
                server.enqueue(MockResponse().setResponseCode(200).setBody(""))
                flo.auth(login).singleElement()
                        .test().assertNoValues()
                server.takeRequest()
            }

            it("should response token") {
                server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("auth.json")!!.reader().readText()))

                flo.auth(login).singleElement()
                        .doOnError { server.takeRequest() }
                        .test().assertValue(assert {
                    server.takeRequest()
                    it.token `should equal` FAKE_TOKEN
                })
            }

            it("should response empty token") {
                server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("auth-empty-token.json")!!.reader().readText()))
                flo.auth(login).singleElement()
                        .doOnError { server.takeRequest() }
                        .test().assertValue(assert {
                    server.takeRequest()
                    it.token `should equal` ""
                })
            }

            it("should response empty user") {
                server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("auth-empty-user.json")!!.reader().readText()))
                flo.auth(login).singleElement()
                        .doOnError { server.takeRequest() }
                        .test().assertValue(assert {
                    server.takeRequest()
                    it.tokenPayload!!.user `should equal` null
                })
            }

            it("should response empty tokenPayload") {
                server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("auth-empty-tokenPayload.json")!!.reader().readText()))
                flo.auth(login).singleElement()
                        .doOnError { server.takeRequest() }
                        .test().assertValue(assert {
                    server.takeRequest()
                    it.tokenPayload `should equal` null
                })
            }

            it("should response credential") {
                server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("auth.json")!!.reader().readText()))

                var credential = Json.nonstrict.parse(Credential.serializer(), javaClass.classLoader.getResourceAsStream("auth.json")!!.reader().readText())
                flo.auth(login).singleElement()
                        .doOnError { server.takeRequest() }
                        .test()
                        .assertValue(assert {
                            server.takeRequest()
                            it.tokenExpiration `should equal` credential.tokenExpiration
                        })
                        .assertValue(assert {
                            it.token `should equal` credential.token
                        })
                        .assertValue(assert {
                            it.tokenPayload!!.user!!.id `should equal` credential.tokenPayload!!.user!!.id
                        })
                        .assertValue(assert {
                            it.tokenPayload!!.timestamp `should equal` credential.tokenPayload!!.timestamp
                        })
                        .assertValue(assert {
                            it.timeNow `should equal` credential.timeNow
                        })
                        .assertValue(assert {
                            it.tokenExpiration `should equal` credential.tokenExpiration
                        })
            }

            it("should response credential raw") {
                // TODO: Move to CredentialSpec
                server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("auth.json")!!.reader().readText()))

                val userId = "ffffffff-ffff-4fff-8fff-ffffffffffff"
                val email = "user@example.com"
                val timestamp = 1483754330L
                val tokenExpiration = 86400L
                val timeNow = 1483754330L

                flo.auth(login).singleElement()
                        .doOnError { server.takeRequest() }
                        .test()
                        .assertValue(assert {
                            server.takeRequest()
                            it.tokenExpiration `should equal` tokenExpiration
                        })
                        .assertValue(assert {
                            it.token `should equal` FAKE_TOKEN
                        })
                        .assertValue(assert {
                            it.tokenPayload!!.user!!.id `should equal` userId
                        })
                        .assertValue(assert {
                            it.tokenPayload!!.user!!.email `should equal` email
                        })
                        .assertValue(assert {
                            it.tokenPayload!!.timestamp `should equal` timestamp
                        })
                        .assertValue(assert {
                            it.timeNow `should equal` timeNow
                        })
                        .assertValue(assert {
                            it.tokenExpiration `should equal` tokenExpiration
                        })
            }
        }
        /*
        it("should be mqtt permissions") {
            server.enqueue(MockResponse()
                    .setResponseCode(200)
                    .setBody(javaClass.classLoader.getResourceAsStream("mqtt-permissions.json")!!
                            .reader().readText()))
            flo.mqttTopicPermissions(token)
                    .singleElement().test()
                    .assertValue(assert { it ->
                        assertThat(it.size).isEqualTo(3)
                        assertThat(it[0].activity).isEqualTo("pub")
                        assertThat(it[1].activity).isEqualTo("sub")
                        assertThat(it[2].activity).isEqualTo("pub")
                        assertThat(it[0].topic).isEqualTo("8cc7aa0277c0")
                        assertThat(it[1].topic).isEqualTo("8cc7aa0277c1")
                        assertThat(it[2].topic).isEqualTo("8cc7aa0277c2")
                    })
        }
        it("should be group") {
            val uuid = UUID.randomUUID().toString()
            server.enqueue(MockResponse()
                    .setResponseCode(200)
                    .setBody("\"$uuid\""))
            flo.groupOfDevice(FAKE_TOKEN, deviceId)
                    .singleElement().test()
                    .assertValue(assert { it ->
                        assertThat(it).isEqualTo(uuid)
                    })
        }
        */
        it("should response location (home profile)") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("locations-me.json")!!.reader().readText()))

            flo.locations("").singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest()
                        it.expansionTank `should equal` 1L
                    })
                    .assertValue(assert {
                        it.stories `should equal` 4L
                    })
                    .assertValue(assert {
                        it.locationType `should equal` "Single Family Home"
                    })
                    .assertValue(assert {
                        it.occupants `should equal` 6L
                    })
                    .assertValue(assert {
                        it.bathroomAmenities!!.size `should equal` 3
                    })
                    .assertValue(assert {
                        it.bathroomAmenities!![0] `should equal` "Bathtub"
                    })
                    .assertValue(assert {
                        it.bathroomAmenities!![1] `should equal` "Jacuzzi"
                    })
                    .assertValue(assert {
                        it.bathroomAmenities!![2] `should equal` "Spa"
                    })
                    .assertValue(assert {
                        it.address `should equal` "1 sesame st"
                    })
                    .assertValue(assert {
                        it.postalcode `should equal` "90017"
                    })
                    .assertValue(assert {
                        it.accountId `should equal` "ffffffff-ffff-4fff-8fff-ffffffffffff"
                    })
                    .assertValue(assert {
                        it.country `should equal` "USA"
                    })
                    .assertValue(assert {
                        it.state `should equal` "CA"
                    })
                    .assertValue(assert {
                        it.city `should equal` "Los Angeles "
                    })
                    .assertValue(assert {
                        it.locationName `should equal` "Home"
                    })
                    .assertValue(assert {
                        it.tankless `should equal` 1L
                    })
                    .assertValue(assert {
                        it.locationSizeCategory `should equal` 4L
                    })
                    .assertValue(assert {
                        it.timezone `should equal` "America/Los_Angeles"
                    })
                    .assertValue(assert {
                        it.locationId `should equal` "ffffffff-ffff-4fff-8fff-ffffffffffff"
                    })
                    .assertValue(assert {
                        it.kitchenAmenities!!.size `should equal` 3
                    })
                    .assertValue(assert {
                        it.kitchenAmenities!![0] `should equal` "Washer / Dryer"
                    })
                    .assertValue(assert {
                        it.kitchenAmenities!![1] `should equal` "Dishwasher"
                    })
                    .assertValue(assert {
                        it.kitchenAmenities!![2] `should equal` "Fridge with Ice Maker"
                    })
        }
        it("should response empty alarms") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("icds-me-alarms-empty.json")!!.reader().readText()))
            flo.alarms("").singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest()
                        it.size `should equal` 0
                    })
        }
        it("should response severe alarm icd not found") {
            server.enqueue(MockResponse().setResponseCode(400).setBody(javaClass.classLoader.getResourceAsStream("severe-icd-not-found.json")!!.reader().readText()))

            flo.severeAlarms("").singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                .assertError(HttpException::class.java)
                .assertError(assert {
                    val e = it as HttpException
                    val error = Json.nonstrict.parseOrNull(Error.serializer(), e.response().errorBody()?.string() ?: "{}")

                    assertThat(error?.error).isEqualTo(true)
                    assertThat(error?.message).isEqualTo("No ICD found.")
                })
        }
        it("should response timezone") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("timezones-active.json")!!.reader().readText()))

            flo.timezones("").singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                .assertValue(assert {
                    server.takeRequest()
                    it.size `should equal` 7
                })
        }
        it("should response faq") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("faq.json")!!.reader().readText()))

            flo.faq("").singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertComplete()
            server.takeRequest()
        }
        it("should response dailygoal") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("goal.json")!!.reader().readText()))

            flo.dailyGoal("").singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest()
                        it.goal `should equal` 360L
                    })
        }
        it("should response userdetails (user profile)") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("userdetails-me.json")!!.reader().readText()))

            flo.userDetails("").singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest()
                        it.firstName `should equal` "Cookie "
                    })
                    .assertValue(assert {
                        it.phoneMobile `should equal` "8182725600"
                    })
                    .assertValue(assert {
                        it.lastName `should equal` "Monster "
                    })
                    .assertValue(assert {
                        it.userId `should equal` "ffffffff-ffff-4fff-8fff-ffffffffffff"
                    })
                    .assertValue(assert {
                        it.prefixName `should equal` "Mr"
                    })
        }
        it("should be serialize first_name by UserProfile") {
            assertThat(Json.stringify(UserProfile.serializer(), UserProfile().apply {
               firstName = "Andrew"
            })).contains("Andrew")
        }
        it("should response forgot password message successfully mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("forgot-password.json")!!.reader().readText()))
            val forgotPassword = ForgotPassword()
            forgotPassword.email = "user@example.com"
            flo.resetUser(forgotPassword).singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest()
                        assertThat(it.message).contains(forgotPassword.email)
                    })
        }
        it("should response register successfully mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("register.json")!!.reader().readText()))

            val register = Register()
            register.token1 = "ffffffff-ffff-4fff-8fff-ffffffffffff"
            register.token2 = "ffffffff-ffff-4fff-8fff-ffffffffffff"
            flo.register(register.token1!!, register.token2!!).singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest()
                        assertThat(it.token1).contains(register.token1)
                    })
                    .assertValue(assert {
                        assertThat(it.token2).contains(register.token2)
                    })

            //server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("register.json")!!.reader().readText()))
            //flo.register(register).singleElement().test()
            //        .assertValue(assert {
            //            assertThat(it.token1).contains(register.token1)
            //        })
            //        .assertValue(assert {
            //            assertThat(it.token2).contains(register.token2)
            //        })
        }

        it("should response register failure mocked") {
            server.enqueue(MockResponse().setResponseCode(500).setBody(javaClass.classLoader.getResourceAsStream("register-expired.json")!!.reader().readText()))

            val register = Register()
            register.token1 = "ffffffff-ffff-4fff-8fff-ffffffffffff"
            register.token2 = "ffffffff-ffff-4fff-8fff-ffffffffffff"
            flo.register(register.token1!!, register.token2!!).singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertError(HttpException::class.java)
                    .assertError(assert {
                        val e = it as HttpException
                        val error = Json.nonstrict.parseOrNull(Error.serializer(), e.response().errorBody()?.string() ?: "{}")
                        assertThat(error?.error).isEqualTo(true)
                        assertThat(error?.message).isEqualTo("Registration token expired.")
                    })
        }
        it("should response unauthorized access mocked") {
            server.enqueue(MockResponse().setResponseCode(500).setBody(javaClass.classLoader.getResourceAsStream("waterflow-today-unauthorized-dev.json")!!.reader().readText()))

            val dev = "8cc7aa0277c0"
            flo.today(FAKE_TOKEN, dev).singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertError(HttpException::class.java)
                    .assertError(assert {
                        val e = it as HttpException
                        val error = Json.nonstrict.parseOrNull(Error.serializer(), e.response().errorBody()?.string() ?: "{}")
                        assertThat(error?.error).isEqualTo(true)
                        assertThat(error?.message).isEqualTo("Unauthorized access.")
                    })
        }
        it("should response today values mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("today.json")!!.reader().readText()))

            val dev = "ffffffffffff"
            flo.today(FAKE_TOKEN, dev).singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest()
                        it.size `should equal` 24
                    })
        }
        it("should response register credential successfully mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("register-crediential.json")!!.reader().readText()))

            val register = Register()

            register.token1 = "ffffffff-ffff-4fff-8fff-ffffffffffff"
            register.token2 = "ffffffff-ffff-4fff-8fff-ffffffffffff"
            register.email = "user@example.com"
            register.firstName = "Andrew"
            register.lastName = "Chen"
            register.phoneMobile = "3101234567"
            register.password = "0910123456"
            register.address = ""
            register.address2 = ""
            register.city = ""
            register.state = ""
            register.postalCode = ""
            register.timeZone = "America/Los_Angeles"
            flo.register(register).singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                .assertValue(assert {
                    server.takeRequest()
                    it.token `should equal` FAKE_TOKEN
                })
        }
        it("should response icd mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("icd.json")!!.reader().readText()))

            flo.icds(FAKE_TOKEN).singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest().run {
                            path `should equal` "/icds/me"
                        }
                        it.paired `should equal` true
                    })
                    .assertValue(assert {
                        it.deviceId `should equal` "ffffffffffff"
                    })
                    .assertValue(assert {
                        it.data `should equal` "ffffffff-ffff-4fff-8fff-ffffffffffff"
                    })
                    .assertValue(assert {
                        it.locationId `should equal` "ffffffff-ffff-4fff-8fff-ffffffffffff"
                    })
                    .assertValue(assert {
                        it.fromCache `should equal` true
                    })
        }
        it("should response icd mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("monthlyusage.json")!!.reader().readText()))

            val dev = "ffffffffffff"
            flo.usageMonthly(FAKE_TOKEN, dev).singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        it.usage `should equal` "0.12"
                        server.takeRequest().run {
                            path `should equal` "/waterflow/monthlyusage/${dev}"
                        }
                    })
        }
        // TODO: test the following Flo APIs

        //faqIos(@Header("Authorization") authorization: String)

        //icds(@Header("Authorization") authorization: String, @Body dev: FloDevice)

        //clearAlarms(@Header("Authorization") authorization: String)

        //actionAlarms(@Header("Authorization") authorization: String, @Body action: AlarmAction)


        //powerreset(@Header("Authorization") authorization: String, @Path("dev-id") dev: String)
        //systemMode(@Header("Authorization") authorization: String, @Path("dev-id") dev: String, @Body mode: SystemMode)
        //sleep(@Header("Authorization") authorization: String, @Path("dev-id") dev: String, @Body mode: SleepMode)
        //closeValve(@Header("Authorization") authorization: String, @Path("dev-id") dev: String)
        //openValve(@Header("Authorization") authorization: String, @Path("dev-id") dev: String)
        //testZi(@Header("Authorization") authorization: String, @Path("dev-id") dev: String)
        //addToken(@Header("Authorization") authorization: String, @Body token: TokenPayload)
        //qrcode(@Header("Authorization") authorization: String, @Body icd: Icd)



        //auth(@Header("Authorization") authorization: String, @Body user: User)
        //logout(@Header("Authorization") authorization: String, @Body user: User)

        it("should response thisWeekWaterConsumption mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody(javaClass.classLoader.getResourceAsStream("this_week.json")!!.reader().readText()))

            flo.thisWeekWaterConsumption(FAKE_TOKEN, "ffffffff-ffff-4fff-8fff-ffffffffffff").singleElement()
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        assertThat(it.first().averagePressure).isNotNull()
                        it.first().did `should equal` "ffffffffffff"
                        it.first().time `should equal` "2019-03-30T07:00:00.000Z"

                        server.takeRequest().run {
                            path `should equal` "/waterflow/measurement/icd/ffffffff-ffff-4fff-8fff-ffffffffffff/this_week"
                        }
                    })
        }

        it("should response away-mode 2.0.0 in firmware features mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody("{\"features\":[{\"name\": \"away-mode\", \"version\": \"2.0.0\"}]}"))
            flo.firmwareFeatures(FAKE_TOKEN, "3.5.1")
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        assertThat(it.features).isNotNull()
                        assertThat(it.features).isNotEmpty()
                        it.features?.firstOrNull()?.apply {
                            name `should equal` "away-mode"
                            version `should equal` "2.0.0"
                        }

                        server.takeRequest().apply {
                            path `should equal` "/firmware/features/3.5.1"
                        }
                    })
        }

        it("should response firmware features mocked") {
            server.enqueue(MockResponse().setResponseCode(200).setBody("{\"features\":[]}"))
            flo.firmwareFeatures(FAKE_TOKEN, "3.1.5")
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        assertThat(it.features).isNotNull()
                        assertThat(it.features).isEmpty()

                        server.takeRequest().apply {
                            path `should equal` "/firmware/features/3.1.5"
                        }
                    })
        }

        it("should logout with mobile_device_id") {
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))
            flo.logout2(FAKE_TOKEN, "mobile_device_id")
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest().apply {
                            path `should equal` "/logout/"
                            assertThat(body.toString()).contains("mobile_device_id")
                        }
                    })
        }

        it("should logout with aws_endpoint_id") {
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))
            flo.logout2(FAKE_TOKEN, "mobile_device_id", "aws_endpoint_id")
                    .doOnError { server.takeRequest() }
                    .test()
                    .assertValue(assert {
                        server.takeRequest().apply {
                            path `should equal` "/logout/"
                            assertThat(body.toString()).contains("aws_endpoint_id")
                        }
                    })
        }

        it("should enable away-mode without irrigation mocked") {
            val fakeDevice = FloDevice(deviceId = "fff", data = FAKE_UUID, paired = true)

            server.enqueue(MockResponse().setResponseCode(200).setBody(Json.stringify(FloDevice.serializer(), fakeDevice)))
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))

            flo.away(FAKE_TOKEN)
                    .doOnError {
                        server.takeRequest()
                        server.takeRequest()
                        server.takeRequest()
                    }
                    .test()
                    .assertValue(assert {
                        server.takeRequest().run {
                            path `should equal` "/icds/me"
                        }
                        server.takeRequest().run {
                            path `should equal` "/awaymode/icd/${FAKE_UUID}/enable"
                        }
                        server.takeRequest().run {
                            path `should equal` "/mqtt/client/setsystemmode/fff"
                            Json.nonstrict.parse(SystemMode.serializer(), body.readUtf8()) `should equal` AWAY_MODE
                        }
                    })
        }

        it("should enable away-mode with irrigation mocked") {
            val fakeDevice = FloDevice(deviceId = "fff", data = FAKE_UUID, paired = true)

            server.enqueue(MockResponse().setResponseCode(200).setBody(Json.stringify(FloDevice.serializer(), fakeDevice)))
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))

            val durations = Durations(listOf(arrayOf("00:00:00", "00:00:11")))
            flo.away(FAKE_TOKEN, durations)
                    .doOnError {
                        server.takeRequest()
                        server.takeRequest()
                        server.takeRequest()
                    }
                    .test()
                    .assertValue(assert {
                        server.takeRequest().run {
                            path `should equal` "/icds/me"
                        }
                        server.takeRequest().run {
                            path `should equal` "/awaymode/icd/${FAKE_UUID}/enable"
                            Json.nonstrict.parse(Durations.serializer(), body.readUtf8()).times.first() `should equal` durations.times.first()
                        }
                        server.takeRequest().run {
                            path `should equal` "/mqtt/client/setsystemmode/fff"
                            Json.nonstrict.parse(SystemMode.serializer(), body.readUtf8()) `should equal` AWAY_MODE
                        }
                    })
        }

        it("should request sleep mode mocked") {
            val fakeDevice = FloDevice(deviceId = "fff", data = FAKE_UUID, paired = true)

            server.enqueue(MockResponse().setResponseCode(200).setBody(Json.stringify(FloDevice.serializer(), fakeDevice)))
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))

            val sleepMode = SleepMode(MODE_HOME, 30)
            flo.sleep(FAKE_TOKEN, sleepMode)
                    .doOnError {
                        server.takeRequest()
                        server.takeRequest()
                    }
                    .test()
                    .assertValue(assert {
                        server.takeRequest().run {
                            path `should equal` "/icds/me"
                        }
                        server.takeRequest().run {
                            path `should equal` "/mqtt/client/sleep/fff"

                            Json.nonstrict.parse(SleepMode.serializer(), body.readUtf8()) `should equal` sleepMode
                        }
                    })
        }
        it("should request home mode mocked") {
            val fakeDevice = FloDevice(deviceId = "fff", data = FAKE_UUID, paired = true)

            server.enqueue(MockResponse().setResponseCode(200).setBody(Json.stringify(FloDevice.serializer(), fakeDevice)))
            server.enqueue(MockResponse().setResponseCode(200).setBody("{}"))

            flo.home(FAKE_TOKEN)
                    .doOnError {
                        server.takeRequest()
                        server.takeRequest()
                    }
                    .test()
                    .assertValue(assert {
                        server.takeRequest().run {
                            path `should equal` "/icds/me"
                        }
                        server.takeRequest().run {
                            path `should equal` "/mqtt/client/setsystemmode/fff"
                            Json.nonstrict.parse(SystemMode.serializer(), body.readUtf8()) `should equal` HOME_MODE
                        }
                    })
        }
    }
})


fun <T> assert(consumer: (T) -> Unit): (T) -> Boolean {
    return {
        consumer.invoke(it)
        true
    }
}
