package com.flotechnologies.model;

import com.google.auto.value.AutoValue;

import javax.annotation.Nonnull;

@AutoValue
public abstract class Pair<L, R> {
    @Nonnull
    public static <L, R> Pair<L, R> of(@Nonnull final L left,
                                       @Nonnull final R right) {
        return new AutoValue_Pair(left, right);
    }

    @Nonnull
    public abstract L left();

    @Nonnull
    public abstract R right();
}
