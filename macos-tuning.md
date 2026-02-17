# macOS Memory & Performance Tuning — 8GB MacBook Air

> Scriptable settings are applied by `macos-defaults.sh`.
> This document covers everything: scriptable, GUI-only, and one-time changes.

Applied: 2026-02-15

## Machine
- MacBook Air, 8GB RAM, Apple Silicon
- macOS (Darwin 25.2.0)
- Key constraint: ~1GB free RAM typical

## 1. Orphaned Daemons Removed

| Service | Action | Notes |
|---|---|---|
| `systems.determinate.nix-installer.nix-hook` | `sudo launchctl bootout` + deleted plist | Was actively running, failing with EX_CONFIG (142 runs) |
| `de.appsolute.mampprohelper` | Deleted plist from `/Library/LaunchDaemons/` | Not running, orphan from uninstalled MAMP |
| `us.zoom.ZoomDaemon` | Deleted plist from `/Library/LaunchDaemons/` | Not running |
| `us.zoom.updater` | Deleted plist from `/Library/LaunchAgents/` | |
| `us.zoom.updater.login.check` | Deleted plist from `/Library/LaunchAgents/` | |
| `com.mathworks.mathworksservicehost.agent` | Deleted plist from `~/Library/LaunchAgents/` | MATLAB orphan |

## 2. Updater Daemons Disabled

Unloaded via `launchctl bootout` and disabled via `launchctl disable`. Apps still update manually.

**System daemons (sudo):**
- `com.microsoft.OneDriveStandaloneUpdaterDaemon`
- `com.microsoft.OneDriveUpdaterDaemon`
- `com.microsoft.autoupdate.helper`

**User agents:**
- `com.google.GoogleUpdater.wake`
- `com.google.keystone.agent`
- `com.google.keystone.xpcservice`
- `com.microsoft.OneDriveStandaloneUpdater`
- `com.microsoft.SyncReporter`
- `com.microsoft.update.agent`

**To re-enable any of these:**
```bash
# System daemon example
sudo launchctl enable system/com.microsoft.autoupdate.helper
# Then reboot, or:
sudo launchctl bootstrap system /Library/LaunchDaemons/com.microsoft.autoupdate.helper.plist

# User agent example
launchctl enable gui/$(id -u)/com.google.keystone.agent
# Then reboot, or:
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.google.keystone.agent.plist
```

## 3. Spotlight Exclusions (via System Settings)

**System Settings > Siri & Spotlight > Spotlight Privacy** — added:
- `~/Library` (48 GB)
- `~/Pictures` (14 GB)
- `~/Downloads` (11 GB)
- `~/OneDrive` (3.2 GB)
- `~/Video Projects` (695 MB)
- `~/go` (257 MB)
- `~/Movies` (139 MB)
- `~/ntws`
- `~/Jts`, `~/IBJts`
- `~/META-INF`

**Kept indexed:** `/Applications`, `~/Desktop`, `~/Documents`

## 4. Animation Reduction (defaults write)

```bash
# Window open/close — instant
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Dock minimize — scale effect (fastest)
defaults write com.apple.dock mineffect -string scale

# Dock autohide — instant, no delay
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide-delay -float 0

# Mission Control — near instant
defaults write com.apple.dock expose-animation-duration -float 0.1

# Launchpad — near instant
defaults write com.apple.dock springboard-show-duration -float 0.1
defaults write com.apple.dock springboard-hide-duration -float 0.1

# Finder — all animations off
defaults write com.apple.finder DisableAllAnimations -bool true

# Scroll — snap instead of glide
defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false

# Focus ring — no pulsing
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

# Quick Look — instant panel
defaults write -g QLPanelAnimationDuration -float 0

# Window resize — near instant
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
```

**To revert any animation setting:**
```bash
defaults delete <domain> <key> && killall Dock && killall Finder
# Example:
defaults delete NSGlobalDomain NSScrollAnimationEnabled
```

## 5. Visual Effects (via System Settings)

- **Accessibility > Display > Reduce transparency** — ON
- **Accessibility > Motion > Reduce motion** — ON

These must be set via GUI; `defaults write` doesn't persist on recent macOS.

## 6. Additional Performance Defaults

```bash
# Disable Apple Intelligence (background ML processes)
defaults write com.apple.CloudSubscriptionFeatures.optIn "545129924" -bool false

# Disable screenshot floating thumbnail (holds image buffer ~5s)
defaults write com.apple.screencapture "show-thumbnail" -bool false

# Disable Feedback Assistant autogather
defaults write com.apple.appleseed.FeedbackAssistant "Autogather" -bool false

# Disable Time Machine new disk prompts (stops background disk scanning)
defaults write com.apple.TimeMachine "DoNotOfferNewDisksForBackup" -bool true

# Disable Dock recents section
defaults write com.apple.dock "show-recents" -bool false
```

## 7. Vivaldi Browser Settings (user applied manually)

- **Settings > Performance > Memory Saver** — Maximum Savings
- **Settings > General > Startup** — Lazy Load Restored Tabs enabled
- **Settings > Performance > Network Performance** — Prefetch disabled
- **Settings > Performance > Energy Saver** — Always Save Energy
- **Settings > Performance > Hardware Acceleration** — ON (offloads to GPU)
- **Settings > Tabs > Tab Display > Dim Icon when Hibernated** — enabled
- Extensions reviewed and pruned

## 8. Finder Usability Improvements

```bash
# Path bar — breadcrumb trail at bottom, drag files onto path segments to move them
defaults write com.apple.finder ShowPathbar -bool true

# Status bar — shows item count and disk space at bottom of windows
defaults write com.apple.finder ShowStatusBar -bool true

# List view as default — better for file operations, sorting, multi-select
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv

# Folders always sort above files
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Folders on top on desktop too
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true

# Search defaults to current folder, not entire Mac
defaults write com.apple.finder FXDefaultSearchScope -string SCcf

# Show all file extensions (.pdf, .docx, etc.)
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Draggable folder icon in every window title bar
sudo defaults write com.apple.universalaccess showWindowTitlebarIcons -bool true

# Save dialogs default to local disk, not iCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# No "are you sure?" when renaming file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Auto-empty bin after 30 days
defaults write com.apple.finder FXRemoveOldTrashItems -bool true
```

**To revert any Finder setting:**
```bash
defaults delete com.apple.finder <key> && killall Finder
# Example:
defaults delete com.apple.finder ShowPathbar && killall Finder
```

**Useful Finder shortcuts (built-in, not defaults):**
- **Copy file as full path**: Right-click file > hold `Option` key > "Copy [filename] as Pathname"
- **Cut & paste files (move)**: `Cmd+C` to copy, then `Cmd+Option+V` to move
- **Spring-loaded folders**: Drag file over a folder and hold — folder opens, keep dragging deeper
- **Path bar drag**: Drag files onto any segment of the path bar breadcrumb
- **Title bar icon drag**: Drag the folder icon from title bar into another window, terminal, or dialog

## Services Intentionally Kept

- ZeroTier (actively used)
- Tailscale
- 1Password
- eqMac
- OneDrive sync (only updater daemons disabled)
- Ollama (18MB, negligible)

## Measured Impact

| Metric | Before | After |
|---|---|---|
| System free memory | 1% | 56% (immediately after changes) |
| Vivaldi RSS | 2,443 MB | 1,948 MB (-495 MB) |
| Spotlight RSS | 420 MB | 319 MB (-101 MB) |
| Swap usage | 0 | 0 |

Full savings will compound after reboot (updater daemons won't re-launch, Apple Intelligence processes stop).
