FROM openjdk:8-jre-alpine

ENV sbt_version 1.0.4
ENV sbt_home /usr/local/sbt
ENV PATH ${PATH}:${sbt_home}/bin

RUN echo https://nl.alpinelinux.org/alpine/v3.9/main > /etc/apk/repositories
RUN echo https://nl.alpinelinux.org/alpine/v3.9/community >> /etc/apk/repositories

# Install sbt
RUN apk add --no-cache --update bash wget && \
    mkdir -p "$sbt_home" && \
    wget -qO - --no-check-certificate "https://github.com/sbt/sbt/releases/download/v$sbt_version/sbt-$sbt_version.tgz" | tar xz -C $sbt_home --strip-components=1 && \
    apk del wget && \
    sbt sbtVersion

WORKDIR /root
