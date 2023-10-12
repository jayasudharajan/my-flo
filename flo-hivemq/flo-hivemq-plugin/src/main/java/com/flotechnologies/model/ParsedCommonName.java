package com.flotechnologies.model;

import com.google.auto.value.AutoValue;
import com.google.common.base.Splitter;

import java.util.List;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;

/**
 * NOTICE commonName must be 3 elements that delimited with "|" such like "1|2|3"
 * or throws NullPointerException
 */
@AutoValue
public abstract class ParsedCommonName {

    public static final ParsedCommonName EMPTY = new ParsedCommonName() {
        @Nonnull
        @Override
        public String version() {
            throw new UnsupportedOperationException();
        }

        @Nonnull
        @Override
        public String clientName() {
            throw new UnsupportedOperationException();
        }

        @Nonnull
        @Override
        public String clientType() {
            throw new UnsupportedOperationException();
        }
    };

    @Nonnull
    public static ParsedCommonName create(@Nonnull final String version,
                                          @Nonnull final String clientType,
                                          @Nonnull final String clientName) {
        return new AutoValue_ParsedCommonName(version, clientType, clientName);
    }

    @Nullable
    public static ParsedCommonName create(@Nonnull final String commonName) {
        final List<String> splitCommonName = Splitter.on("|")
                .splitToList(commonName.toLowerCase());

        if (splitCommonName.size() == 3) {
            final String version = splitCommonName.get(0);
            final String clientType = splitCommonName.get(1);
            final String clientName = splitCommonName.get(2);
            if (version == null) return null;
            if (clientType == null) return null;
            if (clientName == null) return null;
            return create(version, clientType, clientName);
        }

        return null;
    }

    /**
     * @return version
     */
    @Nonnull
    public abstract String version();

    /**
     * @return ClientType
     */
    @Nonnull
    public abstract String clientType();

    /**
     * @return client name
     */
    @Nonnull
    public abstract String clientName();
}
