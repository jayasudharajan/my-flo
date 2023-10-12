package com.flotechnologies.configuration;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.config.SystemInformation;

import java.util.Properties;

@Singleton
public class FirebaseConfiguration {

    @NotNull
    private static final String CONFIG_FILE = "firebase.properties";
    @NotNull
    private static final String FILE_NAME = "fileName";
    @NotNull
    private static final String URL = "URL";
    @NotNull
    private final String credentialsFilePath;
    @NotNull
    private final String firebaseDatabaseUrl;
    @NotNull
    private final SystemInformation systemInformation;

    @Inject
    FirebaseConfiguration(@NotNull final ConfigReader configReader,
                          @NotNull final SystemInformation systemInformation) throws Exception {
        this.systemInformation = systemInformation;
        final Properties properties = configReader.read(CONFIG_FILE);
        credentialsFilePath = properties.getProperty(FILE_NAME);
        firebaseDatabaseUrl = properties.getProperty(URL);
    }

    @NotNull
    public String getCredentialsFilePath() {
        return systemInformation.getPluginFolder().toPath()
                .resolve(credentialsFilePath).toString();
    }

    @NotNull
    public String getFirebaseDatabaseURL() {
        return firebaseDatabaseUrl;
    }

}
