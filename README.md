# HitHint

Keyboard hint clicking and scrolling for macOS, inspired by Hit-a-Hint.

## Install

```bash
brew install --cask schroneko/hithint/hithint
```

## Usage

- Cmd+Shift+Space: show hint labels and click the target by typing its label
- Cmd+Shift+J: scroll mode
- Scroll mode keys: h / j / k / l or arrow keys to scroll, d / u for half page, g / G for top / bottom, Shift for faster scrolling, 1-9 or Tab / Shift+Tab to switch scroll areas
- Escape, mouse click, or switching apps: deactivate
- Menu bar HH > Settings...: drag apps in from Finder to exclude them, and toggle launch at login

HitHint requires the macOS Accessibility permission. Grant it in System Settings > Privacy & Security > Accessibility on first launch.

## Development

```bash
xcodegen generate
xcodebuild -project HitHint.xcodeproj -scheme HitHint -configuration Release build
```
