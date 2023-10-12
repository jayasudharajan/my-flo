```
flutter build apk --target-platform android-arm --release && cd android && ./gradlew crashlyticsUploadDistributionRelease appDistributionUploadRelease && cd -
```
```
flutter build apk --target-platform android-arm --release && cd android && ./gradlew crashlyticsUploadDistributionRelease && cd -
```
```
flutter build apk --target-platform android-arm --release && cd android && ./gradlew appDistributionUploadRelease && cd -
```

```
flutter packages pub run build_runner build --delete-conflicting-outputs
```
