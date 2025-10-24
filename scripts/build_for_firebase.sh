#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Pulse Dating"
BUNDLE_ID="co.za.pulsetek.pulselink"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$BUILD_DIR/release"
DIST_DIR="$RELEASE_DIR/distribution"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  PulseLink Firebase App Distribution${NC}"
echo -e "${BLUE}  Build Script${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to print section headers
print_section() {
  echo -e "\n${BLUE}▶ $1${NC}"
}

# Function to print success messages
print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
  echo -e "${RED}✗ $1${NC}"
  exit 1
}

# Function to print warning messages
print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
  print_error "pubspec.yaml not found. Make sure you're running this from the mobile app directory."
fi

# Parse command line arguments
BUILD_ANDROID=true
BUILD_IOS=true
PLATFORM="${1:-all}"

case $PLATFORM in
  android)
    BUILD_IOS=false
    ;;
  ios)
    BUILD_ANDROID=false
    ;;
  all)
    ;;
  *)
    print_error "Invalid platform: $PLATFORM. Use 'android', 'ios', or 'all'"
    ;;
esac

# Get version from pubspec.yaml
print_section "Reading version information"
VERSION=$(grep "^version:" "$PROJECT_DIR/pubspec.yaml" | awk '{print $2}')
if [ -z "$VERSION" ]; then
  print_error "Could not read version from pubspec.yaml"
fi
print_success "App version: $VERSION"

# Clean previous builds
print_section "Cleaning previous builds"
rm -rf "$BUILD_DIR"
mkdir -p "$DIST_DIR"
print_success "Clean complete"

# Get current date for build info
BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S')
BUILD_TIME=$(date '+%s')
print_success "Build date: $BUILD_DATE"

# Android Build
if [ "$BUILD_ANDROID" = true ]; then
  print_section "Building Android Release APK"
  
  cd "$PROJECT_DIR" || exit
  
  # Clean Flutter
  print_warning "Running flutter clean..."
  flutter clean || print_error "Flutter clean failed"
  
  # Get dependencies
  print_warning "Running flutter pub get..."
  flutter pub get || print_error "Flutter pub get failed"
  
  # Generate Dart code
  print_warning "Running dart run build_runner build..."
  dart run build_runner build --delete-conflicting-outputs 2>/dev/null || print_warning "Build runner skipped (no builders needed)"
  
  # Build APK
  print_warning "Building APK..."
  flutter build apk \
    --release \
    --split-per-abi \
    --obfuscate \
    --split-debug-info="$RELEASE_DIR/debug_symbols" \
    --dart-define=SENTRY_ENABLED=true \
    || print_error "APK build failed"
  
  # Copy APK files
  print_warning "Organizing APK files..."
  mkdir -p "$DIST_DIR/apk"
  cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$DIST_DIR/apk/PulseLink-v${VERSION}-arm64.apk" || print_warning "arm64 APK not found"
  cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$DIST_DIR/apk/PulseLink-v${VERSION}-armv7.apk" || print_warning "armv7 APK not found"
  cp build/app/outputs/flutter-apk/app-x86_64-release.apk "$DIST_DIR/apk/PulseLink-v${VERSION}-x86_64.apk" || print_warning "x86_64 APK not found"
  
  print_success "Android APK build complete"
  ls -lh "$DIST_DIR/apk/"
fi

# iOS Build
if [ "$BUILD_IOS" = true ]; then
  print_section "Building iOS Release Archive"
  
  cd "$PROJECT_DIR" || exit
  
  # Build iOS
  print_warning "Building iOS release..."
  flutter build ios \
    --release \
    --obfuscate \
    --split-debug-info="$RELEASE_DIR/debug_symbols" \
    --dart-define=SENTRY_ENABLED=true \
    || print_error "iOS build failed"
  
  # Create IPA
  print_warning "Creating IPA archive..."
  mkdir -p "$DIST_DIR/ios"
  
  # Navigate to iOS directory and build archive
  cd "ios" || exit
  
  xcodebuild \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath "$DIST_DIR/ios/PulseLink-v${VERSION}.xcarchive" \
    archive \
    || print_error "iOS archive failed"
  
  print_success "iOS archive build complete"
  ls -lh "$DIST_DIR/ios/"
fi

# Create build info file
print_section "Creating build information file"
cat > "$DIST_DIR/BUILD_INFO.txt" << EOF
==========================================
PulseLink - Release Build Information
==========================================

App Name: $APP_NAME
Bundle ID: $BUNDLE_ID
Version: $VERSION
Build Date: $BUILD_DATE
Build Timestamp: $BUILD_TIME

Platforms Built:
EOF

