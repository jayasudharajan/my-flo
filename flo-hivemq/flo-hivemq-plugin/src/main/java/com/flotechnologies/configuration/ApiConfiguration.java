package com.flotechnologies.configuration;


import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;

import java.util.Properties;

@Singleton
public class ApiConfiguration {
    @NotNull
    private static final String CONFIG_FILE = "api.properties";
    @NotNull
    private final String url;

    @Inject
    public ApiConfiguration(@NotNull final ConfigReader configReader) throws Exception {
        final Properties properties = configReader.read(CONFIG_FILE);
        String s = properties.getProperty("api.url");
        if (s == null) throw new IllegalAccessException("Require " + CONFIG_FILE + ":api.url");
        url = s;
    }

    /**
     * @return url
     */
    @NotNull
    public String getUrl() {
        return url;
    }
}
