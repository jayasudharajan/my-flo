package com.flotechnologies.service;

import com.flotechnologies.Flo;
import com.flotechnologies.annotations.NonBlank;
import com.flotechnologies.util.FloClient;
import com.flotechnologies.model.MqttClientData;
import com.flotechnologies.model.SimpleMqttTopicPermission;
import com.google.common.annotations.VisibleForTesting;
import com.google.common.cache.CacheBuilder;
import com.google.common.cache.CacheLoader;
import com.google.common.cache.LoadingCache;
import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.annotations.Nullable;
import com.hivemq.spi.security.ClientData;
import com.hivemq.spi.services.PluginExecutorService;
import com.hivemq.spi.topic.MqttTopicPermission;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

import io.reactivex.Observable;
import io.reactivex.Scheduler;
import io.reactivex.schedulers.Schedulers;

@Singleton
public class AuthorizationService {
    @NotNull
    private final Flo flo;
    @NotNull
    private final PluginExecutorService executorService;
    @NotNull
    private MqttClientDataStore mqttClientDataStore;
    @NotNull
    private final Logger log = LoggerFactory.getLogger(AuthorizationService.class);
    @Nullable
    private String[] appPubTopics;
    @Nullable
    private String[] icdSubTopics;
    @Nullable
    private String[] icdPubTopics;
    @Nullable
    private String[] appSubTopics;

    @Inject
    public AuthorizationService(@NotNull final FloClient floClient,
                                @NotNull final PluginExecutorService executorService,
                                @NotNull final MqttClientDataStore mqttClientDataStore) {
        this.flo = floClient.getFlo();
        this.executorService = executorService;
        this.mqttClientDataStore = mqttClientDataStore;
        this.userPermissions = CacheBuilder.newBuilder()
                .maximumSize(10000)
                .expireAfterAccess(60, TimeUnit.SECONDS)
                .build(new CacheLoader<String, List<MqttTopicPermission>>() {
                           @Override
                           public List<MqttTopicPermission> load(@NotNull final String token) throws Exception {
                               return getUserPermissions(token);
                           }
                       }
                );
    }

    /**
     * Blocking
     * @param clientData client data
     * @return permissions
     * @throws Exception exception
     * NOTICE: Depend on config.xml for optimization
     */
    @NotNull
    public List<MqttTopicPermission> getPermissions(@NotNull final ClientData clientData)
            throws Exception {
        final MqttClientData mqttClientData = mqttClientDataStore.get(clientData);
        final MqttClientData.ClientType clientType = mqttClientData.getClientType();
        if (clientType == null) {
            log.info("clientType: null, empty permissions");
            return Collections.emptyList();
        }
        switch (clientType) {
            case TESTING: {
                log.info("testing: getAppPermissions");
                return Collections.emptyList();
            }
            case ICD: {
                log.info("clientType: ICD");
                final String deviceId = mqttClientData.getClientName();
                log.info("deviceId: {}", deviceId);
                if (deviceId == null || deviceId.trim().isEmpty()) return Collections.emptyList();
                return getICDPermissions(deviceId);
            }
            case APP: {
                log.info("clientType: APP");
                return getAppPermissions();
            }
            case USER: {
                log.info("clientType: USER");
                final String token = clientData.getUsername().orNull();
                log.info("token: {}", token);
                if (token == null || token.trim().isEmpty()) return Collections.emptyList();
                return getCachedUserPermissions(token);
            }
            default: {
                return Collections.emptyList();
            }
        }
    }

    /**
     * @param deviceId DO NOT put empty
     * @return permissions
     */
    @NotNull
    private List<MqttTopicPermission> getICDPermissions(@NonBlank @NotNull final String deviceId) {
        return mapPermissions(deviceId, getIcdSubTopics(), getIcdPubTopics());
    }

    @VisibleForTesting
    @NotNull
    public List<MqttTopicPermission> getICDPermissionsTesting(@NonBlank @NotNull final String deviceId) {
        return getICDPermissions(deviceId);
    }

    /**
     * @return permissions
     */
    @NotNull
    private List<MqttTopicPermission> getAppPermissions() {
        return mapPermissions("+", getAppSubTopics(), getAppPubTopics());
    }

    @VisibleForTesting
    @NotNull
    public List<MqttTopicPermission> getAppPermissionsTesting() {
        return getAppPermissions();
    }

    @VisibleForTesting
    @NotNull
    public String[] getIcdSubTopicsTesting() {
        return getIcdSubTopics();
    }

    @VisibleForTesting
    @NotNull
    public String[] getIcdPubTopicsTesting() {
        return getIcdPubTopics();
    }

    /**
     * Topics ICD may subscribe to:
     * @return topics
     */
    @NotNull
    private String[] getIcdSubTopics() {
        if (icdSubTopics == null) {
            synchronized (this) {
                icdSubTopics = new String[] {
                        "/notifications-response",
                        "/directives",
                        "/upgrade",
                        "/directives-response/ack"
                };
            }
        }
        return icdSubTopics;
    }

    /**
     * Topics Flo Device may publish to:
     * @return topics
     */
    @NotNull
    private String[] getIcdPubTopics() {
        if (icdPubTopics == null) {
            synchronized (this) {
                icdPubTopics = new String[] {
                        "/telemetry",
                        "/notifications",
                        "/notifications-response/ack",
                        "/alarm-notification-status",
                        "/directives/ack",
                        "/will",
                        "/directives-response",
                        "/test-result/vrzit",
                        "/test-result/mvrzit",
                        "/log/syslog",
                        "/external-actions/valve-status",
                        "/device-versions",
                        "/upgrade/ack",
                        "/upgrade/progress"
                };
            }
        }
        return icdPubTopics;
    }

