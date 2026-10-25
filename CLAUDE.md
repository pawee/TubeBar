# TubeBar

Personal macOS menu bar app: YouTube + YouTube Music in a hotkey-toggled floating panel.
Goal: no Dock icon, not in ⌘-Tab, no stray windows; playback continues while hidden.

## Rules
- Native AppKit + WebKit only, no third-party dependencies.
- Swift package (no .xcodeproj). Build on the Mac host with `./build.sh` (needs Command Line Tools).
- App runs as an agent (`LSUIElement`); keep it that way.
- Hotkeys use physical key codes (user types Colemak and Thai).

## Layout
- `Sources/TubeBar/TubeBarApp.swift` — entry point
- `Sources/TubeBar/AppDelegate.swift` — status item, menus, hotkey, login item
- `Sources/TubeBar/PlayerController.swift` — panel, web views, show/hide, pin
- `Sources/TubeBar/HotKey.swift` — Carbon global hotkey
- `Info.plist`, `build.sh` — app bundle packaging
