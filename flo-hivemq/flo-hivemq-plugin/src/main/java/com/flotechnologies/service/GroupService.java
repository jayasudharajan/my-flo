package com.flotechnologies.service;

import com.flotechnologies.Flo;
import com.flotechnologies.annotations.NonBlank;
import com.flotechnologies.util.FloClient;
import com.flotechnologies.model.ParsedGroupTopic;
import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.annotations.Nullable;
import com.hivemq.spi.aop.cache.Cached;
import com.hivemq.spi.services.PluginExecutorService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

import io.reactivex.schedulers.Schedulers;
import routs.LruCache;
import routs.PathMatcher;

@Singleton
public class GroupService {
    @NotNull
    private static final Logger log = LoggerFactory.getLogger(GroupService.class);
    @NotNull
    private final Flo flo;
    @NotNull
    private final PathMatcher pathMatcher;
    @NotNull
    private final PluginExecutorService executorService;
    @NotNull
    private final LruCache<String, ParsedGroupTopic> cache;

    @Inject
    public GroupService(@NotNull final FloClient floClient,
                        @NotNull final PluginExecutorService executorService) {
        this.flo = floClient.getFlo();
        this.executorService = executorService;
        this.cache = new LruCache<>(1024);
        this.pathMatcher = new PathMatcher(1024);
        pathMatcher.add("home/group/:group_id<([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89AB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})>/device/:device_id<([a-fA-F0-9]{12})>/v1/telemetry", "telemetry");
        pathMatcher.add("home/group/:group_id<([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89AB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})>/device/:device_id<([a-fA-F0-9]{12})>/v1/will", "will");
        pathMatcher.add("home/group/:group_id<([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89AB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})>/device/:device_id<([a-fA-F0-9]{12})>/v1/test-result/vrzit", "vrzit");
        pathMatcher.add("home/group/:group_id<([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89AB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})>/device/:device_id<([a-fA-F0-9]{12})>/v1/test-result/mvrzit", "mvrzit");
        pathMatcher.add("home/group/:group_id<([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89AB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})>/device/:device_id<([a-fA-F0-9]{12})>/v1/directives-response", "directives-response");
    }

    /**
     * Resolve group topic
     * @param topic origin topic
     * @return group topic
     */
    @Nullable
    public ParsedGroupTopic parseGroupTopicCached(@NotNull final String topic) {
        if (topic.trim().isEmpty()) return null;

        ParsedGroupTopic cached = cache.get(topic);
        // LruCache doesn't support put(KEY, null) and contains(KEY),
        // we'd like to keep immutable and null-safety object,
        // so we need to put an immutable EMPTY object for recognizing that's not matched
        if (cached != null && cached == ParsedGroupTopic.EMPTY) return null;
        if (cached != null) return cached;

        cached = parseGroupTopicInner(topic);
        if (cached != null) {
            cache.put(topic, cached);
            return cached;
        }

        cached = ParsedGroupTopic.EMPTY;
        cache.put(topic, cached);
        return null;
    }

    /**
     * Resolve group topic
     * @param topic origin topic
     * @return group topic
     */
    @Nullable
    public ParsedGroupTopic parseGroupTopic(@NotNull final String topic) {
        return parseGroupTopicCached(topic);
    }

    /**
     * Resolve group topic
     * @param topic origin topic
     * @return group topic
     */
    @Nullable
    private ParsedGroupTopic parseGroupTopicInner(@NotNull final String topic) {
        if (topic.trim().isEmpty()) return null;

        ParsedGroupTopic groupTopic = null;
        PathMatcher.TrieNode node = pathMatcher.matchesNode(topic);
        if (node.end) { // matched
            String groupId = pathMatcher.namedPath.get("group_id");
            String deviceId = pathMatcher.namedPath.get("device_id");
            pathMatcher.namedPath.clear();

            if (groupId != null && deviceId != null && node.key != null) {
                groupTopic = ParsedGroupTopic.create(groupId, deviceId, node.key);
            }
        }
        return groupTopic;
    }

    /**
     * Blocking processing
     * @param token token, DO NOT put empty
     * @param groupId group id
     * @param deviceId Flo device id
     * @return isDeviceInGroup
     * @throws IOException exception
     */
    @Cached(timeToLive = 10, timeUnit = TimeUnit.SECONDS)
    public boolean isDeviceInGroup(@NonBlank @NotNull final String token,
                                   @NotNull final String groupId,
                                   @NotNull final String deviceId) throws IOException {
        if (deviceId.trim().isEmpty()) return false;
        if (groupId.trim().isEmpty()) return false;

        return groupId.equals(flo.groupOfDevice(token, deviceId)
                .subscribeOn(Schedulers.from(executorService)).blockingSingle(""));
    }
}
