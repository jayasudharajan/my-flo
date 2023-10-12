package com.flotechnologies.callbacks;

import com.flotechnologies.service.DeviceStatusService;
import com.flotechnologies.service.MqttClientDataStore;
import com.flotechnologies.model.MqttClientData;
import com.google.common.base.Charsets;
import com.google.common.base.Optional;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.annotations.Nullable;
import com.hivemq.spi.callback.events.OnDisconnectCallback;
import com.hivemq.spi.security.ClientData;
import com.hivemq.spi.services.AsyncSessionAttributeStore;
import com.hivemq.spi.services.OptionalAttribute;
import com.hivemq.spi.services.PluginExecutorService;
import com.hivemq.spi.services.exception.NoSuchClientIdException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;

public class ClientDisconnect implements OnDisconnectCallback {

    @NotNull
    private final Logger log = LoggerFactory.getLogger(ClientDisconnect.class);

    @NotNull
    private final DeviceStatusService deviceStatusService;
    @NotNull
    private final MqttClientDataStore mqttClientDataStore;
    @NotNull
    private final AsyncSessionAttributeStore asyncSessionAttributeStore;
    @NotNull
    private final PluginExecutorService pluginExecutorService;

    /**
     * @param deviceStatusService deviceStatusService
     * @param mqttClientDataStore mqttClientDataStore
     * @param asyncSessionAttributeStore asyncSessionAttributeStore
     * @param pluginExecutorService pluginExecutorService
     */
    @Inject
    public ClientDisconnect(@NotNull final DeviceStatusService deviceStatusService,
                            @NotNull final MqttClientDataStore mqttClientDataStore,
                            @NotNull final AsyncSessionAttributeStore asyncSessionAttributeStore,
                            @NotNull final PluginExecutorService pluginExecutorService) {
        this.deviceStatusService = deviceStatusService;
        this.mqttClientDataStore = mqttClientDataStore;
        this.asyncSessionAttributeStore = asyncSessionAttributeStore;
        this.pluginExecutorService = pluginExecutorService;
    }


    /**
     * @param clientData client data
     * @param abruptAbort abort
     */
    @Override
    public void onDisconnect(@NotNull final ClientData clientData, boolean abruptAbort) {
        final String STATUS = "status";
        final String OFFLINE = "offline";
        final String clientId = clientData.getClientId();
        log.debug("Client {} is disconnected", clientId);

        if (!clientData.getClientId().toLowerCase().startsWith("agent")) {
            final MqttClientData mqttClientData = MqttClientData.create(clientData);
            if (mqttClientData.getClientType() == MqttClientData.ClientType.ICD) {
                final String deviceId = mqttClientData.getClientName();
                if (deviceId == null || deviceId.trim().isEmpty()) return;
                final Optional<Long> disconnectTimestamp = clientData.getDisconnectTimestamp();
                // TODO: disconnectTimestamp.toJavaUtil().flatMap(timestamp -> {})
                if (disconnectTimestamp.isPresent()) {
                    final ListenableFuture<OptionalAttribute> optionalAttributeListenableFuture = asyncSessionAttributeStore
                            .putIfNewer(clientData.getClientId(), STATUS, OFFLINE.getBytes(Charsets.UTF_8),
                                    disconnectTimestamp.get());
                    Futures.addCallback(optionalAttributeListenableFuture, new FutureCallback<OptionalAttribute>() {
                        @Override
                        public void onSuccess(@Nullable final OptionalAttribute result) {
                            if (result == null || result.isReplaced()) {
                                log.debug("Set client offline in firebase (from onSuccess). Client Id: {}", clientId);
                                deviceStatusService.sendOffline(deviceId, disconnectTimestamp.get());
                            }
                        }

                        @Override
                        public void onFailure(@NotNull final Throwable throwable) {
                            if (throwable instanceof NoSuchClientIdException) {
                                log.debug("Set client offline in firebase (from onFailure). Client Id: {}", clientId);
                                deviceStatusService.sendOffline(deviceId, disconnectTimestamp.get());
                            }
                        }
                    }, pluginExecutorService);
                }
            }
        }
    }
}
