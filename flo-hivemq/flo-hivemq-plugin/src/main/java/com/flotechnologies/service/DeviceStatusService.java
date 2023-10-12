package com.flotechnologies.service;

import com.flotechnologies.annotations.NonBlank;
import com.flotechnologies.util.ApiFuturese.FutureCallbacks;
import com.google.common.base.Charsets;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.message.PUBLISH;
import com.hivemq.spi.message.QoS;
import com.hivemq.spi.message.RetainedMessage;
import com.hivemq.spi.services.AsyncRetainedMessageStore;
import com.hivemq.spi.services.PluginExecutorService;
import com.hivemq.spi.services.PublishService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.concurrent.ExecutorService;

import io.reactivex.functions.Action;

@Singleton
public class DeviceStatusService {
    @NotNull
    public static final Action EMPTY_ACTION = () -> {};
    @NotNull
    private final Logger log = LoggerFactory.getLogger(DeviceStatusService.class);
    @NotNull
    private final AsyncRetainedMessageStore asyncRetainedMessageStore;
    @NotNull
    private final PublishService publishService;
    @NotNull
    private final FirebaseService firebaseService;
    @NotNull
    private final ExecutorService executorService;
    @NotNull
    private static final String DEVICE_ID = "device_id";
    @NotNull
    private static final String STATUS = "status";
    @NotNull
    private static final String ONLINE = "online";
    @NotNull
    private static final String OFFLINE = "offline";
    @NotNull
    private static final String TELEMETRY = "telemetry";
    @NotNull
    private static final byte[] ONLINE_MESSAGE = ("{\"" + STATUS + "\":\"" + ONLINE + "\"}").getBytes(Charsets.UTF_8);

    @Inject
    public DeviceStatusService(@NotNull final AsyncRetainedMessageStore asyncRetainedMessageStore,
                               @NotNull final PublishService publishService,
                               @NotNull final PluginExecutorService executorService,
                               @NotNull final FirebaseService firebaseService) {
        this.asyncRetainedMessageStore = asyncRetainedMessageStore;
        this.publishService = publishService;
        this.executorService = executorService;
        this.firebaseService = firebaseService;
    }

    /**
     * @param deviceId Flo device id, DO NOT put empty
     */
    public void setWillTopicOnline(@NonBlank @NotNull final String deviceId) {
        final String willTopic = "home/device/" + deviceId + "/v1/will";
        final ListenableFuture<RetainedMessage> future =
                asyncRetainedMessageStore.getRetainedMessage(willTopic);

        Futures.addCallback(future, new FutureCallbacks<>(retainedMessage -> {
                if (retainedMessage == null || !Arrays.equals(retainedMessage.getMessage(),
                        ONLINE_MESSAGE)) {
                    final PUBLISH publish = new PUBLISH(ONLINE_MESSAGE, willTopic,
                            QoS.AT_LEAST_ONCE);
                    publish.setRetain(true);
                    publishService.publish(publish);
                }
            }, throwable -> {
                log.error("Error setting will topic '{}'", willTopic, throwable);
            }), executorService);
    }

    /**
     * @param deviceId Flo device ID, DO NOT put empty
     * @param timestamp offline timestamp
     */
    public void sendOnline(@NonBlank @NotNull final String deviceId,
                           final long timestamp) {
        try {
            firebaseService.updateDeviceStatus(deviceId, timestamp, true);
        } catch (Exception e) {
            log.error("Error updating online status for device {}", deviceId, e);
        }
    }

    /**
     * @param deviceId Flo device ID, DO NOT put empty
     * @param timestamp offline timestamp
     */
    public void sendOffline(@NonBlank @NotNull final String deviceId,
                            final long timestamp) {
        try {
            firebaseService.updateDeviceStatus(deviceId, timestamp, false);
        } catch (Throwable e) {
            log.error("Error updating offline status for device '{}'", deviceId, e);
        }
    }
}
