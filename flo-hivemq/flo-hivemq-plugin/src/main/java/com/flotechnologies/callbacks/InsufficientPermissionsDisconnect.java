package com.flotechnologies.callbacks;

import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.callback.security.OnInsufficientPermissionDisconnect;
import com.hivemq.spi.message.QoS;
import com.hivemq.spi.security.ClientData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Nothing now
 */
public class InsufficientPermissionsDisconnect implements OnInsufficientPermissionDisconnect {

    @NotNull
    private final Logger log = LoggerFactory.getLogger(InsufficientPermissionsDisconnect.class);

    /**
     * @param clientData client data
     * @param topic topic
     * @param qoS qos
     */
    @Override
    public void onPublishDisconnect(ClientData clientData, String topic, QoS qoS) {
        log.info("Unauthorized publish to topic " + topic);
    }

    /**
     * @param clientData client data
     * @param topic topic
     * @param qoS qos
     */
    @Override
    public void onSubscribeDisconnect(ClientData clientData, String topic, QoS qoS) {
        log.info("Unauthorized subscribe to topic " + topic);
    }
}