if [ "$BUILD_ANDROID" = true ]; then
  echo "  ✓ Android (APK split by ABI)" >> "$DIST_DIR/BUILD_INFO.txt"
fi

if [ "$BUILD_IOS" = true ]; then
  echo "  ✓ iOS (XCArchive)" >> "$DIST_DIR/BUILD_INFO.txt"
fi

cat >> "$DIST_DIR/BUILD_INFO.txt" << EOF

Output Directory: $DIST_DIR

Next Steps:
1. For Android:
   - Upload APK files to Firebase App Distribution via:
     firebase appdistribution:distribute <APK_PATH> \\
       --app co.za.pulsetek.pulselink \\
       --release-notes "Version $VERSION Release" \\
       --testers-file testers.txt

2. For iOS:
   - Upload XCArchive to TestFlight/Firebase via Xcode or:
     firebase appdistribution:distribute <IPA_PATH> \\
       --app 1:436349093696:ios:eb0ed710c339640c4d1ca5 \\
       --release-notes "Version $VERSION Release" \\
       --testers-file testers.txt

Release Notes Template:
- Features added: ...
- Bugs fixed: ...
- Known issues: ...

==========================================
EOF

print_success "Build information saved to $DIST_DIR/BUILD_INFO.txt"
cat "$DIST_DIR/BUILD_INFO.txt"

# Create deployment instructions
print_section "Creating deployment instructions"
cat > "$DIST_DIR/DEPLOYMENT_INSTRUCTIONS.md" << 'EOF'
# PulseLink Firebase App Distribution Deployment Guide

## Prerequisites
- Firebase CLI installed: `npm install -g firebase-tools`
- Authenticated with Firebase: `firebase login`
- Appropriate signing credentials configured

## Android Deployment

### Option 1: Using Firebase CLI
```bash
firebase appdistribution:distribute build/release/apk/PulseLink-v*.apk \
  --app co.za.pulsetek.pulselink \
  --release-notes "Release notes here" \
  --testers-file testers.txt
```

### Option 2: Using fastlane
```bash
gem install fastlane
cd android
fastlane init
fastlane add_plugin firebase_app_distribution
# Configure fastlane files
fastlane ios distribute
```

## iOS Deployment

### Option 1: TestFlight (Recommended)
1. Open Xcode
2. Product → Archive
3. Organizer → Validate App
4. Upload to App Store Connect

### Option 2: Firebase App Distribution
```bash
firebase appdistribution:distribute build/release/ios/PulseLink-*.ipa \
  --app 1:436349093696:ios:eb0ed710c339640c4d1ca5 \
  --release-notes "Release notes here" \
  --testers-file testers.txt
```

## Testers File Format (testers.txt)
```
tester1@example.com
tester2@example.com
tester3@example.com
```

## Version Management

To update version for next release:
1. Edit `pubspec.yaml`: `version: X.Y.Z+BUILD_NUMBER`
2. Android: Automatically uses version from pubspec
3. iOS: Update in Xcode if needed

## Monitoring

### Check Distribution Status
```bash
firebase appdistribution:list --app co.za.pulsetek.pulselink
```

### View Tester Feedback
- Check Firebase Console → App Distribution → Feedback
- Testers can report issues directly from the app

## Troubleshooting

### Build Fails with "Permission denied"
```bash
chmod +x gradlew
```

### iOS Code Signing Issues
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
```

### Firebase CLI Authentication
```bash
firebase login:ci
```

## Release Checklist
- [ ] Version bumped in pubspec.yaml
- [ ] CHANGELOG.md updated
- [ ] All tests passing locally
- [ ] Lint checks passing
- [ ] Screenshots updated
- [ ] Release notes prepared
- [ ] Testers list updated
- [ ] Build creates without warnings
- [ ] App tested on physical device
- [ ] Privacy policy and terms reviewed
EOF

print_success "Deployment instructions saved"

# Summary
print_section "Build Summary"
echo -e "${GREEN}"
echo "Build completed successfully!"
echo ""
echo "Output Location: $DIST_DIR"
echo ""
if [ "$BUILD_ANDROID" = true ]; then
  echo "Android Files:"
  find "$DIST_DIR/apk" -type f -exec ls -lh {} \; 2>/dev/null || echo "  No APK files found"
fi
if [ "$BUILD_IOS" = true ]; then
  echo "iOS Files:"
  find "$DIST_DIR/ios" -type f -name "*.xcarchive" -exec ls -lh {} \; 2>/dev/null || echo "  No archives found"
fi
echo ""
echo "Next: Review $DIST_DIR/DEPLOYMENT_INSTRUCTIONS.md for deployment steps"
echo -e "${NC}"

print_success "All done! 🎉"