    /**
     * @return topics
     */
    @NotNull
    private String[] getAppSubTopics() {
        if (appSubTopics == null) {
            synchronized (this) {
                appSubTopics = new String[] {
                        "/telemetry",
                        "/will",
                        "/directives/ack",
                        "/notifications-response/ack",
                        "/alarm-notification-status",
                        "/directives-response",
                        "/external-actions/valve-status",
                        "/device-versions",
                        "/upgrade/ack",
                        "/upgrade/progress",
                        "/notifications" // only for testing
                };
            }
        }
        return appSubTopics;
    }

    @VisibleForTesting
    @NotNull
    public String[] getAppSubTopicsTesting() {
        return getAppSubTopics();
    }

    @VisibleForTesting
    @NotNull
    public String[] getAppPubTopicsTesting() {
        return getAppPubTopics();
    }

    /**
     * @return app pub topics
     */
    @NotNull
    private String[] getAppPubTopics() {
        if (appPubTopics == null) {
            synchronized (this) {
                appPubTopics = new String[] {
                        "/directives",
                        "/notifications-response",
                        "/upgrade",
                        "/directives-response/ack"
                };
            }
        }
        return appPubTopics;
    }

    /**
     * @param token, DO NOT put empty
     * @return user permissions
     * @throws IOException exception
     * @throws ClassCastException exception
     * @throws IllegalStateException exception
     */
    @NotNull
    public List<MqttTopicPermission> getUserPermissions(@NonBlank @NotNull final String token)
            throws IOException,
            ClassCastException,
            IllegalStateException {
        return getUserPermissions(token, Schedulers.from(executorService));
    }

    @NotNull
    private final LoadingCache<String, List<MqttTopicPermission>> userPermissions;

    public List<MqttTopicPermission> getCachedUserPermissions(@NonBlank @NotNull final String token) {
        try {
            return userPermissions.get(token);
        } catch (ExecutionException e) {
            e.printStackTrace();
        }
        return Collections.emptyList();
    }

    /**
     * Blocking
     * Longer processing / Network processing
     * @param token Flo token, DO NOT put empty
     * @return permissions
     * @throws IOException exception
     * @throws ClassCastException exception
     * @throws IllegalStateException exception
     */
    @NotNull
    //@Cached(timeToLive = 60, timeUnit = TimeUnit.SECONDS)
    private List<MqttTopicPermission> getUserPermissions(@NonBlank @NotNull final String token,
                                                         @Nullable final Scheduler scheduler)
            throws IOException,
            ClassCastException,
            IllegalStateException {
        Observable<List<com.flotechnologies.MqttTopicPermission>> obs = flo.mqttTopicPermissions(token);
        if (scheduler != null) obs = obs.subscribeOn(scheduler);
        return obs
                .doOnNext(it -> {
                    log.info("mqttTopicPermissions", it);
                })
                .flatMap(it -> Observable.fromIterable(it))
                .doOnNext(it -> {
                    log.info(it.getActivity());
                    log.info(it.getTopic());
                })
                .filter(it -> it.getTopic() != null && it.getActivity() != null)
                .map(p -> new MqttTopicPermission(
                    p.getTopic(),
                    MqttTopicPermission.TYPE.ALLOW,
                    "sub".equals(p.getActivity())
                            ? MqttTopicPermission.ACTIVITY.SUBSCRIBE
                            : "pub".equals(p.getActivity())
                            ? MqttTopicPermission.ACTIVITY.PUBLISH
                            : MqttTopicPermission.ACTIVITY.ALL))
                .toList().blockingGet();
    }

    @VisibleForTesting
    @NotNull
    public List<MqttTopicPermission> getUserPermissionsTesting(@NonBlank @NotNull final String token)
            throws IOException,
                ClassCastException,
                IllegalStateException {
        return getUserPermissions(token, null);
    }

    /**
     * @param deviceId Flo device ID, DO NOT put empty
     * @return topic
     */
    @NotNull
    private static String getRootTopic(@NonBlank @NotNull final String deviceId) {
        return "home/device/" + deviceId + "/v1";
    }

    /**
     * @param deviceId Flo device ID, DO NOT put empty
     * @param subTopics subscribed topics
     * @param pubTopics published topics
     * @return permissions
     */
    @NotNull
    private static List<MqttTopicPermission> mapPermissions(@NonBlank @NotNull final String deviceId,
                                                            @NotNull final String[] subTopics,
                                                            @NotNull final String[] pubTopics) {
        final String rootTopic = getRootTopic(deviceId);
        final List<MqttTopicPermission> permissions = new ArrayList<>();

        for (String subTopic : subTopics) {
            permissions.add(new SimpleMqttTopicPermission(
                    rootTopic + subTopic,
                    MqttTopicPermission.TYPE.ALLOW,
                    MqttTopicPermission.QOS.ALL,
                    MqttTopicPermission.ACTIVITY.SUBSCRIBE
            ));
        }

        for (String pubTopic : pubTopics) {
            permissions.add(new SimpleMqttTopicPermission(
                    rootTopic + pubTopic,
                    MqttTopicPermission.TYPE.ALLOW,
                    MqttTopicPermission.QOS.ALL,
                    MqttTopicPermission.ACTIVITY.PUBLISH
            ));
        }

        return Collections.unmodifiableList(permissions);
    }
}
