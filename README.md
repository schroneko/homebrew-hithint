# HitHint

Keyboard hint clicking and scrolling for macOS, inspired by Hit-a-Hint.

## Install

```bash
brew install --cask schroneko/hithint/hithint
```

## Usage

- Cmd+Shift+Space: show hint labels and click the target by typing its label
- Cmd+Shift+J: scroll mode
- Escape: deactivate

HitHint requires the macOS Accessibility permission. Grant it in System Settings > Privacy & Security > Accessibility on first launch.

## Development

```bash
xcodegen generate
xcodebuild -project HitHint.xcodeproj -scheme HitHint -configuration Release build
```
