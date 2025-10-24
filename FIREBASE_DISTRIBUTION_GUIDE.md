# Firebase App Distribution Build Guide

## Quick Start

### Build All Platforms (Android + iOS)
```bash
cd mobile
chmod +x scripts/build_for_firebase.sh
./scripts/build_for_firebase.sh all
```

### Build Android Only
```bash
./scripts/build_for_firebase.sh android
```

### Build iOS Only
```bash
./scripts/build_for_firebase.sh ios
```

---

## What Gets Built

### Android
- **arm64-v8a APK** - 64-bit ARM (most devices)
- **armeabi-v7a APK** - 32-bit ARM (older devices)
- **x86_64 APK** - Intel/x86 emulators and devices
- **Debug Symbols** - For crash reporting/debugging

### iOS
- **XCArchive** - Signed archive ready for TestFlight/App Store
- **Debug Symbols** - For crash reporting

---

## Version Update

### Current Version
```yaml
# mobile/pubspec.yaml
version: 1.0.2+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

### To Release New Version
1. Edit `mobile/pubspec.yaml`:
   ```yaml
   version: 1.0.3+2  # Increment PATCH and BUILD_NUMBER
   ```

2. iOS (if needed):
   ```bash
   cd mobile/ios
   # Update version in Xcode project settings
   # Or edit ios/Runner/Info.plist
   ```

3. Commit to Git:
   ```bash
   git add mobile/pubspec.yaml
   git commit -m "Release v1.0.3 for Firebase App Distribution"
   git push
   ```

---

## Distribution Options

### Firebase App Distribution (Fastest)
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# Create testers.txt
cat > testers.txt << EOF
tester1@example.com
tester2@example.com
EOF

# Distribute Android
firebase appdistribution:distribute build/release/apk/PulseLink-v1.0.3-arm64.apk \
  --app co.za.pulsetek.pulselink \
  --release-notes "Version 1.0.3 - Speed Dating Navigation Fixes" \
  --testers-file testers.txt

# Distribute iOS
firebase appdistribution:distribute build/release/ios/PulseLink-v1.0.3.ipa \
  --app 1:436349093696:ios:eb0ed710c339640c4d1ca5 \
  --release-notes "Version 1.0.3 - Speed Dating Navigation Fixes" \
  --testers-file testers.txt
```

### Google Play Store (Production)
1. Build release APK or App Bundle
2. Upload to Google Play Console
3. Set as staged rollout or full release

### Apple App Store (Production)
1. Build iOS Archive
2. Upload via Xcode or Transporter
3. Configure in App Store Connect

---

## Project Configuration

### Firebase Project ID
`futuristic-app-f7280`

### Android App ID
`1:436349093696:android:50bcdd0c06acd8154d1ca5`
Package: `co.za.pulsetek.pulselink`

### iOS App ID
`1:436349093696:ios:eb0ed710c339640c4d1ca5`
Bundle ID: `co.za.pulsetek.pulselink`

---

## Build Troubleshooting

### Clean Build Required
```bash
flutter clean
rm -rf build/
flutter pub get
```

### Android Build Issues
```bash
# Make gradle executable
chmod +x android/gradlew

# Clear Gradle cache
rm -rf ~/.gradle/caches

# Build again
flutter build apk --release
```

### iOS Build Issues
```bash
# Clean Pods
rm -rf ios/Pods ios/Podfile.lock

# Reinstall
cd ios && pod install && cd ..

# Build again
flutter build ios --release
```

---

## Release Notes Template

```
Version 1.0.3 - October 24, 2025

✨ Features:
- Speed dating event detail navigation improvements
- Fixed scrolling behavior when joining events

🐛 Bug Fixes:
- Fixed navigation going to wrong screen after leaving events
- Fixed page scroll reset when joining speed dating events
- Fixed profile tab synchronization

⚡ Performance:
- Optimized BLoC state management
- Improved navigation responsiveness

📱 Testing:
Please test the following:
- Join speed dating event → should stay on event page
- Leave speed dating event → should return to event list
- Tab switching in profile → should maintain scroll position
```

---

## Monitoring Releases

### Check Tester Distribution
```bash
firebase appdistribution:list --app co.za.pulsetek.pulselink
```

### View Feedback
1. Open Firebase Console
2. Go to App Distribution
3. Check "Feedback" tab for tester comments

### Monitor Crashes
1. Firebase Console → Crashlytics
2. Filter by version
3. Prioritize issues by crash count

---

## Checklist Before Release

- [ ] Version bumped in `pubspec.yaml`
- [ ] CHANGELOG.md updated
- [ ] All tests passing: `flutter test`
- [ ] Linting clean: `flutter analyze`
- [ ] No console warnings or errors
- [ ] Tested on physical device
- [ ] Screenshots/video demos prepared
- [ ] Release notes written
- [ ] Testers list current (testers.txt)
- [ ] Privacy policy compliant
- [ ] All dependencies up to date

---

## Common Commands

```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/

# Generate documentation
dart doc

# Check outdated packages
flutter pub outdated

# Generate APK (single file - NOT recommended)
flutter build apk --release

# Generate App Bundle (recommended for Play Store)
flutter build appbundle --release

# Generate iOS app
flutter build ios --release

# Clean everything
flutter clean && rm -rf build/
```

---

## What Each Build Script Does

1. **Reads version** from `pubspec.yaml`
2. **Cleans** previous builds and Flutter cache
3. **Gets dependencies** with `flutter pub get`
4. **Generates code** (if needed)
5. **Builds APK/IPA** with:
   - Release configuration
   - Obfuscation enabled
   - Debug symbols extracted
   - Sentry error tracking enabled
6. **Organizes output** into `build/release/distribution/`
7. **Creates build info** file with metadata
8. **Generates deployment instructions** for next steps

---

## Build Output Structure

```
build/
├── release/
│   ├── distribution/
│   │   ├── apk/
│   │   │   ├── PulseLink-v1.0.3-arm64.apk
│   │   │   ├── PulseLink-v1.0.3-armv7.apk
│   │   │   └── PulseLink-v1.0.3-x86_64.apk
│   │   ├── ios/
│   │   │   └── PulseLink-v1.0.3.xcarchive
│   │   ├── BUILD_INFO.txt
│   │   └── DEPLOYMENT_INSTRUCTIONS.md
│   └── debug_symbols/
│       ├── android/
│       └── ios/
```

---

## Support

For issues:
1. Check build logs in `build/` directory
2. Review Firebase App Distribution console
3. Check Crashlytics for runtime errors
4. Review tester feedback in Firebase console

