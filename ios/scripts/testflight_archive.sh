#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOS_DIR="${ROOT_DIR}/ios"
BUILD_DIR="${IOS_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/SoberLife.xcarchive"

mkdir -p "${BUILD_DIR}"
rm -rf "${ARCHIVE_PATH}"

echo "Archiving SoberLife for TestFlight..."
xcodebuild \
  -project "${IOS_DIR}/SoberLife.xcodeproj" \
  -scheme "SoberLife" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  archive

echo "Archive complete: ${ARCHIVE_PATH}"
echo "Next: upload with Xcode Organizer or your CI upload lane."

