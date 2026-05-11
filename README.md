# ImeLock

A macOS input method locker. Locks the current input method to prevent accidental switching across apps.

## Install

### Homebrew (recommended)

```bash
brew tap dreamor/tap
brew install --cask imelock
```

> On first launch, right-click ImeLock.app and select "Open" to bypass Gatekeeper.

### Manual

Download the latest release from [Releases](https://github.com/dreamor/ImeLock/releases), unzip, and drag `ImeLock.app` to `/Applications`.

## Usage

The app runs in the menu bar only — no Dock icon.

| Menu bar icon | Meaning |
|---|---|
| Closed lock | Input method locked |
| Open lock | Input method unlocked |

- **Lock/Unlock**: Click the menu bar icon, then click "Lock" or "Unlock"
- **Switch input method**: Click the menu bar icon and pick from the list; if locked, it re-locks to the new selection
- **Launch at login**: Click the menu bar icon, check "Launch at Login"
- **Quit**: Right-click the menu bar icon, select "Quit"

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac

## Acknowledgements

Inspired by [SwitchKey](https://github.com/itsuhane/SwitchKey) by itsuhane

## License

GPL-3.0