package com.flotechnologies.callbacks;

import com.flotechnologies.service.MqttClientDataStore;
import com.flotechnologies.model.MqttClientData;
import com.flotechnologies.util.Optionals;
import com.google.inject.Inject;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.callback.exception.AuthenticationException;
import com.hivemq.spi.callback.security.OnAuthenticationCallback;
import com.hivemq.spi.security.ClientCredentialsData;
import com.hivemq.spi.services.configuration.entity.Listener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static com.hivemq.spi.callback.CallbackPriority.HIGH;
import static com.hivemq.spi.message.ReturnCode.REFUSED_NOT_AUTHORIZED;

/**
 * See the workflow
 * https://www.hivemq.com/docs/plugins/latest/#hivemqdocs_client_authentication
 */
public class FloOnAuthenticationCallback implements OnAuthenticationCallback {

    @NotNull
    private final Logger log = LoggerFactory.getLogger(FloOnAuthenticationCallback.class);

    @NotNull
    private final MqttClientDataStore mqttClientDataStore;

    /**
     * @param mqttClientDataStore store
     */
    @Inject
    public FloOnAuthenticationCallback(@NotNull final MqttClientDataStore mqttClientDataStore) {
        this.mqttClientDataStore = mqttClientDataStore;
    }
    /**
     * config/opt/hivemq/conf/config.xml
     * 8000 - app        - token expected - no cert expected / websocket
     * 8001 - mobile     - token expected - no cert expected
     * 8883 - flo device - cert expected
     * 8884 - flo device - cert expected
     * 1883 - testing port
     *
     * NOTICE: Depend on config.xml for optimization
     */
    @Override
    public Boolean checkCredentials(ClientCredentialsData clientData) throws AuthenticationException {
        log.info("checkCredentials");
        int port = Optionals.toJavaUtil(clientData.getListener())
                .map(Listener::getPort)
                .orElseThrow(() -> new AuthenticationException("No port provided", REFUSED_NOT_AUTHORIZED));
        switch (port) {
            case 1883: {
                log.info("Testing");
                break;
            }
            case 8000:
            case 8001: {
                if (!clientData.getUsername().isPresent()) { // token
                    log.info("No username provided");
                    throw new AuthenticationException("No username provided", REFUSED_NOT_AUTHORIZED);
                }
                break;
            }
            case 8883:
            case 8884: {
                if (!clientData.getCertificate().isPresent()) {
                    log.info("No certificate provided");
                    throw new AuthenticationException("No certificate provided", REFUSED_NOT_AUTHORIZED);
                }
                break;
            }
        }

        final MqttClientData mqttClientData = mqttClientDataStore.get(clientData);
        final MqttClientData.ClientType clientType = mqttClientData.getClientType();
        if (clientType == null) {
            log.info("No certificate provided");
            throw new AuthenticationException("No certificate provided", REFUSED_NOT_AUTHORIZED);
        }
        return true;
    }

    @Override
    public int priority() {
        return HIGH;
    }
}
