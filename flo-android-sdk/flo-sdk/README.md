# flo-sdk for java

maven repo: https://bintray.com/flo/maven/flo-android-sdk

## Testing

```sh
./gradlew :flo-sdk:test
```

```sh
FLO_DEV_TESTER_USERNAME="" \
FLO_DEV_TESTER_PASSWORD="" \
FLO_DEV_ADMIN_USERNAME="" \
FLO_DEV_ADMIN_PASSWORD="" \
  ./gradlew :flo-sdk:test
```

Specify class:

```sh
./gradlew :flo-sdk:test --tests com.flotechnologies.FaqSpec
```

## Deployment

```sh
./gradlew :flo-sdk:bintrayUpload
```

## Coverage

```sh
./gradlew :flo-sdk:jacocoTestReport
```
