#!/bin/bash
# The build gate: generate the project, then build the Mac app and the iPhone
# simulator app. A fresh checkout works because generation is the first step.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is missing: run 'brew install xcodegen' and try again." >&2
    exit 1
fi

xcodegen generate --quiet

xcodebuild -project StoreSim.xcodeproj -scheme StoreSim_macOS -destination 'platform=macOS' \
    -configuration Debug -derivedDataPath .build/DerivedData build -quiet

xcodebuild -project StoreSim.xcodeproj -scheme StoreSim_iOS -destination 'platform=iOS Simulator,name=iPhone 16' \
    -configuration Debug -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build -quiet

echo "build: ok (Mac app under .build/DerivedData/Build/Products/Debug/, simulator app under Debug-iphonesimulator/)"
