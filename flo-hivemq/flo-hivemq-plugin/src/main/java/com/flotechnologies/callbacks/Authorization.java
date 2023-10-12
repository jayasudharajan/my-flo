package com.flotechnologies.callbacks;


import com.flotechnologies.service.AuthorizationService;
import com.google.inject.Inject;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.annotations.Nullable;
import com.hivemq.spi.aop.cache.Cached;
import com.hivemq.spi.callback.CallbackPriority;
import com.hivemq.spi.callback.security.OnAuthorizationCallback;
import com.hivemq.spi.callback.security.authorization.AuthorizationBehaviour;
import com.hivemq.spi.security.ClientData;
import com.hivemq.spi.topic.MqttTopicPermission;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Collections;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * From Flo API permissions,
 * NOTICE: now it is blocking http request, we just apply cache for that
 * See workflow
 * https://www.hivemq.com/docs/plugins/latest/#client-authorization-chapter
 */
public class Authorization implements OnAuthorizationCallback {

    @NotNull
    private final Logger log = LoggerFactory.getLogger(Authorization.class);

    @NotNull
    private final AuthorizationService authorizationService;

    @Inject
    public Authorization(@NotNull final AuthorizationService authorizationService) {
        this.authorizationService = authorizationService;
    }

    /**
     * Blocking
     * How to disconnect the client if no permissions properly? Returns null?
     * @param clientData client data
     */
    @Override
    @Nullable
    public List<MqttTopicPermission> getPermissionsForClient(@NotNull final ClientData clientData) {
        try {
            final List<MqttTopicPermission> permissions = authorizationService.getPermissions(clientData);
            if (permissions.isEmpty()) return null;
            log.info("permissions: {}", permissions);
            return permissions;
        } catch (Exception e) {
            log.error("Error retrieving permissions for client id '{}'",
                    clientData.getClientId(), e);
        }

        return null;
    }




    /**
     * Default Behaviour should always be set to DENY as we take a WHITELIST approach.
     */
    @Override
    @NotNull
    public AuthorizationBehaviour getDefaultBehaviour() {
        return AuthorizationBehaviour.DENY;
    }

    /**
     * AuthorizationCallback should always be set to CRITICAL
     * as we want this callback to execute first.
     */
    @Override
    public int priority() {
        return CallbackPriority.CRITICAL;
    }

}
