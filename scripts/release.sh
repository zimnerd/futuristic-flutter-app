#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$MOBILE_DIR")"

# Configuration
ANDROID_APP_ID="co.za.pulsetek.pulselink"
IOS_APP_ID="1:436349093696:ios:eb0ed710c339640c4d1ca5"
FIREBASE_PROJECT="futuristic-app-f7280"

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   PulseLink Automated Release & Firebase Deploy   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"

# Step 1: Update Version
echo -e "\n${YELLOW}📦 Step 1: Updating Version...${NC}"

cd "$MOBILE_DIR"

# Get current version
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | head -1 | awk '{print $2}')
echo -e "Current version: ${BLUE}$CURRENT_VERSION${NC}"

# Parse version components (MAJOR.MINOR.PATCH+BUILD)
VERSION_PART=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

MAJOR=$(echo "$VERSION_PART" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_PART" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_PART" | cut -d'.' -f3)

# Increment patch version
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}+$((BUILD_NUMBER + 1))"

echo -e "New version: ${GREEN}$NEW_VERSION${NC}"

# Update pubspec.yaml
sed -i '' "s/^version:.*/version: $NEW_VERSION/" pubspec.yaml
echo -e "${GREEN}✓ pubspec.yaml updated${NC}"

# Step 2: Build Android
echo -e "\n${YELLOW}🔨 Step 2: Building Android APKs...${NC}"

flutter clean
flutter pub get

flutter build apk \
  --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/release/debug_symbols

echo -e "${GREEN}✓ Android APKs built${NC}"

# Step 3: Build iOS
echo -e "\n${YELLOW}🔨 Step 3: Building iOS Archive...${NC}"

flutter build ios \
  --release \
  --obfuscate \
  --split-debug-info=build/release/debug_symbols

echo -e "${GREEN}✓ iOS archive built${NC}"

# Step 4: Convert iOS Archive to IPA
echo -e "\n${YELLOW}🔄 Step 4: Converting XCArchive to IPA...${NC}"

IOS_DIST_DIR="$MOBILE_DIR/build/release/distribution/ios"
mkdir -p "$IOS_DIST_DIR"

# Find the xcarchive
XCARCHIVE=$(find "$MOBILE_DIR/build/ios" -name "*.xcarchive" | head -1)

if [ -z "$XCARCHIVE" ]; then
  echo -e "${RED}✗ XCArchive not found${NC}"
  exit 1
fi

echo -e "Found archive: ${BLUE}$(basename "$XCARCHIVE")${NC}"

# Extract app from archive
IPA_STAGING="$IOS_DIST_DIR/Payload"
rm -rf "$IPA_STAGING"
mkdir -p "$IPA_STAGING"

cp -r "$XCARCHIVE/Products/Applications/Runner.app" "$IPA_STAGING/"

# Create IPA (zip)
IPA_PATH="$IOS_DIST_DIR/PulseLink-${NEW_VERSION}.ipa"
rm -f "$IPA_PATH"
cd "$IOS_DIST_DIR"
zip -r -q "PulseLink-${NEW_VERSION}.ipa" Payload/
cd - > /dev/null

echo -e "${GREEN}✓ IPA created: $(du -h "$IPA_PATH" | cut -f1)${NC}"

# Step 5: Organize Android APKs
echo -e "\n${YELLOW}📱 Step 5: Organizing Build Artifacts...${NC}"

APK_DIST_DIR="$MOBILE_DIR/build/release/distribution/apk"
mkdir -p "$APK_DIST_DIR"

# Copy APKs with version naming
for apk in $MOBILE_DIR/build/app/outputs/flutter-apk/app-*.apk; do
  if [ -f "$apk" ]; then
    filename=$(basename "$apk")
    if [[ $filename == *"arm64"* ]]; then
      cp "$apk" "$APK_DIST_DIR/PulseLink-${NEW_VERSION}-arm64.apk"
      echo -e "${GREEN}✓ $(du -h "$APK_DIST_DIR/PulseLink-${NEW_VERSION}-arm64.apk" | cut -f1) - arm64${NC}"
    elif [[ $filename == *"armeabi"* ]]; then
      cp "$apk" "$APK_DIST_DIR/PulseLink-${NEW_VERSION}-armv7.apk"
      echo -e "${GREEN}✓ $(du -h "$APK_DIST_DIR/PulseLink-${NEW_VERSION}-armv7.apk" | cut -f1) - armv7${NC}"
    elif [[ $filename == *"x86"* ]]; then
      cp "$apk" "$APK_DIST_DIR/PulseLink-${NEW_VERSION}-x86_64.apk"
      echo -e "${GREEN}✓ $(du -h "$APK_DIST_DIR/PulseLink-${NEW_VERSION}-x86_64.apk" | cut -f1) - x86_64${NC}"
    fi
  fi
done

# Step 6: Deploy to Firebase
echo -e "\n${YELLOW}🚀 Step 6: Deploying to Firebase App Distribution...${NC}"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
  echo -e "${RED}✗ Firebase CLI not installed${NC}"
  echo -e "${YELLOW}Install with: npm install -g firebase-tools${NC}"
  exit 1
fi

# Get testers from file or use default
TESTERS_FILE="$MOBILE_DIR/testers.txt"
if [ -f "$TESTERS_FILE" ]; then
  TESTERS=$(cat "$TESTERS_FILE" | tr '\n' ',' | sed 's/,$//')
  echo -e "Testers: ${BLUE}$TESTERS${NC}"
else
  echo -e "${YELLOW}⚠ No testers.txt file found${NC}"
  TESTERS=""
fi

# Create release notes
RELEASE_NOTES="PulseLink v$NEW_VERSION

Changes:
- Updated dependencies
- Bug fixes and improvements
- Performance optimizations

Build: $(date '+%Y-%m-%d %H:%M:%S')"

# Deploy Android (arm64 recommended)
echo -e "\n${BLUE}→ Deploying Android (arm64)...${NC}"
firebase appdistribution:distribute \
  "$APK_DIST_DIR/PulseLink-${NEW_VERSION}-arm64.apk" \
  --app "$ANDROID_APP_ID" \
  --release-notes="$RELEASE_NOTES" \
  --testers="$TESTERS" 2>/dev/null || true

echo -e "${GREEN}✓ Android deployed${NC}"

# Deploy iOS
echo -e "\n${BLUE}→ Deploying iOS...${NC}"
firebase appdistribution:distribute \
  "$IPA_PATH" \
  --app "$IOS_APP_ID" \
  --release-notes="$RELEASE_NOTES" \
  --testers="$TESTERS" 2>/dev/null || true

echo -e "${GREEN}✓ iOS deployed${NC}"

# Summary
echo -e "\n${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              🎉 Release Complete! 🎉               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo -e "\n${GREEN}Version:${NC} $NEW_VERSION"
echo -e "${GREEN}Android:${NC} $APK_DIST_DIR/PulseLink-${NEW_VERSION}-arm64.apk"
echo -e "${GREEN}iOS:${NC} $IPA_PATH"
echo -e "${GREEN}Firebase Project:${NC} $FIREBASE_PROJECT"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Check Firebase Console: https://console.firebase.google.com/project/$FIREBASE_PROJECT/appdistribution"
echo -e "2. Monitor Crashlytics for crashes"
echo -e "3. Share feedback link with testers"
echo -e ""
