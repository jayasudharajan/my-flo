package com.flotechnologies.configuration;


import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.config.SystemInformation;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

@Singleton
public class ConfigReader {
    @NotNull
    private final Logger log = LoggerFactory.getLogger(ConfigReader.class);
    @NotNull
    private final SystemInformation systemInformation;

    @Inject
    ConfigReader(@NotNull final SystemInformation systemInformation) {
        this.systemInformation = systemInformation;
    }

    /**
     * @param fileName file name
     * @return properties
     * @throws IOException exception
     */
    @NotNull
    public Properties read(@NotNull final String fileName) throws Exception {
        final File configFolder = systemInformation.getConfigFolder();
        final File file = new File(configFolder, fileName);
        final String path = file.getAbsolutePath();

        if (!file.canRead()) {
            throw new IOException("Could not read properties file " + path);
        }

        try (InputStream is = new FileInputStream(file)) {
            Properties properties = new Properties();

            log.debug("Reading property file {}", path);
            properties.load(is);
            return properties;
        } catch (IOException e) {
            throw new IOException("An error occurred while reading the properties file " + path, e);
        }
    }
}
