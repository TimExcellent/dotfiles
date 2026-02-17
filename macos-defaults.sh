#!/usr/bin/env bash
#
# macOS System Defaults
# Idempotent — safe to re-run. Applies scriptable macOS customizations.
# For GUI-only and one-time settings, see macos-tuning.md.
#
# Usage: bash macos-defaults.sh

set -euo pipefail

# Keep sudo alive for the duration of the script
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# Animation Reduction                                                         #
###############################################################################

# Window open/close — instant
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Dock minimize — scale effect (fastest built-in option)
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

###############################################################################
# Performance                                                                 #
###############################################################################

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

###############################################################################
# Finder Usability                                                            #
###############################################################################

# Path bar — breadcrumb trail at bottom
defaults write com.apple.finder ShowPathbar -bool true

# Status bar — item count and disk space
defaults write com.apple.finder ShowStatusBar -bool true

# List view as default
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv

# Folders always sort above files
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true

# Search defaults to current folder, not entire Mac
defaults write com.apple.finder FXDefaultSearchScope -string SCcf

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Draggable folder icon in every window title bar
sudo defaults write com.apple.universalaccess showWindowTitlebarIcons -bool true

# Save dialogs default to local disk, not iCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# No warning when renaming file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Auto-empty bin after 30 days
defaults write com.apple.finder FXRemoveOldTrashItems -bool true

###############################################################################
# Updater Daemons                                                             #
###############################################################################

# Microsoft — system daemons
sudo launchctl disable system/com.microsoft.OneDriveStandaloneUpdaterDaemon 2>/dev/null || true
sudo launchctl disable system/com.microsoft.OneDriveUpdaterDaemon 2>/dev/null || true
sudo launchctl disable system/com.microsoft.autoupdate.helper 2>/dev/null || true

# Microsoft — user agents
launchctl disable "gui/$(id -u)/com.microsoft.OneDriveStandaloneUpdater" 2>/dev/null || true
launchctl disable "gui/$(id -u)/com.microsoft.SyncReporter" 2>/dev/null || true
launchctl disable "gui/$(id -u)/com.microsoft.update.agent" 2>/dev/null || true

# Google — user agents
launchctl disable "gui/$(id -u)/com.google.GoogleUpdater.wake" 2>/dev/null || true
launchctl disable "gui/$(id -u)/com.google.keystone.agent" 2>/dev/null || true
launchctl disable "gui/$(id -u)/com.google.keystone.xpcservice" 2>/dev/null || true

###############################################################################
# Apply Changes                                                               #
###############################################################################

killall Dock && killall Finder && killall SystemUIServer

echo "macOS defaults applied. Some changes may require logout/reboot."
