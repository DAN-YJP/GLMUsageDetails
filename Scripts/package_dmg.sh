#!/bin/zsh
set -euo pipefail

APP_NAME="GlmUsageDetails"
PROJECT="UsageMonitorApp.xcodeproj"
SCHEME="UsageMonitorApp"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-.xcode/DerivedData}"
SOURCE_PACKAGES="${SOURCE_PACKAGES:-.xcode/SourcePackages}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
DMG_NAME="${DMG_NAME:-${APP_NAME}-${CONFIGURATION}.dmg}"
STAGING_DIR="${DERIVED_DATA}/dmg-staging"
APP_PATH="${DERIVED_DATA}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}"

mkdir -p "${OUTPUT_DIR}"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
mkdir -p "${DERIVED_DATA}/Build/Products/${CONFIGURATION}/GRDB_GRDB.bundle"

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${DERIVED_DATA}" \
  -clonedSourcePackagesDirPath "${SOURCE_PACKAGES}" \
  PRODUCT_NAME="${APP_NAME}" \
  CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED}" \
  build

cp -R "${APP_PATH}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

rm -f "${DMG_PATH}"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "${DMG_PATH}"
