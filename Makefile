APP_NAME := GlmUsageDetails
PROJECT := UsageMonitorApp.xcodeproj
SCHEME := UsageMonitorApp
CONFIGURATION ?= Debug
DERIVED_DATA := .xcode/DerivedData
SOURCE_PACKAGES := .xcode/SourcePackages
APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/$(APP_NAME).app
INSTALL_DIR ?= $(HOME)/Applications
OUTPUT_DIR ?= dist
DMG_NAME ?= $(APP_NAME)-$(CONFIGURATION).dmg
CODE_SIGNING_ALLOWED ?= NO

.PHONY: build run install package dmg clean test

build:
	@mkdir -p $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/GRDB_GRDB.bundle
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -derivedDataPath $(DERIVED_DATA) -clonedSourcePackagesDirPath $(SOURCE_PACKAGES) PRODUCT_NAME=$(APP_NAME) CODE_SIGNING_ALLOWED=$(CODE_SIGNING_ALLOWED) build

run: build
	open $(APP_PATH)

install: build
	mkdir -p $(INSTALL_DIR)
	cp -R $(APP_PATH) $(INSTALL_DIR)/$(APP_NAME).app

package:
	CONFIGURATION=Release OUTPUT_DIR=$(OUTPUT_DIR) CODE_SIGNING_ALLOWED=$(CODE_SIGNING_ALLOWED) ./Scripts/package_dmg.sh

dmg: package

clean:
	rm -rf .build $(DERIVED_DATA) $(SOURCE_PACKAGES)

test:
	swift test
