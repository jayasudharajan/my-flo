package com.flotechnologies.util;

import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.firebase.database.annotations.NotNull;
import com.google.firebase.database.annotations.Nullable;

import java.util.concurrent.Callable;
import java.util.concurrent.Executor;
import java.util.concurrent.Future;
import java.util.function.Consumer;

import static com.google.common.util.concurrent.JdkFutureAdapters.listenInPoolThread;

/** Static utility methods for the {@link Futures} interface. */
public final class Futurese {
    private Futurese() {}

    public static class FutureCallbacks<V> implements FutureCallback<V> {
        private final Consumer<? super V> success;
        private final Consumer<? super Throwable> failure;
        // TODO: Move to Consumers.EMPTY
        public static final Consumer<? super Object> EMPTY_CONSUMER = v -> {};

        public FutureCallbacks() {
            this(EMPTY_CONSUMER, EMPTY_CONSUMER);
        }

        public FutureCallbacks(@NotNull final Consumer<? super V> success) {
            this(success, EMPTY_CONSUMER);
        }

        public FutureCallbacks(@NotNull final Consumer<? super V> success, @NotNull final Consumer<? super Throwable> failure) {
            this.success = success;
            this.failure = failure;
        }

        @Override
        public void onFailure(@NotNull final Throwable e) {
            failure.accept(e);
        }

        @Override
        public void onSuccess(@Nullable final V v) {
            success.accept(v);
        }
    }

    public static <V> void addListenable(@NotNull final Callable<ListenableFuture<? extends V>> futureCallable,
                                         @NotNull final Consumer<? super V> success,
                                         @NotNull final Consumer<? super Throwable> failure,
                                         @NotNull final Executor executor) {
        try {
            Futures.addCallback(futureCallable.call(),
                    new FutureCallbacks<>(success, failure),
                    executor);
        } catch (Throwable e) {
            failure.accept(e);
        }
    }

    public static <V> void addCallback(@NotNull final Callable<Future<? extends V>> futureCallable,
                                       @NotNull final Consumer<? super V> success,
                                       @NotNull final Consumer<? super Throwable> failure,
                                       @NotNull final Executor executor) {
        try {
            Futures.addCallback(listenInPoolThread(futureCallable.call(), executor),
                    new FutureCallbacks<>(success, failure),
                    executor);
        } catch (Throwable e) {
            failure.accept(e);
        }
    }
}
