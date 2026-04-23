#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/debug"
APP_NAME="MiddleClickScroll"
DIST_DIR="$ROOT_DIR/Dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE_PATH="$BUILD_DIR/$APP_NAME"
CACHE_HOME="$ROOT_DIR/.build/cache-home"
MODULE_CACHE_DIR="$ROOT_DIR/.build/ModuleCache.noindex"
SWIFTPM_CACHE_DIR="$ROOT_DIR/.build/swiftpm-cache"
ICON_MASTER_PATH="$ROOT_DIR/Resources/AppIcon-master.png"
STATUS_ICON_PATH="$ROOT_DIR/Resources/StatusBarIcon.png"
ICONSET_DIR="$ROOT_DIR/.build/AppIcon.iconset"
ICON_FILE_NAME="AppIcon"

BUILD_ONLY=0
if [[ "${1:-}" == "--build-only" ]]; then
  BUILD_ONLY=1
fi

echo "Building $APP_NAME..."
mkdir -p "$CACHE_HOME" "$MODULE_CACHE_DIR" "$SWIFTPM_CACHE_DIR"
HOME="$CACHE_HOME" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
swift build --product "$APP_NAME" --cache-path "$SWIFTPM_CACHE_DIR"

mkdir -p "$DIST_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"

if [[ -f "$STATUS_ICON_PATH" ]]; then
  cp "$STATUS_ICON_PATH" "$RESOURCES_DIR/StatusBarIcon.png"
fi

if [[ -f "$ICON_MASTER_PATH" ]]; then
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"

  sips -z 16 16 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_MASTER_PATH" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  cp "$ICON_MASTER_PATH" "$ICONSET_DIR/icon_512x512@2x.png"

  iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/$ICON_FILE_NAME.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MiddleClickScroll</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.philipkiulpekidis.MiddleClickScroll</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MiddleClickScroll</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "App bundle ready at:"
echo "  $APP_DIR"

if [[ "$BUILD_ONLY" -eq 1 ]]; then
  exit 0
fi

echo "Launching app bundle..."
exec open "$APP_DIR"
