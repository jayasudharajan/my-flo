package com.flotechnologies.service;

import com.flotechnologies.model.MqttClientData;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.security.ClientData;

import routs.LruCache;

@Singleton
public class MqttClientDataStore {
    @NotNull
    private final LruCache<String, MqttClientData> cache;
    @NotNull
    private final Object lock = new Object();

    public MqttClientDataStore() {
        this(1024);
    }

    public MqttClientDataStore(int maxSize) {
        this.cache = new LruCache<>(maxSize);
    }

    @NotNull
    public MqttClientData get(@NotNull final ClientData clientData) {
        return getCached(clientData);
    }

    /**
     * @param clientData client data
     * @return cached MqttClientData
     */
    @NotNull
    public MqttClientData getCached(@NotNull final ClientData clientData) {
        final String clientId = clientData.getClientId();
        MqttClientData cached = clientId != null ? cache.get(clientId) : null;
        if (cached == null) {
            synchronized (lock) {
                cached = MqttClientData.create(clientData);
                if (clientId != null) cache.put(clientId, cached);
            }
        }
        return cached;
    }

}
