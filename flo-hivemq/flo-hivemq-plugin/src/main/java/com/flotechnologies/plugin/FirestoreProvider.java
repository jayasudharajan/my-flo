package com.flotechnologies.plugin;

import com.flotechnologies.configuration.FirebaseConfiguration;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.database.FirebaseDatabase;
import com.google.inject.Inject;
import com.google.inject.Provider;
import com.hivemq.spi.annotations.NotNull;

import java.io.FileInputStream;
import java.io.IOException;

public class FirestoreProvider implements Provider<FirebaseDatabase> {

    @NotNull
    private final FirebaseConfiguration firebaseConfiguration;

    @Inject
    public FirestoreProvider(@NotNull final FirebaseConfiguration firebaseConfiguration) {
        this.firebaseConfiguration = firebaseConfiguration;
    }

    @NotNull
    @Override
    public FirebaseDatabase get() {
        try {
            final String path = firebaseConfiguration.getCredentialsFilePath();
            final FileInputStream serviceAccount =
                    new FileInputStream(path);
            final GoogleCredentials credentials = GoogleCredentials.fromStream(serviceAccount);
            final FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(credentials)
                    .setDatabaseUrl(firebaseConfiguration.getFirebaseDatabaseURL())
                    .build();
            FirebaseApp.initializeApp(options);
        } catch (IOException e) {
            e.printStackTrace();
        }

        return FirebaseDatabase.getInstance();
    }

}

