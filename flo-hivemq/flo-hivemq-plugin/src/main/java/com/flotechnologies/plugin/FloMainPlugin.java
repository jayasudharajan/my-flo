/*
 * Copyright 2015 dc-square GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.flotechnologies.plugin;

import com.flotechnologies.callbacks.Authorization;
import com.flotechnologies.callbacks.ClientConnect;
import com.flotechnologies.callbacks.ClientDisconnect;
import com.flotechnologies.callbacks.FloOnAuthenticationCallback;
import com.flotechnologies.callbacks.InsufficientPermissionsDisconnect;
import com.flotechnologies.callbacks.PublishReceived;
import com.flotechnologies.callbacks.Subscribe;
import com.hivemq.spi.PluginEntryPoint;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.callback.registry.CallbackRegistry;
import com.hivemq.spi.callback.security.OnAuthenticationCallback;

import javax.annotation.PostConstruct;
import javax.inject.Inject;

public class FloMainPlugin extends PluginEntryPoint {

    @NotNull
    private final OnAuthenticationCallback onAuthenticationCallback;
    @NotNull
    private final ClientConnect clientConnect;
    @NotNull
    private final Authorization authorization;
    @NotNull
    private final ClientDisconnect clientDisconnect;
    @NotNull
    private final PublishReceived publishReceived;
    @NotNull
    private final InsufficientPermissionsDisconnect insufficientPermissionsDisconnect;
    @NotNull
    private final Subscribe subscribe;

    @Inject
    public FloMainPlugin(
            @NotNull final FloOnAuthenticationCallback onAuthenticationCallback,
            @NotNull final ClientConnect clientConnect,
            @NotNull final Authorization authorization,
            @NotNull final ClientDisconnect clientDisconnect,
            @NotNull final PublishReceived publishReceived,
            @NotNull final InsufficientPermissionsDisconnect insufficientPermissionsDisconnect,
            @NotNull final Subscribe subscribe) {
        this.onAuthenticationCallback = onAuthenticationCallback;
        this.clientConnect = clientConnect;
        this.authorization = authorization;
        this.clientDisconnect = clientDisconnect;
        this.publishReceived = publishReceived;
        this.insufficientPermissionsDisconnect = insufficientPermissionsDisconnect;
        this.subscribe = subscribe;
    }

    @PostConstruct
    public void postConstruct() {
        CallbackRegistry callbackRegistry = getCallbackRegistry();
        callbackRegistry.addCallback(onAuthenticationCallback);
        callbackRegistry.addCallback(clientConnect);
        callbackRegistry.addCallback(authorization);
        callbackRegistry.addCallback(clientDisconnect);
        callbackRegistry.addCallback(insufficientPermissionsDisconnect);
        callbackRegistry.addCallback(publishReceived);
        callbackRegistry.addCallback(subscribe);
    }
}
