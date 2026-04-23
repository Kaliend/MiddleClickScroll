# MiddleClickScroll

Windows-style middle-click auto-scroll for macOS.

MiddleClickScroll brings Windows-style middle-click auto-scroll to macOS.

Press the middle mouse button once to enter auto-scroll mode, move the pointer up or down to scroll smoothly, and click again to stop. The app includes a configurable scroll engine, a global overlay indicator, a menu bar item, optional launch-at-login, and a DMG builder for distribution.

## Features

- Global middle-click auto-scroll on macOS
- Smooth pixel-based scrolling with tunable speed, acceleration, and smoothing
- Configurable dead zone, horizontal scrolling, inversion, and frame rate
- Global visual overlay for active auto-scroll state
- Optional menu bar item
- Optional launch at login
- DMG packaging script with installer window layout

## Requirements

- macOS 14 or newer
- Apple Silicon Mac recommended
- Accessibility permission enabled for the app

## Build

```bash
swift build
```

## Run As App Bundle

```bash
./run_as_app_bundle.sh
```

This creates a local `.app` bundle in `Dist/` and launches it.

## Build DMG

```bash
./scripts/build_dmg.sh
```

This creates:

- `Dist/MiddleClickScroll.app`
- `Dist/MiddleClickScroll.dmg`

## Installation Notes

Because the app is currently unsigned and not notarized, macOS Gatekeeper may block the first launch on another Mac.

Recommended install flow:

1. Drag `MiddleClickScroll.app` to `Applications`
2. Remove quarantine:

```bash
xattr -dr com.apple.quarantine /Applications/MiddleClickScroll.app
```

3. Launch:

```bash
open /Applications/MiddleClickScroll.app
```

On first run, grant Accessibility access in System Settings so the app can intercept the middle mouse button and generate synthetic scroll events.

## Project Structure

- `Sources/MiddleClickScrollApp/` — app source code
- `Resources/` — app icon and status bar icon assets
- `scripts/build_dmg.sh` — DMG packaging script
- `run_as_app_bundle.sh` — local app bundle builder/launcher

## Version

Version 0.1.0

Vibecoded by Philip A. Kiulpekidis.
