package com.flotechnologies.util;

import com.flotechnologies.Flo;
import com.flotechnologies.configuration.ApiConfiguration;
import com.github.aurae.retrofit2.LoganSquareConverterFactory;
import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.jakewharton.retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory;

import okhttp3.OkHttpClient;
import retrofit2.Retrofit;

/**
 * Type-safety endpoints with Retrofit for Flo RESTful service
 */
@Singleton
public class FloClient {
    @NotNull
    private final OkHttpClient okHttpClient;
    @NotNull
    private final Flo flo;

    @Inject
    public FloClient(@NotNull final OkHttpClient okHttpClient,
                     @NotNull final ApiConfiguration config) {
        this.okHttpClient = okHttpClient;
        this.flo = new Retrofit.Builder()
                .addCallAdapterFactory(RxJava2CallAdapterFactory.create())
                .addConverterFactory(LoganSquareConverterFactory.create())
                .baseUrl(config.getUrl())
                .client(okHttpClient)
                .build()
                .create(Flo.class);
    }

    @NotNull
    public Flo getFlo() {
        return flo;
    }

    @NotNull
    public OkHttpClient getHttpClient() {
        return okHttpClient;
    }
}
