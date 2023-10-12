package com.flotechnologies.model;

import com.flotechnologies.util.Optionals;
import com.google.auto.value.AutoValue;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.security.ClientData;
import com.hivemq.spi.security.SslClientCertificate;
import com.hivemq.spi.services.configuration.entity.Listener;

import java.util.Objects;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;

/**
 * Non Singleton
 */
@AutoValue
public abstract class MqttClientData {
    @NotNull
    public static final String ICD = "icd";

    @NotNull
    public static final String GEN1 = "gen1";

    @NotNull
    public static final String GEN2 = "gen2";

    @NotNull
    public static final String APP = "app";

    @NotNull
    public static final MqttClientData EMPTY = new MqttClientData() {
        @Nonnull
        @Override
        protected ClientData clientData() {
            throw new UnsupportedOperationException();
        }
    };

    @Nonnull
    protected abstract ClientData clientData();

    @Nullable
    protected ParsedCommonName parsedCommonName;

    @Nullable
    private ClientType clientType = ClientType.NULL;

    @Nullable
    private String clientName = NULL_STRING;

    @NotNull
    public static final String NULL_STRING = new String();

    public enum ClientType {
        APP,
        ICD,
        USER,
        TESTING,
        NULL
    }

    @Nullable
    protected ParsedCommonName parsedCommonName() {
        if (parsedCommonName == null) {
            synchronized (this) {
                parsedCommonName = Optionals.toJavaUtil(clientData().getCertificate())
                        .map(SslClientCertificate::commonName)
                        .map(ParsedCommonName::create)
                        .orElse(ParsedCommonName.EMPTY);
            }
        }

        return parsedCommonName != ParsedCommonName.EMPTY ? parsedCommonName : null;
    }

    @Nonnull
    public static MqttClientData create(@Nonnull final ClientData clientData) {
        return new AutoValue_MqttClientData(clientData);
    }

    /**
     * 8000 - app        - token expected - no cert expected / websocket
     * 8001 - user     - token expected - no cert expected
     * 8883 - flo device - cert expected
     * 8884 - flo device - cert expected
     * @return client type
     * NOTICE: Depend on config.xml for optimization
     */
    @Nullable
    public ClientType getClientType() {
        if (clientType != ClientType.NULL) return clientType;
        clientType = null;
        int port = Optionals.toJavaUtil(clientData().getListener())
                .map(Listener::getPort)
                .orElse(-1);
        if (port < 0) return null;
        switch (port) {
            case 1883: {
                clientType = ClientType.TESTING;
                return clientType;
            }
            case 8000: {
                if (!clientData().getUsername().isPresent()) {
                    return null;
                }
                clientType = ClientType.APP;
                return clientType;
            }
            case 8001: {
                if (!clientData().getUsername().isPresent()) {
                    return null;
                }
                clientType = ClientType.USER;
                return clientType;
            }
            case 8883:
            case 8884: { // Flo Device / ICD
                if (!clientData().getCertificate().isPresent()) {
                    return null;
                }
                if (parsedCommonName() == null) { // Invalid certificate
                    return null;
                }
                switch (parsedCommonName().clientType().toLowerCase()) {
                    case ICD:
                    case GEN1:
                    case GEN2: {
                        clientType = ClientType.ICD;
                        return clientType;
                    }
                    case APP: {
                        clientType = ClientType.APP;
                        return clientType;
                    }
                    default: {
                        return null;
                    }
                }
            }
            default: {
                return null;
            }
        }
    }

    /**
     * @return client type
     */
    @NotNull
    public ClientType getClientTypeLegacy() {
        if (!clientData().getCertificate().isPresent()) {
            return ClientType.USER;
        }
        if (parsedCommonName() == null) { // Invalid certificate
            return ClientType.USER;
        }
        if (parsedCommonName().clientType().toLowerCase().equals(ICD) ||
                parsedCommonName().clientType().toLowerCase().equals(GEN1) ||
                parsedCommonName().clientType().toLowerCase().equals(GEN2)) {
            return ClientType.ICD;
        }
        return ClientType.APP; // it's dangerous as default
    }

    /**
     * TODO NonNull
     * @return client name
     */
    @Nullable
    public String getClientName() {
        if (!Objects.equals(clientName, NULL_STRING)) return clientName;
        clientName = null;
        if (!clientData().getCertificate().isPresent()) {
            return null;
        }
        if (parsedCommonName() == null) {
            return null;
        }
        clientName = parsedCommonName().clientName();
        return clientName;
    }
}
