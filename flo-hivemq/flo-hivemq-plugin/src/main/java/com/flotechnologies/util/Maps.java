package com.flotechnologies.util;

import java.util.Map;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;

public class Maps {
    private Maps() {}

    @Nonnull
    public static <K, V> Map<K, V> putIfNotNull(@Nonnull final Map<K, V> map,
                                                @Nonnull final K key,
                                                @Nullable final V value) {
        if (value == null) return map;
        map.put(key, value);
        return map;
    }

    @Nonnull
    public static <K, V> Map<K, V> put(@Nonnull final Map<K, V> map,
                                       @Nonnull final K key,
                                       @Nonnull final V value) {
        map.put(key, value);
        return map;
    }

    public static class Builder<K, V> {
        @Nonnull
        private final Map<K, V> map;

        public Builder(@Nonnull final Map<K, V> map) {
            this.map = map;
        }

        @Nonnull
        public static <K, V> Builder<K, V> of(@Nonnull final Map<K, V> map) {
            return new Builder<>(map);
        }

        @Nonnull
        public Map<K, V> get() {
            return map;
        }

        @Nonnull
        public Builder<K, V> put(@Nonnull final K key,
                                 @Nonnull final V value) {
            map.put(key, value);
            return this;
        }

        @Nonnull
        public Builder<K, V> putIfNotNull(@Nonnull final K key,
                                          @Nullable final V value) {
            if (value == null) return this;
            return put(key, value);
        }
    }
}
