package com.flotechnologies.model;

import com.google.auto.value.AutoValue;

import java.util.Objects;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;

@AutoValue
public abstract class PairNullable<L, R> {
    @Nonnull
    public static <L, R> PairNullable<L, R> of(@Nullable final L left,
                                               @Nullable final R right) {
        return new AutoValue_PairNullable(left, right);
    }

    @Nullable
    public abstract L left();

    @Nullable
    public abstract R right();

    @Nonnull
    public L leftOrThrow() {
        Objects.requireNonNull(left());
        return left();
    }

    @Nonnull
    public R rightOrThrow() {
        Objects.requireNonNull(right());
        return right();
    }
}
