# StudyGram

StudyGram is an offline-first Flutter study feed with subject accounts, study cards, file import, stories, and progress tracking.

## Development

Requires Flutter stable and Android SDK (API 36), Java 17.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The release APK is produced at `build/app/outputs/flutter-apk/app-release.apk`.

## CI

GitHub Actions runs dependency resolution, static analysis, tests, and a release APK build on pushes to `main` and manual dispatches. Successful builds upload the `studygram-release-apk` artifact.
