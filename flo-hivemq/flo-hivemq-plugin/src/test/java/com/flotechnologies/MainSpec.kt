package com.flotechnologies

import com.flotechnologies.callbacks.FloOnAuthenticationCallback
import com.flotechnologies.kafka.KafkaPublisher
import com.flotechnologies.service.AuthorizationService
import com.flotechnologies.service.GroupService
import com.flotechnologies.service.KafkaForwardingService
import com.flotechnologies.service.MqttClientDataStore
import com.flotechnologies.util.FloClient
import com.flotechnologies.model.MqttClientData
import com.github.aurae.retrofit2.LoganSquareConverterFactory
import com.google.common.base.Optional
import com.google.gson.JsonSyntaxException
import com.hivemq.spi.callback.exception.AuthenticationException
import com.hivemq.spi.security.ClientCredentialsData
import com.hivemq.spi.security.SslClientCertificate
import com.hivemq.spi.services.PluginExecutorService
import com.hivemq.spi.services.configuration.entity.Listener
import com.hivemq.spi.topic.MqttTopicPermission
import com.jakewharton.retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import com.nhaarman.mockito_kotlin.whenever
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.jetbrains.spek.api.Spek
import org.jetbrains.spek.api.dsl.describe
import org.jetbrains.spek.api.dsl.it
import org.junit.platform.runner.JUnitPlatform
import org.junit.runner.RunWith
import org.mockito.Mockito.anyString
import org.mockito.Mockito.mock
import retrofit2.Retrofit
import java.util.*


