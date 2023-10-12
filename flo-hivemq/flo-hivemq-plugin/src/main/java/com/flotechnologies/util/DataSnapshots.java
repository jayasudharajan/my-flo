package com.flotechnologies.util;

import com.google.common.annotations.VisibleForTesting;
import com.google.firebase.database.DataSnapshot;

import java.util.List;
import java.util.Map;
import java.util.Objects;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;

/**
 * TODO: Move to be as lib
 */
public class DataSnapshots {
    private DataSnapshots() {}

    @VisibleForTesting
    @Nullable
    public static <T> T getValueTesting(@Nonnull final Class<T> clazz,
                                        @Nonnull final DataSnapshot dataSnapshot) {
        return getValue(clazz, dataSnapshot);
    }

    @VisibleForTesting
    @Nonnull
    public static <T> T getValueOrThrowTesting(@Nonnull final Class<T> clazz,
                                               @Nonnull final DataSnapshot dataSnapshot) {
        return getValueOrThrow(clazz, dataSnapshot);
    }

    @Nullable
    private static <T> T getValue(@Nonnull final Class<T> clazz,
                                  @Nonnull final DataSnapshot dataSnapshot) {
        return clazz.cast(dataSnapshot.getValue());
    }

    @Nonnull
    private static <T> T getValueOrThrow(@Nonnull final Class<T> clazz,
                                         @Nonnull final DataSnapshot dataSnapshot) {
        return clazz.cast(Objects.requireNonNull(dataSnapshot.getValue()));
    }

    @Nullable
    public static Long getLong(@Nonnull final DataSnapshot dataSnapshot) {
        return getValue(Long.class, dataSnapshot);
    }

    @Nonnull
    public static long getLongOrThrow(@Nonnull final DataSnapshot dataSnapshot) {
        return Objects.requireNonNull(getLong(dataSnapshot)).longValue();
    }

    @Nonnull
    public static long getValue(@Nonnull final DataSnapshot dataSnapshot,
                                @Nonnull final long defaultValue) {
        final Long value = getLong(dataSnapshot);
        return value != null ? value : defaultValue;
    }

    @Nullable
    public static Boolean getBoolean(@Nonnull final DataSnapshot dataSnapshot) {
        return getValue(Boolean.class, dataSnapshot);
    }

    @Nonnull
    public static boolean getBooleanOrThrow(@Nonnull final DataSnapshot dataSnapshot) {
        return Objects.requireNonNull(getBoolean(dataSnapshot)).booleanValue();
    }

    @Nonnull
    public static boolean getValue(@Nonnull final DataSnapshot dataSnapshot,
                                   @Nonnull final boolean defaultValue) {
        final Boolean value = getBoolean(dataSnapshot);
        return value != null ? value : defaultValue;
    }

    @Nullable
    public static Double getDouble(@Nonnull final DataSnapshot dataSnapshot) {
        return getValue(Double.class, dataSnapshot);
    }

    @Nonnull
    public static double getDoubleOrThrow(@Nonnull final DataSnapshot dataSnapshot) {
        return Objects.requireNonNull(getDouble(dataSnapshot)).doubleValue();
    }

    @Nonnull
    public static double getValue(@Nonnull final DataSnapshot dataSnapshot,
                                  @Nonnull final double defaultValue) {
        final Double value = getDouble(dataSnapshot);
        return value != null ? value : defaultValue;
    }

    @Nullable
    public static String getString(@Nonnull final DataSnapshot dataSnapshot) {
        return getValue(String.class, dataSnapshot);
    }

    @Nonnull
    public static String getValue(@Nonnull final DataSnapshot dataSnapshot,
                                  @Nonnull final String defaultValue) {
        final String value = getString(dataSnapshot);
        return value != null ? value : defaultValue;
    }

    @Nullable
    public static Map<String, Object> getMap(@Nonnull final DataSnapshot dataSnapshot) {
        return getValue(Map.class, dataSnapshot);
    }

    @Nonnull
    public static Map<String, Object> getValue(@Nonnull final DataSnapshot dataSnapshot,
                                               @Nonnull final Map<String, Object> defaultValue) {
        final Map<String, Object> value = getMap(dataSnapshot);
        return value != null ? value : defaultValue;
    }

    @Nullable
    public static List<Object> getList(@Nonnull final DataSnapshot dataSnapshot) {
        return getValue(List.class, dataSnapshot);
    }

    @Nonnull
    public static List<Object> getValue(@Nonnull final DataSnapshot dataSnapshot,
                                        @Nonnull final List<Object> defaultValue) {
        final List<Object> value = getList(dataSnapshot);
        return value != null ? value : defaultValue;
    }
}
