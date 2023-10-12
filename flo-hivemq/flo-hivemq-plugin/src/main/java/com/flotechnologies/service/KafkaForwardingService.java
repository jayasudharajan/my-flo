package com.flotechnologies.service;

import com.flotechnologies.annotations.NonBlank;
import com.flotechnologies.kafka.KafkaPublisher;
import com.google.common.annotations.VisibleForTesting;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonSyntaxException;
import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.annotations.Nullable;
import com.hivemq.spi.services.PluginExecutorService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;

import routs.LruCache;
import routs.PathMatcher;

@Singleton
public class KafkaForwardingService {
    @NotNull
    private final Logger log = LoggerFactory.getLogger(KafkaForwardingService.class);
    @NotNull
    private final KafkaPublisher kafkaPublisher;
    @NotNull
    private final PathMatcher pathMatcher;
    @NotNull
    private final LruCache<String, String> cache;
    @NotNull
    private final PluginExecutorService executorService;

    @Inject
    public KafkaForwardingService(@NotNull final KafkaPublisher kafkaPublisher,
                                  @NotNull final PluginExecutorService executorService) {
        this.kafkaPublisher = kafkaPublisher;
        this.executorService = executorService;
        this.cache = new LruCache<>(1024);
        this.pathMatcher = new PathMatcher();
        pathMatcher.add("home/device/<([a-fA-F0-9]){12}>/v1/telemetry", "telemetry-v3");
        pathMatcher.add("home/device/<([a-fA-F0-9]){12}>/v1/notifications", "notifications-v2");
        pathMatcher.add("home/device/<([a-fA-F0-9]){12}>/v1/directives-response", "directives-response-v2");
        pathMatcher.add("home/device/<([a-fA-F0-9]){12}>/v1/test-result/vrzit", "zit-v2");
        pathMatcher.add("home/device/<([a-fA-F0-9]){12}>/v1/test-result/mvrzit", "zit-v2");
        pathMatcher.add("home/device/<([a-fA-F0-9]){12}>/v1/alarm-notification-status", "alarm-notification-status-v2");
        pathMatcher.add("home/device/<([a-fA-F0-9]){12}>/v1/external-actions/valve-status", "external-actions-valve-status-v2");
    }

    /**
     * @param deviceId Flo Device Id, DO NOT put empty
     * @param mqttTopic MQTT Topic, DO NOT put empty
     * @param mqttMessage MQTT Message, DO NOT put empty
     *
     * Ignore CheckReturnValue for now, we don't handle dispoition until timeout by KafkaProducer
     */
    @SuppressWarnings("CheckReturnValue")
    public void forwardMessage(@NonBlank @NotNull final String deviceId,
                               @NonBlank @NotNull final String mqttTopic,
                               @NonBlank @NotNull final String mqttMessage) {
        final String kafkaTopic = getKafkaTopic(mqttTopic);
        if (kafkaTopic == null) return;

        // using deviceId as a partition key
        kafkaPublisher.publish(
                kafkaTopic,
                deviceId,
                ensureDeviceId(deviceId, mqttTopic, kafkaTopic, mqttMessage))
                .subscribe(v -> {}, e -> {
                    log.error("forwardMessage", e);
                });
    }

    /**
     * Resolve kafka topic
     * @param mqttTopic mqtt topic, DO NOT put empty
     * @return kafka topic
     */
    @Nullable
    public String getKafkaTopicCached(@NonBlank @NotNull final String mqttTopic) {
        String cached = cache.get(mqttTopic);
        if (cached != null && cached.isEmpty()) return null;
        if (cached != null) return cached;

        cached = getKafkaTopicInner(mqttTopic);
        if (cached != null) {
            cache.put(mqttTopic, cached);
            return cached;
        }

        cached = "";
        cache.put(mqttTopic, cached);
        return null;
    }

    /**
     * Resolve kafka topic
     * @param mqttTopic mqtt topic, DO NOT put empty
     * @return kafka topic
     */
    @Nullable
    public String getKafkaTopic(@NonBlank @NotNull final String mqttTopic) {
        return getKafkaTopicCached(mqttTopic);
    }

    /**
     * Resolve kafka topic
     * @param mqttTopic mqtt topic, DO NOT put empty
     * @return kafka topic
     */
    @Nullable
    private String getKafkaTopicInner(@NonBlank @NotNull final String mqttTopic) {
        final PathMatcher.TrieNode node = pathMatcher.matchesNode(mqttTopic);
        if (node.end) return node.key;
        return null;
    }

    @NotNull
    @VisibleForTesting
    public String ensureDeviceIdTesting(@NonBlank @NotNull final String deviceId,
                                        @NonBlank @NotNull final String mqttTopic,
                                        @NonBlank @NotNull final String kafkaTopic,
                                        @NonBlank @NotNull final String message) {
        return ensureDeviceId(deviceId, mqttTopic, kafkaTopic, message);
    }

    /**
     * Ensures that any device IDs in the message payload match the device ID of
     * the ICD that published
     * the message.
     *
     * And we don't trust that deviceIDs from message payload
     *
     * @param deviceId Flo Device Id, DO NOT put empty
     * @param kafkaTopic Kafka Topic, DO NOT put empty
     * @param message kafka json message, DO NOT put empty
     * @return refined json
     * @throws IllegalArgumentException
     * @throws JsonSyntaxException
     */
    @NotNull
    private String ensureDeviceId(@NonBlank @NotNull final String deviceId,
                                  @NonBlank @NotNull final String mqttTopic,
                                  @NonBlank @NotNull final String kafkaTopic,
                                  @NonBlank @NotNull final String message)
            throws IllegalArgumentException {
        final JsonObject jsonObject = new JsonParser().parse(message).getAsJsonObject();
        jsonObject.addProperty("hts", new Date().getTime());

        switch (kafkaTopic) {
            case "telemetry-v3":
            case "notifications-v2":
            case "alarm-notification-status-v2":
            case "external-actions-valve-status-v2":
                jsonObject.addProperty("did", deviceId);
                break;
            case "directives-response-v2":
            case "zit-v2":
                jsonObject.addProperty("device_id", deviceId);
                break;
            default:
                throw new IllegalArgumentException("No sanitization defined for topic " + kafkaTopic);
        }

        return jsonObject.toString();
    }
}
