#!/bin/bash

# Firebase App Distribution Deployment Script
# Automates uploading built APKs/IPAs to Firebase App Distribution

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$PROJECT_DIR/build/release/distribution"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Firebase App Distribution Deployer${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
  echo -e "${RED}✗ Firebase CLI not found${NC}"
  echo "Install with: npm install -g firebase-tools"
  exit 1
fi

# Check if logged in
if ! firebase projects:list &> /dev/null; then
  echo -e "${YELLOW}Not logged in to Firebase${NC}"
  echo "Running: firebase login"
  firebase login
fi

# Check if testers file exists
if [ ! -f "$PROJECT_DIR/testers.txt" ]; then
  echo -e "${YELLOW}⚠ testers.txt not found${NC}"
  echo "Creating template..."
  cat > "$PROJECT_DIR/testers.txt" << 'EOF'
# Add tester email addresses here, one per line
# Example:
# tester1@example.com
# tester2@example.com
EOF
  echo -e "${YELLOW}Please edit testers.txt and add email addresses${NC}"
  exit 1
fi

# Check for build artifacts
if [ ! -d "$DIST_DIR" ]; then
  echo -e "${RED}✗ Build artifacts not found in $DIST_DIR${NC}"
  echo "Run: ./scripts/build_for_firebase.sh all"
  exit 1
fi

# Get version
VERSION=$(grep "^version:" "$PROJECT_DIR/pubspec.yaml" | awk '{print $2}')
echo -e "${GREEN}✓ Version: $VERSION${NC}"

# Prepare release notes
RELEASE_NOTES_FILE="$DIST_DIR/release_notes.txt"
if [ ! -f "$RELEASE_NOTES_FILE" ]; then
  cat > "$RELEASE_NOTES_FILE" << EOF
Version $VERSION Release

Bug Fixes:
- Speed Dating navigation improvements
- Fixed scrolling behavior when joining events
- Fixed profile tab synchronization
- Fixed premium subscription UI visibility

Enhancements:
- Improved state management for real-time features
- Better error handling in API calls

Testing Notes:
Please test the following features:
1. Join a speed dating event
2. Leave a speed dating event
3. Navigate between profile tabs
4. Premium subscription management

Send feedback via the app's feedback feature.
EOF
fi

# Function to deploy platform
deploy_platform() {
  local platform=$1
  local app_id=$2
  local file_pattern=$3
  local file_path=$(find "$DIST_DIR" -name "$file_pattern" | head -n1)
  
  if [ -z "$file_path" ]; then
    echo -e "${YELLOW}⚠ No $platform artifacts found (pattern: $file_pattern)${NC}"
    return
  fi
  
  echo -e "\n${BLUE}▶ Deploying $platform${NC}"
  echo -e "  File: $(basename "$file_path")"
  echo -e "  Size: $(du -h "$file_path" | cut -f1)"
  
  # Show release notes
  echo -e "  ${YELLOW}Release Notes:${NC}"
  head -n 5 "$RELEASE_NOTES_FILE" | sed 's/^/    /'
  
  read -p "  Continue with deployment? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠ Skipped $platform deployment${NC}"
    return
  fi
  
  echo -e "  ${YELLOW}Uploading...${NC}"
  
  if firebase appdistribution:distribute "$file_path" \
    --app "$app_id" \
    --release-notes-file "$RELEASE_NOTES_FILE" \
    --testers-file "$PROJECT_DIR/testers.txt"; then
    echo -e "${GREEN}✓ $platform deployment successful${NC}"
  else
    echo -e "${RED}✗ $platform deployment failed${NC}"
    return 1
  fi
}

# Check which platforms are available
has_android=false
has_ios=false

if find "$DIST_DIR/apk" -name "*.apk" &> /dev/null 2>&1; then
  has_android=true
fi

if find "$DIST_DIR/ios" -name "*.ipa" &> /dev/null 2>&1; then
  has_ios=true
fi

if [ "$has_android" = false ] && [ "$has_ios" = false ]; then
  echo -e "${RED}✗ No Android APK or iOS IPA found${NC}"
  echo "Expected:"
  echo "  - $DIST_DIR/apk/*.apk"
  echo "  - $DIST_DIR/ios/*.ipa"
  exit 1
fi

# Deploy selected platforms
echo -e "\n${BLUE}Available Platforms:${NC}"
[ "$has_android" = true ] && echo -e "  ${GREEN}✓ Android${NC}" || echo -e "  ${RED}✗ Android${NC}"
[ "$has_ios" = true ] && echo -e "  ${GREEN}✓ iOS${NC}" || echo -e "  ${RED}✗ iOS${NC}"

read -p "Which platform to deploy? (android/ios/both): " platform

case $platform in
  android)
    deploy_platform "Android" "co.za.pulsetek.pulselink" "apk/PulseLink-v*-arm64.apk"
    ;;
  ios)
    deploy_platform "iOS" "1:436349093696:ios:eb0ed710c339640c4d1ca5" "ios/PulseLink-v*.ipa"
    ;;
  both)
    deploy_platform "Android" "co.za.pulsetek.pulselink" "apk/PulseLink-v*-arm64.apk"
    deploy_platform "iOS" "1:436349093696:ios:eb0ed710c339640c4d1ca5" "ios/PulseLink-v*.ipa"
    ;;
  *)
    echo -e "${RED}Invalid choice${NC}"
    exit 1
    ;;
esac

# Check distribution status
echo -e "\n${BLUE}▶ Distribution Status${NC}"

read -p "Check distribution status? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  firebase appdistribution:list --app co.za.pulsetek.pulselink
fi

echo -e "\n${GREEN}Deployment workflow complete! 🎉${NC}"
echo -e "\nNext Steps:"
echo -e "  1. Monitor: Firebase Console → App Distribution"
echo -e "  2. Feedback: Check tester feedback in the console"
echo -e "  3. Crashes: Monitor Crashlytics for any crash reports"
echo -e "  4. Iterate: Make updates and redeploy as v$(echo $VERSION | awk -F+ '{print $1}').X"
