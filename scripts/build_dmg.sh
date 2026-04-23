#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MiddleClickScroll"
VOLUME_NAME="Install $APP_NAME"
DIST_DIR="$ROOT_DIR/Dist"
APP_PATH="$DIST_DIR/$APP_NAME.app"
DMG_ROOT="$ROOT_DIR/.build/dmg"
STAGING_DIR="$DMG_ROOT/staging"
RW_DMG="$DMG_ROOT/$APP_NAME-temp.dmg"
FINAL_DMG="$DIST_DIR/$APP_NAME.dmg"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_PATH="$BACKGROUND_DIR/InstallerBackground.png"
CACHE_HOME="$ROOT_DIR/.build/cache-home"
MODULE_CACHE_DIR="$ROOT_DIR/.build/ModuleCache.noindex"

"$ROOT_DIR/run_as_app_bundle.sh" --build-only

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR" "$BACKGROUND_DIR" "$DIST_DIR" "$CACHE_HOME" "$MODULE_CACHE_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

BACKGROUND_PATH="$BACKGROUND_PATH" \
HOME="$CACHE_HOME" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
swift - <<'SWIFT'
import AppKit
import Foundation

let outputPath = ProcessInfo.processInfo.environment["BACKGROUND_PATH"]!
let size = NSSize(width: 640, height: 460)
let image = NSImage(size: size)
image.lockFocus()

let background = NSColor(calibratedRed: 0.93, green: 0.96, blue: 0.99, alpha: 1.0)
background.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

let accent = NSColor(calibratedRed: 0.16, green: 0.45, blue: 0.93, alpha: 1.0)
let secondary = NSColor(calibratedWhite: 0.25, alpha: 1.0)
let tertiary = NSColor(calibratedWhite: 0.55, alpha: 1.0)

let title = "Install MiddleClickScroll"
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 30, weight: .semibold),
    .foregroundColor: secondary
]
title.draw(at: NSPoint(x: 36, y: 334), withAttributes: titleAttrs)

let subtitle = "Drag the app to Applications to install it."
let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 16, weight: .regular),
    .foregroundColor: tertiary
]
subtitle.draw(at: NSPoint(x: 38, y: 300), withAttributes: subtitleAttrs)

let line = NSBezierPath()
line.move(to: NSPoint(x: 222, y: 220))
line.line(to: NSPoint(x: 410, y: 220))
line.lineWidth = 10
accent.setStroke()
line.stroke()

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 410, y: 250))
arrow.line(to: NSPoint(x: 470, y: 220))
arrow.line(to: NSPoint(x: 410, y: 190))
arrow.close()
accent.setFill()
arrow.fill()

let hint = "Open the app once after install and grant Accessibility access."
let hintAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: secondary
]
hint.draw(at: NSPoint(x: 38, y: 76), withAttributes: hintAttrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render DMG background")
}

try png.write(to: URL(fileURLWithPath: outputPath))
SWIFT

rm -f "$RW_DMG" "$FINAL_DMG"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -fs HFS+ \
  -format UDRW \
  "$RW_DMG" >/dev/null

DEVICE_INFO="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG")"
DEVICE="$(echo "$DEVICE_INFO" | awk '/Apple_HFS/ {print $1}')"
MOUNT_POINT="$(echo "$DEVICE_INFO" | sed -n 's#^/dev/[^[:space:]]*[[:space:]]*Apple_HFS[[:space:]]*##p' | tail -n 1)"
DISK_NAME="$(basename "$MOUNT_POINT")"

cleanup() {
  if mount | grep -q "$MOUNT_POINT"; then
    hdiutil detach "$DEVICE" -force >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

touch "$MOUNT_POINT/.DS_Store"
SetFile -a V "$MOUNT_POINT/.DS_Store" || true
SetFile -a V "$MOUNT_POINT/.background" || true

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$DISK_NAME"
    open
    delay 1
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {120, 120, 760, 580}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set text size of viewOptions to 14
    set background picture of viewOptions to file ".background:InstallerBackground.png"
    set position of item "$APP_NAME.app" of container window to {170, 220}
    set position of item "Applications" of container window to {470, 220}
    update without registering applications
    delay 2
    close
    open
    update without registering applications
    delay 3
    close
  end tell
end tell
APPLESCRIPT

sync
sleep 2
hdiutil detach "$DEVICE" >/dev/null
trap - EXIT

hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG" >/dev/null
rm -f "$RW_DMG"

echo "DMG ready at:"
echo "  $FINAL_DMG"
