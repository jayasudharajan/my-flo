package com.flotechnologies.model;

import com.google.auto.value.AutoValue;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;

@AutoValue
public abstract class ParsedGroupTopic {

    public static final Empty EMPTY = new Empty();

    public static class Empty extends ParsedGroupTopic {
        @Nonnull
        @Override
        public String groupId() {
            throw new UnsupportedOperationException();
        }

        @Nonnull
        @Override
        public String deviceId() {
            throw new UnsupportedOperationException();
        }

        @Nonnull
        @Override
        public String subTopic() {
            throw new UnsupportedOperationException();
        }
    }

    @Nonnull
    public static ParsedGroupTopic create(@Nonnull final String groupId,
                                          @Nonnull final String deviceId,
                                          @Nonnull final String subTopic) {
        return new AutoValue_ParsedGroupTopic(groupId, deviceId, subTopic);
    }

    /**
     * @return group id
     */
    @Nonnull
    public abstract String groupId();

    /**
     * @return device id
     */
    @Nonnull
    public abstract String deviceId();

    /**
     * @return sub topic
     */
    @Nonnull
    public abstract String subTopic();

    @Nullable
    private String forwardedTopic;

    /**
     * @return forwarded topic
     */
    @Nonnull
    public String forwardedTopic() {
        if (forwardedTopic == null) {
            synchronized (this) {
                forwardedTopic = "home/device/" + deviceId() + "/v1/" + subTopic();
            }
        }
        return forwardedTopic;
    }
}
