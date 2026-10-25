#!/bin/bash
# Build TubeBar.app on the Mac host. Needs Xcode Command Line Tools (swift + codesign).
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/TubeBar"

APP="build/TubeBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/TubeBar"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"     # ad-hoc signature, local use only

echo "Built $APP"
