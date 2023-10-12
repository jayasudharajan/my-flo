package com.flotechnologies.callbacks;

import com.flotechnologies.service.GroupService;
import com.flotechnologies.model.ParsedGroupTopic;
import com.flotechnologies.util.Futurese.FutureCallbacks;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.inject.Inject;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.callback.CallbackPriority;
import com.hivemq.spi.callback.events.OnSubscribeCallback;
import com.hivemq.spi.callback.exception.InvalidSubscriptionException;
import com.hivemq.spi.message.SUBSCRIBE;
import com.hivemq.spi.message.Topic;
import com.hivemq.spi.security.ClientData;
import com.hivemq.spi.services.AsyncSubscriptionStore;
import com.hivemq.spi.services.PluginExecutorService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ExecutorService;

public class Subscribe implements OnSubscribeCallback {

    @NotNull
    private final Logger log = LoggerFactory.getLogger(Subscribe.class);

    @NotNull
    private final GroupService groupService;
    @NotNull
    private final AsyncSubscriptionStore subscriptionStore;
    @NotNull
    private final ExecutorService executorService;

    @Inject
    Subscribe(@NotNull final AsyncSubscriptionStore subscriptionStore,
              @NotNull final GroupService groupService,
              @NotNull final PluginExecutorService executorService) {
        this.subscriptionStore = subscriptionStore;
        this.groupService = groupService;
        this.executorService = executorService;
    }

    /**
     * @param subscribe subscribe
     * @param clientData client data
     * @throws InvalidSubscriptionException exception
     */
    @Override
    public void onSubscribe(@NotNull final SUBSCRIBE subscribe,
                            @NotNull final ClientData clientData)
            throws InvalidSubscriptionException {
        final String token = clientData.getUsername().orNull();
        if (token == null || token.trim().isEmpty()) return;

        for (final Topic topic : subscribe.getTopics()) {
            final ParsedGroupTopic parsedGroupTopic =
                    groupService.parseGroupTopic(topic.getTopic());

            // Not a group topic
            if (parsedGroupTopic == null) continue;

            boolean isDeviceInGroup;
            try {
                // Long-time processing from http
                isDeviceInGroup = groupService.isDeviceInGroup(token, parsedGroupTopic.groupId(), parsedGroupTopic.deviceId());
            } catch (Throwable e) {
                log.error(e.getMessage());
                throw new InvalidSubscriptionException(e);
            }

            if (isDeviceInGroup) {
                forwardSubscription(clientData.getClientId(), topic, parsedGroupTopic.forwardedTopic());
            } else {
                final String message = String.format("Device %s is not in group %s",
                        parsedGroupTopic.deviceId(),
                        parsedGroupTopic.groupId());
                log.info(message);
                throw new InvalidSubscriptionException(message);
            }
        }
    }

    /**
     * @param clientId client id
     * @param originalTopic original topic
     * @param forwardedTopic forwarded topic
     */
    private void forwardSubscription(@NotNull final String clientId,
                                     @NotNull final Topic originalTopic,
                                     @NotNull final String forwardedTopic) {
        final ListenableFuture<Void> future = subscriptionStore.addSubscription(clientId,
                new Topic(forwardedTopic, originalTopic.getQoS()));

        Futures.addCallback(future, new FutureCallbacks<>(v -> {
            log.info("Forwarded client {} subscription from {} to {}",
                    clientId, originalTopic.getTopic(), forwardedTopic);
        }, e -> {
            log.error("Error while forwarding client {} subscription from {} to {} -- {} ",
                    clientId, originalTopic.getTopic(), forwardedTopic, e);
        }), executorService);
    }

    /**
     */
    @Override
    public int priority() {
        return CallbackPriority.MEDIUM;
    }
}
