package com.flotechnologies.util;

import java.util.Optional;

import javax.annotation.Nonnull;

public class Optionals {
    private Optionals() {
        throw new UnsupportedOperationException();
    }

    @Nonnull
    public static <T> Optional<T> toJavaUtil(@Nonnull final com.google.common.base.Optional<T> optional) {
        return Optional.ofNullable(optional.orNull());
    }
}
