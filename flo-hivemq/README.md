# flo-hivemq-plugin

[![CircleCI](https://circleci.com/gh/FloTechnologies/flo-hivemq-plugin/tree/dev.svg?style=svg&circle-token=de8898fe80fe827e089f46328d8d9ded957a7319)](https://circleci.com/gh/FloTechnologies/flo-hivemq-plugin/tree/dev)
[![Download](https://api.bintray.com/packages/flo/maven/flo-hivemq-plugin/images/download.svg)](https://bintray.com/flo/maven/flo-hivemq-plugin/_latestVersion)

Flo HiveMQ Plugin

* Flo Auth
* Retain messages
* Filter messages
* Classify messages
* Forward to Flo kafka
* Multiple services

## Build

Prepare Flo crediential for downloading deps, such like ~/.gradle/gradle.properties:

```
BINTRAY_USER=xxx
BINTRAY_KEY=xxx
```

```sh
./gradlew assemble
```

## Test

```sh
./gradlew test
```

flo-hivemq-plugin/build/reports/tests/test/index.html

## Coverage

```sh
./gradlew jacocoTestReport
```

flo-hivemq-plugin/build/reports/jacoco/test/html/index.html

## JavaDoc

```sh
./gradlew javadoc
```

flo-hivemq-plugin/build/docs/javadoc/index.html

## Deploy manually (without proguard)

```sh
./gradlew assemble bintrayUpload
```

## Deploy shadowJar (a.k.a fatjar) manually (without proguard)

```sh
./gradlew shadowJar
```

## load-test

Put certs into load-test/certs/

```
load-test/certs/
├── ffffff000000.key.pem
├── ffffff000000.cert.pem
├── *.cert.pem
├── *.key.pem
└── flo-ca-chain.cert.pem
```

```sh
docker-compose run -p 8089:8089 load-test locust --host $HOST:$PORT
```

Go to http://localhost:8089/

## Deployment by CircleCI

Remember setup those variables in environment for downloading deps:

* `BINTRAY_USER`
* `BINTRAY_KEY`

```
git tag TAG
git push TAG
```

## Proguard (Obfuscation/Optimization/Shrinking) - Experimental

```sh
./gradlew proguard
```

ref.  `build/libs-proguard/*`:

```
build/libs:
total 368
-rw-r--r--  1 yongjhih  staff    99K Jun 12 10:17 flo-hivemq-plugins-javadoc.jar
-rw-r--r--  1 yongjhih  staff    44K Jun 12 10:17 flo-hivemq-plugins-sources.jar
-rw-r--r--  1 yongjhih  staff    39K Jun 12 10:17 flo-hivemq-plugins.jar

build/libs-proguard:
total 296
-rw-r--r--  1 yongjhih  staff    99K Jun 12 10:17 flo-hivemq-plugins-javadoc.jar
-rw-r--r--  1 yongjhih  staff    22K Jun 12 10:17 flo-hivemq-plugins-sources.jar
-rw-r--r--  1 yongjhih  staff    24K Jun 12 10:17 flo-hivemq-plugins.jar
```

## Integration Test

```sh
docker-compose run build && docker-compose build app && docker-compose up local
```

Test non-tls subscription:

```sh
mosquitto_sub -h localhost -p 1883 -t home/device/8cc7aa0280f0/v1/will -u "user1" -d
```

Test tls subscription:

```sh
mosquitto_sub -h localhost -p 8883 -t home/device/8cc7aa0280f0/v1/will --cert config/client-certs/8cc7aa0280dc/client-cert.pem --key config/client-certs/8cc7aa0280dc/client-key.pem -d
```

Check logs/flo-hivemq.log

## Documentation

* https://www.hivemq.com/docs/upgrade/#hivemqdocs_introduction
