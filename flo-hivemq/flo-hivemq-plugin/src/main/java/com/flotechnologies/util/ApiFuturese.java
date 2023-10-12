package com.flotechnologies.util;

import com.google.api.core.ApiFutureCallback;
import com.google.api.core.ApiFutures;
import com.google.firebase.database.annotations.NotNull;

import java.util.function.Consumer;

/** Static utility methods for the {@link ApiFutures} interface. */
public final class ApiFuturese {
    private ApiFuturese() {}

    public final static class FutureCallbacks<V> extends Futurese.FutureCallbacks<V> implements ApiFutureCallback<V> {
        public FutureCallbacks() {
            super();
        }

        public FutureCallbacks(@NotNull final Consumer<? super V> success) {
            super(success);
        }

        public FutureCallbacks(@NotNull final Consumer<? super V> success, @NotNull final Consumer<? super Throwable> failure) {
            super(success, failure);
        }
    }
}