@RunWith(JUnitPlatform::class)
class MainSpec : Spek({
    val floClient = mock(FloClient::class.java)
    val mqttClientDataStore = MqttClientDataStore()
    whenever(floClient.flo).thenReturn(null)
    val auth = AuthorizationService(floClient, mock(PluginExecutorService::class.java), mqttClientDataStore)

    describe("With testing port") {
        val clientData = mock(ClientCredentialsData::class.java)
        val cert = mock(SslClientCertificate::class.java)
        val certOpt: Optional<SslClientCertificate> = Optional.of(cert)
        whenever(cert.commonName()).thenReturn("1|2|3")
        whenever(clientData.getCertificate()).thenReturn(certOpt)
        val listener = mock(Listener::class.java)
        val listenerOpt: Optional<Listener> = Optional.of(listener)
        whenever(listener.getPort()).thenReturn(1883)
        whenever(clientData.getListener()).thenReturn(listenerOpt)
        whenever(clientData.getPassword()).thenReturn(Optional.absent())
        whenever(clientData.getPasswordBytes()).thenReturn(Optional.absent())
        it("should be testing of client type") {
            val mqttData = MqttClientData.create(clientData)
            whenever(clientData.getUsername()).thenReturn(Optional.of("faketoken"))
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.TESTING)
            assertThat(auth.getPermissions(clientData)).isEmpty()
        }
        it("should unknown client name with invalid common name") {
            val mqttData = MqttClientData.create(clientData)
            whenever(cert.commonName()).thenReturn("")
            assertThat(mqttData.getClientName()).isEqualTo(null)
        }

        it("should be true of checkCredentials") {
            val authenticationCallback = FloOnAuthenticationCallback(mqttClientDataStore)
            assertThat(authenticationCallback.checkCredentials(clientData)).isTrue()
        }
    }

    describe("With APP port") {
        val clientData = mock(ClientCredentialsData::class.java)
        val cert = mock(SslClientCertificate::class.java)
        val certOpt: Optional<SslClientCertificate> = Optional.of(cert)
        whenever(cert.commonName()).thenReturn("1|2|3")
        whenever(clientData.getCertificate()).thenReturn(certOpt)
        val listener = mock(Listener::class.java)
        val listenerOpt: Optional<Listener> = Optional.of(listener)
        whenever(listener.getPort()).thenReturn(8000)
        whenever(clientData.getListener()).thenReturn(listenerOpt)
        whenever(clientData.getPassword()).thenReturn(Optional.absent())
        whenever(clientData.getPasswordBytes()).thenReturn(Optional.absent())
        it("should be app of client type") {
            val mqttData = MqttClientData.create(clientData)
            whenever(clientData.getUsername()).thenReturn(Optional.of("faketoken"))
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.APP)
        }

        it("should be app perms") {
            whenever(clientData.getUsername()).thenReturn(Optional.of("faketoken"))
            assertThat(auth.getPermissions(clientData)).isEqualTo(auth.getAppPermissionsTesting())
        }

        it("should be true of checkCredentials") {
            val authenticationCallback = FloOnAuthenticationCallback(mqttClientDataStore)
            assertThat(authenticationCallback.checkCredentials(clientData)).isTrue()
        }
    }

    describe("Have no certificate") {
        val clientData = mock(ClientCredentialsData::class.java)
        val certOpt: Optional<SslClientCertificate> = Optional.absent()
        whenever(clientData.getCertificate()).thenReturn(certOpt)
        val listener = mock(Listener::class.java)
        val listenerOpt: Optional<Listener> = Optional.of(listener)
        whenever(clientData.getListener()).thenReturn(listenerOpt)
        whenever(clientData.getPassword()).thenReturn(Optional.absent())
        whenever(clientData.getPasswordBytes()).thenReturn(Optional.absent())
        it("should be app of client type") {
            whenever(listener.getPort()).thenReturn(8000)
            val mqttData = MqttClientData.create(clientData)
            whenever(clientData.getUsername()).thenReturn(Optional.of("faketoken"))
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.APP)
        }
        it("should be empty app perms if also have no client username") {
            whenever(listener.getPort()).thenReturn(8000)
            whenever(clientData.getUsername()).thenReturn(Optional.absent())
            assertThat(auth.getPermissions(clientData)).isEmpty()
        }
        it("should be user of client type") {
            whenever(listener.getPort()).thenReturn(8001)
            val mqttData = MqttClientData.create(clientData)
            whenever(clientData.getUsername()).thenReturn(Optional.of("faketoken"))
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.USER)
        }
        it("should be empty user perms if also have no client username") {
            whenever(listener.getPort()).thenReturn(8001)
            whenever(clientData.getUsername()).thenReturn(Optional.absent())
            assertThat(auth.getPermissions(clientData)).isEmpty()
        }

        it("should throw AuthenticationException without username/token, 8000") {
            whenever(listener.getPort()).thenReturn(8000)
            whenever(clientData.getUsername()).thenReturn(Optional.absent())
            mqttClientDataStore.get(clientData)
            val authenticationCallback = FloOnAuthenticationCallback(mqttClientDataStore)
            assertThatThrownBy({
                authenticationCallback.checkCredentials(clientData)
            }).isInstanceOf(AuthenticationException::class.java)
        }
    }

    describe("KafkaForwardingService") {
        val kafkaPublisher = mock(KafkaPublisher::class.java)
        val kafkaForwardingService = KafkaForwardingService(kafkaPublisher, mock(PluginExecutorService::class.java))
        it("should has did property") {
            assertThat(kafkaForwardingService.ensureDeviceIdTesting("yo",
                    "yo",
                    "telemetry-v3",
                    "{}")).contains("did")
        }
        it("should throw exception if topic not found") {
            assertThatThrownBy({ kafkaForwardingService.ensureDeviceIdTesting("yo",
                    "yo",
                    "yo",
                    "{}")
            }).isInstanceOf(Exception::class.java)
        }
        it("should throw JsonSyntaxException if message is invalid json") {
            assertThatThrownBy({ kafkaForwardingService.ensureDeviceIdTesting("yo",
                    "yo",
                    "telemetry-v3",
                    "{")
            }).isInstanceOf(JsonSyntaxException::class.java)
        }
        it("should not throw with invalid topic") {
            whenever(kafkaPublisher.publish(anyString(), anyString(), anyString())).thenReturn(io.reactivex.Maybe.empty())
            kafkaForwardingService.forwardMessage("yo", "yo", "{}")
        }
        it("should not throw with valid topic") {
            whenever(kafkaPublisher.publish(anyString(), anyString(), anyString())).thenReturn(io.reactivex.Maybe.empty())
            kafkaForwardingService.forwardMessage("yo", "home/device/123456789012/v1/telemetry", "{}")
        }
        it("should not throw with invalid topic") {
            whenever(kafkaPublisher.publish(anyString(), anyString(), anyString())).thenReturn(io.reactivex.Maybe.error(Exception()))
            assertThatThrownBy({
                kafkaForwardingService.forwardMessage("yo", "yo", "{}")
            }).isInstanceOf(Exception::class.java)
        }
    }

    describe("8883 port without certificate") {
        val clientData = mock(ClientCredentialsData::class.java)
        val certOpt: Optional<SslClientCertificate> = Optional.absent()
        val listener = mock(Listener::class.java)
        val listenerOpt: Optional<Listener> = Optional.of(listener)
        whenever(clientData.getCertificate()).thenReturn(certOpt)
        whenever(listener.getPort()).thenReturn(8883)
        whenever(clientData.getListener()).thenReturn(listenerOpt)
        whenever(clientData.getPassword()).thenReturn(Optional.absent())
        whenever(clientData.getPasswordBytes()).thenReturn(Optional.absent())
        it("should be null client type") {
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isEqualTo(null)
        }
        it("should unknown client name without cert") {
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientName()).isEqualTo(null)
        }
        it("should throw AuthenticationException without cert") {
            val authenticationCallback = FloOnAuthenticationCallback(mqttClientDataStore)
            assertThatThrownBy({
                authenticationCallback.checkCredentials(clientData)
            }).isInstanceOf(AuthenticationException::class.java)
        }
    }

    describe("unknown 8885 port for example") {
        val clientData = mock(ClientCredentialsData::class.java)
        val certOpt: Optional<SslClientCertificate> = Optional.absent()
        val listener = mock(Listener::class.java)
        val listenerOpt: Optional<Listener> = Optional.of(listener)
        whenever(listener.getPort()).thenReturn(8885)
        whenever(clientData.getListener()).thenReturn(listenerOpt)
        whenever(clientData.getPassword()).thenReturn(Optional.absent())
        whenever(clientData.getPasswordBytes()).thenReturn(Optional.absent())
        it("should be also null client type") {
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isEqualTo(null)
        }

        it("should throw AuthenticationException with unknown clientType with unknown port ") {
            val authenticationCallback = FloOnAuthenticationCallback(mqttClientDataStore)
            assertThatThrownBy({
                authenticationCallback.checkCredentials(clientData)
            }).isInstanceOf(AuthenticationException::class.java)
        }
    }

    describe("Have icd certificate") {
        val clientData = mock(ClientCredentialsData::class.java)
        val cert = mock(SslClientCertificate::class.java)
        val certOpt: Optional<SslClientCertificate> = Optional.of(cert)
        whenever(clientData.getCertificate()).thenReturn(certOpt)
        val listener = mock(Listener::class.java)
        val listenerOpt: Optional<Listener> = Optional.of(listener)
        whenever(listener.getPort()).thenReturn(8883)
        whenever(clientData.getListener()).thenReturn(listenerOpt)
        whenever(clientData.getPassword()).thenReturn(Optional.absent())
        whenever(clientData.getPasswordBytes()).thenReturn(Optional.absent())
        it("should be icd of client type with icd cert") {
            whenever(cert.commonName()).thenReturn("1|icd|3")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.ICD)
        }
        it("should be icd of client type with gen1 cert") {
            whenever(cert.commonName()).thenReturn("1|gen1|3")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.ICD)
        }
        it("should be icd of client type with gen2 cert") {
            whenever(cert.commonName()).thenReturn("1|gen2|3")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.ICD)
        }
        it("should be icd of client type with app cert") {
            whenever(cert.commonName()).thenReturn("1|app|3")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.APP)
        }
        it("should be icd of client type with app|flo-app-api cert") {
            whenever(cert.commonName()).thenReturn("v1|app|flo-app-api")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.APP)
        }
        it("should be icd of client type with uppercase APP|FLO-APP-API cert") {
            whenever(cert.commonName()).thenReturn("V1|APP|FLO-APP-API")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isEqualTo(MqttClientData.ClientType.APP)
        }
        it("should be app client type with unknown client name of cert") {
            whenever(cert.commonName()).thenReturn("1|gen3|3")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isNull()
        }
        it("should be app client type with unknown2 client name of cert") {
            whenever(cert.commonName()).thenReturn("1|na|3")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientType()).isNull()
        }
        it("should be empty perms with icd cert without deviceId") {
            whenever(cert.commonName()).thenReturn("1|icd|")
            whenever(clientData.getUsername()).thenReturn(Optional.absent())
            assertThat(auth.getPermissions(clientData)).isEmpty()
        }
        it("should be empty perms with gen1 cert without deviceId") {
            whenever(cert.commonName()).thenReturn("1|gen1|")
            whenever(clientData.getUsername()).thenReturn(Optional.absent())
            assertThat(auth.getPermissions(clientData)).isEmpty()
        }
        it("should be empty perms with gen2 cert without deviceId") {
            whenever(cert.commonName()).thenReturn("1|gen2|")
            whenever(clientData.getUsername()).thenReturn(Optional.absent())
            assertThat(auth.getPermissions(clientData)).isEmpty()
        }
        it("should be empty perms with invalid icd cert") {
            whenever(cert.commonName()).thenReturn("")
            whenever(clientData.getUsername()).thenReturn(Optional.absent())
            assertThat(auth.getPermissions(clientData)).isEmpty()
        }
        it("should be 1 on deviceId") {
            whenever(cert.commonName()).thenReturn("1|gen2|3")
            val mqttData = MqttClientData.create(clientData)
            assertThat(mqttData.getClientName()).isEqualTo("3")
        }
        it("should be icd perms with icd cert") {
            whenever(cert.commonName()).thenReturn("1|icd|3")
            assertThat(auth.getPermissions(clientData)).isEqualTo(auth.getICDPermissionsTesting("3"))
        }
        it("should be icd perms with icd cert") {
            whenever(cert.commonName()).thenReturn("1|gen1|3")
            assertThat(auth.getPermissions(clientData)).isEqualTo(auth.getICDPermissionsTesting("3"))
        }
        it("should be icd perms with icd cert") {
            whenever(cert.commonName()).thenReturn("1|gen2|3")
            assertThat(auth.getPermissions(clientData)).isEqualTo(auth.getICDPermissionsTesting("3"))
        }
        it("should be app perms with app cert") {
            whenever(cert.commonName()).thenReturn("1|app|3")
            assertThat(auth.getPermissions(clientData)).isEqualTo(auth.getAppPermissionsTesting())
        }
        it("should be app perms with app|flo-app-api cert") {
            whenever(cert.commonName()).thenReturn("v1|app|flo-app-api")
            assertThat(auth.getPermissions(clientData)).isEqualTo(auth.getAppPermissionsTesting())
        }
    }

    describe("GroupTopic") {
        val mockFloClient = mock(FloClient::class.java)
        val mockFlo = mock(Flo::class.java)
        whenever(mockFloClient.flo).thenReturn(mockFlo)
        val groupService = GroupService(mockFloClient, mock(PluginExecutorService::class.java))
        it("should be null with invalid group id") {
            assertThat(groupService.parseGroupTopic("home/group/1345678-1234-4321-9876-123456789012/device/123456789012/v1/telemetry")).isNull()
            assertThat(groupService.parseGroupTopic("home/group/1345678123443219876123456789012/device/123456789012/v1/telemetry")).isNull()
        }
        it("should be null with invalid device id") {
            assertThat(groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/12345678901/v1/telemetry")).isNull()
            assertThat(groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/ /v1/telemetry")).isNull()
        }
        it("should be null with invalid subtopic") {
            assertThat(groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1")).isNull()
            assertThat(groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/telemetr")).isNull()
        }
        it("should be null with invalid prefix") {
            assertThat(groupService.parseGroupTopic("12345678-1234-4321-9876-123456789012/device/123456789012/v1/telemetry")).isNull()
            assertThat(groupService.parseGroupTopic("home/ /12345678-1234-4321-9876-123456789012/device/123456789012/v1/telemetr")).isNull()
        }
        it("should be telemetry") {
            val group = groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/telemetry")
            assertThat(group).isNotNull()
            assertThat(group.groupId()).isEqualTo("12345678-1234-4321-9876-123456789012")
            assertThat(group.deviceId()).isEqualTo("123456789012")
            assertThat(group.forwardedTopic()).isEqualTo("home/device/123456789012/v1/telemetry")
        }
        it("should be will") {
            val group = groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/will")
            assertThat(group).isNotNull()
            assertThat(group.groupId()).isEqualTo("12345678-1234-4321-9876-123456789012")
            assertThat(group.deviceId()).isEqualTo("123456789012")
            assertThat(group.forwardedTopic()).isEqualTo("home/device/123456789012/v1/will")
        }
        it("should be vrzit") {
            val group = groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/vrzit")
            assertThat(group).isNotNull()
            assertThat(group.groupId()).isEqualTo("12345678-1234-4321-9876-123456789012")
            assertThat(group.deviceId()).isEqualTo("123456789012")
            assertThat(group.forwardedTopic()).isEqualTo("home/device/123456789012/v1/vrzit")
        }
        it("should be mvrzit") {
            val group = groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit")
            assertThat(group).isNotNull()
            assertThat(group.groupId()).isEqualTo("12345678-1234-4321-9876-123456789012")
            assertThat(group.deviceId()).isEqualTo("123456789012")
            assertThat(group.forwardedTopic()).isEqualTo("home/device/123456789012/v1/mvrzit")
        }
        it("should be directives-response") {
            val group = groupService.parseGroupTopic("home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/directives-response")
            assertThat(group).isNotNull()
            assertThat(group.groupId()).isEqualTo("12345678-1234-4321-9876-123456789012")
            assertThat(group.deviceId()).isEqualTo("123456789012")
            assertThat(group.forwardedTopic()).isEqualTo("home/device/123456789012/v1/directives-response")
        }
        //it("benchmark") {
        //    val DEVICE_ID_REGEX_V1 = "([a-fA-F0-9]{12})";
        //    // 12345678-1234-4321-9876-123456789012
        //    // 12345678-1234-4123-9123-123456789012
        //    // UUID
        //    val GROUP_ID_REGEX_V1 =
        //       "([0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12})";
        //    // home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1
        //    val GROUP_TOPIC_REGEX_V1 =
        //       "(^)home/group/" + GROUP_ID_REGEX_V1 + "/device/" + DEVICE_ID_REGEX_V1 + "/v1";
        //    // home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/telemetry
        //    val GROUP_TELEMETRY_REGEX_V1 =
        //       GROUP_TOPIC_REGEX_V1 + "/telemetry($)";
        //    // home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/will
        //    val GROUP_WILL_REGEX_V1 = GROUP_TOPIC_REGEX_V1 + "/will($)";
        //    // home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/vrzit
        //    val GROUP_AUTO_ZIT_RESULT_REGEX_V1 =
        //       GROUP_TOPIC_REGEX_V1 + "/test-result/vrzit($)";
        //    // home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit
        //    val GROUP_MANUAL_ZIT_RESULT_REGEX_V1 =
        //       GROUP_TOPIC_REGEX_V1 + "/test-result/mvrzit($)";
        //    // home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/directives-response
        //    val GROUP_DIRECTIVES_RESPONSE_REGEX_V1 =
        //       GROUP_TOPIC_REGEX_V1 + "/directives-response($)";
        //    val map : HashMap<Pattern, String> = HashMap()
        //    map.put(Pattern.compile(GROUP_TELEMETRY_REGEX_V1, Pattern.CASE_INSENSITIVE), "telemetry")
        //    map.put(Pattern.compile(GROUP_WILL_REGEX_V1, Pattern.CASE_INSENSITIVE), "will")
        //    map.put(Pattern.compile(GROUP_AUTO_ZIT_RESULT_REGEX_V1, Pattern.CASE_INSENSITIVE), "vrzit")
        //    map.put(Pattern.compile(GROUP_MANUAL_ZIT_RESULT_REGEX_V1, Pattern.CASE_INSENSITIVE), "mvrzit")
        //    map.put(Pattern.compile(GROUP_DIRECTIVES_RESPONSE_REGEX_V1, Pattern.CASE_INSENSITIVE), "directives-response")

        //    val topics = arrayOf(
        //            "",
        //            "home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit/home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit",
        //            "home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/telemetry",
        //            "home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/will",
        //            "home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/vrzit",
        //            "home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/test-result/mvrzit",
        //            "home/group/12345678-1234-4321-9876-123456789012/device/123456789012/v1/directives-response"
        //    )

        //    println(LocalDateTime.now())
        //    for (i in 1..100000) {
        //        for (topic in topics) {
        //            groupService.parseGroupTopic(topic)
        //        }
        //    }
        //    println(LocalDateTime.now())
        //    val pathMatcher = PathMatcher()
        //    pathMatcher.add("home/group/:group_id<([0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12})>/device/<([a-fA-F0-9]{12})>/v1/telemetry")
        //    pathMatcher.add("home/group/:group_id<([0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12})>/device/<([a-fA-F0-9]{12})>/v1/will")
        //    pathMatcher.add("home/group/:group_id<([0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12})>/device/<([a-fA-F0-9]{12})>/v1/test-result/vrzit")
        //    pathMatcher.add("home/group/:group_id<([0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12})>/device/<([a-fA-F0-9]{12})>/v1/test-result/mvrzit")
        //    pathMatcher.add("home/group/:group_id<([0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12})>/device/<([a-fA-F0-9]{12})>/v1/directives-response")
        //    println(LocalDateTime.now())
        //    for (i in 1..100000) {
        //        for (topic in topics) {
        //            if (pathMatcher.matches(topic)) {
        //                ParsedGroupTopic.create("", "", "")
        //            }
        //        }
        //    }
        //    println(LocalDateTime.now())
        //    println(LocalDateTime.now())
        //    for (i in 1..100000) {
        //        for (key in map.keys) {
        //            for (topic in topics) {
        //                val matcher = key.matcher(topic)
        //                if (matcher.matches()) {
        //                    ParsedGroupTopic.create("", "", "")
        //                }
        //            }
        //        }
        //    }
        //    println(LocalDateTime.now())
        //}

        it("should be false with empty groupId or deviceId") {
            assertThat(groupService.isDeviceInGroup("yo", "", "")).isFalse()
        }
        it("should be false with empty groupId") {
            assertThat(groupService.isDeviceInGroup("yo", "yo", "")).isFalse()
        }
        it("should be false with empty deviceId") {
            assertThat(groupService.isDeviceInGroup("yo", "", "yo")).isFalse()
        }
        // FIXME: Implement Blocking Scheduler
        //val uuid = UUID.randomUUID().toString()
        //whenever(mockFlo.groupOfDevice(ArgumentMatchers.anyString(), ArgumentMatchers.anyString())).thenReturn(io.reactivex.Observable.just("$uuid"))
        //it("should be true with groupService.isDeviceInGroup()") {
        //    assertThat(groupService.isDeviceInGroup("yo", uuid, uuid)).isTrue()
        //}
        //it("should be false with groupService.isDeviceInGroup()") {
        //    assertThat(groupService.isDeviceInGroup("a", "b", "c")).isFalse()
        //}
    }

    describe("AuthorizationService") {
        it("should be correct permissions with app") {
            assertThat(auth.appPermissionsTesting.size)
                    .isEqualTo(auth.appSubTopicsTesting.size + auth.appPubTopicsTesting.size)
        }
        it("should be correct permissions with icd") {
            assertThat(auth.getICDPermissionsTesting("123456789012").size)
                    .isEqualTo(auth.icdSubTopicsTesting.size + auth.icdPubTopicsTesting.size)
        }
    }
    describe("KafkaForwarding") {
        val kafka = KafkaForwardingService(mock(KafkaPublisher::class.java), mock(PluginExecutorService::class.java))
        it("should be invalid topic") {
            assertThat(kafka.getKafkaTopic("/device/123456789012/v1/telemetry")).isNull()
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1/telemetr")).isNull()
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1")).isNull()
            assertThat(kafka.getKafkaTopic("home/device/12345678901/v1/telemetry")).isNull()
            assertThat(kafka.getKafkaTopic("home/device//v1/telemetry")).isNull()
            assertThat(kafka.getKafkaTopic("home/device/ /v1/telemetry")).isNull()
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1/telemetry/home/device/123456789012/v1/telemetry")).isNull()
            assertThat(kafka.getKafkaTopic("123456789012/v1/telemetry/home/device/")).isNull()
            assertThat(kafka.getKafkaTopic("/123456789012/v1/telemetry/home/device")).isNull()
        }
        it("should be corresponding topic") {
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1/telemetry")).isEqualTo("telemetry-v3")
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1/notifications")).isEqualTo("notifications-v2")
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1/test-result/vrzit")).isEqualTo("zit-v2")
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1/test-result/mvrzit")).isEqualTo("zit-v2")
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1/alarm-notification-status")).isEqualTo("alarm-notification-status-v2")
            assertThat(kafka.getKafkaTopic("home/device/123456789012/v1/external-actions/valve-status")).isEqualTo("external-actions-valve-status-v2")
        }
    }

    describe("MqttClientData.EMPTY") {
        it("should throw UnsupportedOperationException") {
            //assertThatThrownBy({ MqttClientData.create(MqttClientData.EMPTY) })
            //        .isInstanceOf(UnsupportedOperationException::class.java)
        }
    }

    /**
     * Move those test cases to flo-sdk
     */
    val server = MockWebServer()
    server.start()
    val token = "faketoken"
    val flo = Retrofit.Builder()
            .client(OkHttpClient.Builder().build())
            .addCallAdapterFactory(RxJava2CallAdapterFactory.create())
            .addConverterFactory(LoganSquareConverterFactory.create())
            .baseUrl(server.url("/").toString())
            .build().create(Flo::class.java)

    describe("AuthorizationService with Flo Client") {
        val mockFloClient = mock(FloClient::class.java)
        whenever(mockFloClient.flo).thenReturn(flo)
        val service = AuthorizationService(mockFloClient, mock(PluginExecutorService::class.java), mqttClientDataStore)
        it("should be user permissions") {
            server.enqueue(MockResponse()
                    .setResponseCode(200)
                    .setBody(javaClass.classLoader.getResourceAsStream("mqtt-permissions.json")!!
                            .reader().readText()))
            val it = service.getUserPermissionsTesting(token)
            assertThat(it.size).isEqualTo(3)
            assertThat(it[0].activity).isEqualTo(MqttTopicPermission.ACTIVITY.PUBLISH)
            assertThat(it[1].activity).isEqualTo(MqttTopicPermission.ACTIVITY.SUBSCRIBE)
            assertThat(it[2].activity).isEqualTo(MqttTopicPermission.ACTIVITY.ALL)
            assertThat(it[0].topic).isEqualTo("8cc7aa0277c0")
            assertThat(it[1].topic).isEqualTo("8cc7aa0277c1")
            assertThat(it[2].topic).isEqualTo("8cc7aa0277c2")
        }
        /* TODO
        it("should be user perms") {
            server.enqueue(MockResponse()
                    .setResponseCode(200)
                    .setBody(javaClass.classLoader.getResourceAsStream("mqtt-permissions.json")!!
                            .reader().readText()))
            val clientData = mock(ClientCredentialsData::class.java)
            val cert = mock(SslClientCertificate::class.java)
            val certOpt: Optional<SslClientCertificate> = Optional.absent()
            whenever(clientData.getCertificate()).thenReturn(certOpt)
            whenever(clientData.getUsername()).thenReturn(Optional.of("mockUserName"))
            val perms = arrayOf()
            assertThat(auth.getPermissions(clientData)).isEqualTo(perms)
        }
        */
    }

    describe("Flo Client") {
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
                        assertThat(it[2].activity).isEqualTo("")
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
            val deviceId = "123456789012"
            flo.groupOfDevice(token, deviceId)
                    .singleElement().test()
                    .assertValue(assert { it ->
                        assertThat(it).isEqualTo(uuid)
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
