package com.flotechnologies.callbacks;

import com.flotechnologies.service.DeviceStatusService;
import com.flotechnologies.service.MqttClientDataStore;
import com.flotechnologies.model.MqttClientData;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.base.Charsets;
import com.google.inject.Inject;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.annotations.Nullable;
import com.hivemq.spi.callback.CallbackPriority;
import com.hivemq.spi.callback.events.OnConnectCallback;
import com.hivemq.spi.callback.exception.RefusedConnectionException;
import com.hivemq.spi.message.CONNECT;
import com.hivemq.spi.security.ClientData;
import com.hivemq.spi.services.AsyncSessionAttributeStore;
import com.hivemq.spi.services.OptionalAttribute;
import com.hivemq.spi.services.PluginExecutorService;
import com.hivemq.spi.services.exception.NoSuchClientIdException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static com.hivemq.spi.message.ReturnCode.REFUSED_IDENTIFIER_REJECTED;

/**
 * Initialize retained message and report Flo device status
 * See the workflow
 * https://www.hivemq.com/docs/plugins/latest/#hivemqdocs_client_authentication
 */
public class ClientConnect implements OnConnectCallback {

    @NotNull
    private final Logger log = LoggerFactory.getLogger(ClientConnect.class);
    @NotNull
    private final DeviceStatusService deviceStatusService;
    @NotNull
    private final MqttClientDataStore mqttClientDataStore;
    @NotNull
    private final AsyncSessionAttributeStore asyncSessionAttributeStore;
    @NotNull
    private final PluginExecutorService pluginExecutorService;

    @Inject
    public ClientConnect(@NotNull final DeviceStatusService deviceStatusService,
                         @NotNull final MqttClientDataStore mqttClientDataStore,
                         @NotNull final AsyncSessionAttributeStore asyncSessionAttributeStore,
                         @NotNull final PluginExecutorService pluginExecutorService) {
        this.deviceStatusService = deviceStatusService;
        this.mqttClientDataStore = mqttClientDataStore;
        this.asyncSessionAttributeStore = asyncSessionAttributeStore;
        this.pluginExecutorService = pluginExecutorService;
    }

    /**
     * This is the callback method, which is called by the HiveMQ core, if a client has sent,
     * a {@link CONNECT} Message and was successfully authenticated. In this acme there is only
     * a logging statement, normally the behavior would be implemented in here.
     *
     * @param connect    The {@link CONNECT} message from the client.
     * @param clientData Useful information about the clients authentication state and credentials.
     * @throws RefusedConnectionException This exception should be thrown, if the client is
     *                                    not allowed to connect.
     */
    @Override
    public void onConnect(@NotNull final CONNECT connect,
                          @NotNull final ClientData clientData)
            throws RefusedConnectionException {
        final String STATUS = "status";
        final String ONLINE = "online";
        final String clientId = clientData.getClientId();
        log.debug("Client {} is connected", clientId);

        if (!clientData.getClientId().toLowerCase().startsWith("agent")) {
            final MqttClientData mqttClientData = mqttClientDataStore.get(clientData);
            if (mqttClientData.getClientType() == MqttClientData.ClientType.ICD) {
                final String deviceId = mqttClientData.getClientName();
                if (deviceId == null || deviceId.trim().isEmpty()) {
                    throw new RefusedConnectionException(REFUSED_IDENTIFIER_REJECTED);
                }

                // Following operations are async
                deviceStatusService.setWillTopicOnline(deviceId);
                final long connectTimestamp = System.currentTimeMillis();
                final ListenableFuture<OptionalAttribute> optionalAttributeListenableFuture = asyncSessionAttributeStore
                        .putIfNewer(clientData.getClientId(), STATUS, ONLINE.getBytes(Charsets.UTF_8), connectTimestamp);
                Futures.addCallback(optionalAttributeListenableFuture, new FutureCallback<OptionalAttribute>() {
                    @Override
                    public void onSuccess(@Nullable final OptionalAttribute result) {
                        if (result == null || result.isReplaced()) {
                            log.debug("Set client online in firebase (from onSuccess). Client Id: {}", clientId);
                            deviceStatusService.sendOnline(deviceId, connectTimestamp);
                        }
                    }

                    @Override
                    public void onFailure(final Throwable throwable) {
                        if (throwable instanceof NoSuchClientIdException) {
                            log.debug("Set client online in firebase (from onFailure). Client Id: {}", clientId);
                            deviceStatusService.sendOnline(deviceId, connectTimestamp);
                        }
                    }
                }, pluginExecutorService);
            }
        }
    }

    /**
     * The priority is used when more than one OnConnectCallback is implemented to determine
     * the order.
     * If there is only one callback, which implements a certain interface,
     * the priority has no effect.
     *
     * @return callback priority
     */
    @Override
    public int priority() {
        return CallbackPriority.HIGH;
    }
}

