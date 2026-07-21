#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
APP_NAME="SolatNotch"
BUNDLE_ID="my.takukku.SolatNotch.dev4"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$HOME/Applications"
APP_BUNDLE="$INSTALL_DIR/$APP_NAME.app"
SCRATCH_DIR="$HOME/Library/Caches/TakukkuBuild"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
cd "$ROOT_DIR"
swift build --scratch-path "$SCRATCH_DIR"
BUILD_DIR="$(swift build --scratch-path "$SCRATCH_DIR" --show-bin-path)"
mkdir -p "$INSTALL_DIR"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
find "$BUILD_DIR" -maxdepth 1 -type d -name '*.bundle' -exec cp -R {} "$APP_BUNDLE/Contents/Resources/" \;
# SwiftPM's generated Bundle.module accessor checks directly beside the app
# bundle before falling back to the build folder. Keep a copy there so the
# installed app never needs access to the source directory in Downloads.
find "$BUILD_DIR" -maxdepth 1 -type d -name '*.bundle' -exec cp -R {} "$APP_BUNDLE/" \;
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
/usr/libexec/PlistBuddy -c 'Clear dict' "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" -c "Add :CFBundleIdentifier string $BUNDLE_ID" -c "Add :CFBundleName string 'Solat Notch'" -c 'Add :CFBundlePackageType string APPL' -c 'Add :LSMinimumSystemVersion string 14.0' -c 'Add :NSPrincipalClass string NSApplication' -c 'Add :LSUIElement bool false' -c 'Add :NSLocationWhenInUseUsageDescription string Solat Notch uses your approximate location only to suggest a Malaysian prayer zone for your confirmation.' -c 'Add :NSLocationAlwaysUsageDescription string Solat Notch keeps an approximate location suggestion current when live location is enabled.' "$APP_BUNDLE/Contents/Info.plist"
open_app() { (cd / && /usr/bin/open -n "$APP_BUNDLE"); }
case "$MODE" in
  run) open_app ;;
  --debug|debug) lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  --logs|logs) open_app; /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\"" ;;
  --telemetry|telemetry) open_app; /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\"" ;;
  --verify|verify) open_app; sleep 2; pgrep -x "$APP_NAME" >/dev/null ;;
  *) echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac
