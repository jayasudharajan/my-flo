package com.flotechnologies.callbacks;

import com.flotechnologies.service.KafkaForwardingService;
import com.flotechnologies.service.MqttClientDataStore;
import com.flotechnologies.model.MqttClientData;
import com.google.common.base.Charsets;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.callback.CallbackPriority;
import com.hivemq.spi.callback.events.OnPublishReceivedCallback;
import com.hivemq.spi.callback.exception.OnPublishReceivedException;
import com.hivemq.spi.message.PUBLISH;
import com.hivemq.spi.security.ClientData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;

/**
 * This class implements the {@link OnPublishReceivedCallback}, which is triggered every time
 * a new message is published to the broker. This callback enables a custom handling of a
 * MQTT message, for acme saving to a database.
 */
public class PublishReceived implements OnPublishReceivedCallback {

    @NotNull
    private final Logger log = LoggerFactory.getLogger(PublishReceived.class);

    @NotNull
    private final KafkaForwardingService kafkaForwardingService;
    @NotNull
    private final MqttClientDataStore mqttClientDataStore;

    @Inject
    public PublishReceived(@NotNull final KafkaForwardingService kafkaForwardingService,
                           @NotNull final MqttClientDataStore mqttClientDataStore) {
        this.kafkaForwardingService = kafkaForwardingService;
        this.mqttClientDataStore = mqttClientDataStore;
    }

    /**
     * This method is called from the HiveMQ, when a new MQTT {@link PUBLISH} message arrives
     * at the broker. In this acme the method is just logging each message to the console.
     *
     * @param publish    The publish message send by the client.
     * @param clientData Useful information about the clients authentication state and credentials.
     * @throws OnPublishReceivedException When the exception is thrown, the publish is not accepted
     * and will NOT be delivered to the subscribing clients.
     */
    @Override
    public void onPublishReceived(@NotNull final PUBLISH publish,
                                  @NotNull final ClientData clientData)
            throws OnPublishReceivedException {

        try {
            final MqttClientData mqttClientData = mqttClientDataStore.get(clientData);

            if (mqttClientData.getClientType() == MqttClientData.ClientType.ICD) {
                final String message = new String(publish.getPayload(), Charsets.UTF_8);
                if (message.trim().isEmpty()) return;
                final String deviceId = mqttClientData.getClientName();
                if (deviceId == null || deviceId.trim().isEmpty()) return;
                final String topic = publish.getTopic();
                if (topic == null || topic.trim().isEmpty()) return;
                kafkaForwardingService.forwardMessage(deviceId, topic, message);
            }
        } catch (Exception e) {
            log.error(e.getMessage());
        }
    }


    /**
     * The priority is used when more than one OnConnectCallback is implemented to determine
     * the order.
     * If there is only one callback, which implements a certain interface, the priority
     * has no effect.
     *
     * @return callback priority
     */
    @Override
    public int priority() {
        return CallbackPriority.HIGH;
    }
}
