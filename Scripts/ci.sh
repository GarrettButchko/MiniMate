#!/usr/bin/env bash
set -euo pipefail

# 1) Point at the workspace (so Xcode knows about your Swift packages)
WORKSPACE="MiniMate.xcodeproj/project.xcworkspace"
SCHEME="MiniMate"
DERIVED_DATA="DerivedData"

# 2) Resolve Swift-PM dependencies
echo "🔄 Resolving Swift packages…"
xcodebuild \
  -resolvePackageDependencies \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -derivedDataPath "$DERIVED_DATA"

# 3) Build (and test, if you like)
echo "🏗 Building…"
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build