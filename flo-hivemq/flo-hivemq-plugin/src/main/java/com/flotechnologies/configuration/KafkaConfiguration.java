package com.flotechnologies.configuration;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;

import java.util.Properties;

@Singleton
public class KafkaConfiguration {
    @NotNull
    private static final String CONFIG_FILE = "kafka.properties";
    @NotNull
    private final Properties properties;

    @Inject
    KafkaConfiguration(@NotNull final ConfigReader configReader) throws Exception {
        properties = configReader.read(CONFIG_FILE);
    }

    /**
     * @return properties
     */
    @NotNull
    public Properties getProperties() {
        return properties;
    }
}
