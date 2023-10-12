package com.flotechnologies.service;

import com.flotechnologies.annotations.NonBlank;
import com.google.firebase.database.*;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.annotations.Nullable;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.atomic.AtomicInteger;

import javax.inject.Inject;

import rxfirebase2.admin.database.RxDatabaseReference;

public class FirebaseService {

    @NotNull
    private static final Logger log = LoggerFactory.getLogger(FirebaseService.class);

    @NotNull
    private final FirebaseDatabase firebase;
    private static final int MAX_ATTEMPTS = 2;
    @NotNull
    private static final String DEVICE_STATUS = "device_status";

    @Inject
    public FirebaseService(@NotNull final FirebaseDatabase firebase) {
        this.firebase = firebase;
    }

    public void updateDeviceStatus(@NonBlank @NotNull final String deviceId,
                                   final long timestamp,
                                   final boolean isConnected) {
        final DatabaseReference deviceStatusRef = firebase.getReference(DEVICE_STATUS);
        final AtomicInteger numAttempts = new AtomicInteger(0);
        // TODO: Using RxDatabaseReference.transaction() instead, for example:
        // <pre>
        //    RxDatabaseReference.transaction(deviceStatusRef.child(deviceId), mutableData -> {
        //        if (numAttempts.getAndIncrement() >= MAX_ATTEMPTS) {
        //            return Transaction.abort();
        //        }
        //        final Long savedTimestamp = mutableData.child("timestamp").getValue(Long.class);
        //        if (savedTimestamp == null || savedTimestamp < timestamp) {
        //            mutableData.child("device_id").setValue(deviceId);
        //            mutableData.child("timestamp").setValue(timestamp);
        //            mutableData.child("is_connected").setValue(isConnected);
        //            return Transaction.success(mutableData);
        //        }
        //        return Transaction.abort();
        //    })
        //    .subscribeOn(Schedulers.from(pluginExecutorService))
        //    .doOnError(e -> {
        //        log.error("Firebase transaction failed", e);
        //    })
        //    .subscribe(dataSnapshot -> {});
        // </pre>
        deviceStatusRef.child(deviceId).runTransaction(new Transaction.Handler() {
            @Override
            public Transaction.Result doTransaction(@NotNull final MutableData mutableData) {
                if (numAttempts.getAndIncrement() >= MAX_ATTEMPTS) {
                    return Transaction.abort();
                }

                final Long savedTimestamp = mutableData.child("timestamp").getValue(Long.class);

                if (savedTimestamp == null || savedTimestamp < timestamp) {
                    mutableData.child("device_id").setValue(deviceId);
                    mutableData.child("timestamp").setValue(timestamp);
                    mutableData.child("is_connected").setValue(isConnected);
                    return Transaction.success(mutableData);
                }
                return Transaction.abort();
            }
            @Override
            public void onComplete(@Nullable final DatabaseError databaseError,
                                   boolean isCommitted,
                                   @Nullable final DataSnapshot dataSnapshot) {
                if (databaseError != null) {
                    log.error("Firebase transaction failed", databaseError);
                }
            }
        });
    }
}
