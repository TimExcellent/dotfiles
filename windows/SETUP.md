# Windows Terminal Setup

Second-class citizen — mirrors the macOS/Linux experience as closely as possible but maintained separately.

## Prerequisites

Install via winget (recommended):

```powershell
winget install wez.wezterm
winget install Git.Git
winget install Starship.Starship
```

### Fonts

Install Hack Nerd Font (required for icons):

```powershell
# Option 1: via scoop
scoop bucket add nerd-fonts
scoop install Hack-NF-Mono

# Option 2: manual download from https://www.nerdfonts.com/font-downloads
# Install "Hack Nerd Font" — the Mono variant
```

### Optional TUI tools

```powershell
winget install jesseduffield.lazygit
winget install sxyazi.yazi
scoop install btop
winget install Neovim.Neovim
```

## Installation

Copy the WezTerm config to your home directory:

```powershell
copy windows\dot_wezterm.lua %USERPROFILE%\.wezterm.lua
```

Or from Git Bash:

```bash
cp windows/dot_wezterm.lua ~/.wezterm.lua
```

## What's Different from macOS/Linux

### Keybinding mapping

| macOS | Windows | Action |
|-------|---------|--------|
| `CMD+T` | `ALT+T` | New tab |
| `CMD+W` | `ALT+W` | Close pane |
| `CMD+1-9` | `ALT+1-9` | Switch tabs |
| `CMD+D` | `ALT+D` | Split horizontal |
| `CMD+SHIFT+D` | `ALT+SHIFT+D` | Split vertical |
| `CMD+OPT+hjkl` | `CTRL+ALT+hjkl` | Navigate panes |
| `CMD+OPT+SHIFT+HJKL` | `CTRL+ALT+SHIFT+HJKL` | Resize panes |
| `CMD+Z` | `ALT+Z` | Zoom pane |
| `CMD+SHIFT+C` | `CTRL+SHIFT+C` | Claude Code pane |
| `CMD+SHIFT+P` | `CTRL+SHIFT+P` | Project switcher |
| `CMD+SHIFT+W` | `CTRL+SHIFT+W` | Workspace switcher |
| `CMD+SHIFT+G` | `CTRL+SHIFT+G` | lazygit |
| `CMD+SHIFT+Y` | `CTRL+SHIFT+Y` | yazi |
| `CMD+SHIFT+B` | `CTRL+SHIFT+B` | btop |
| `CMD+SHIFT+Enter` | `CTRL+SHIFT+Enter` | Terminal split below |
| `F1` | `F1` | Help overlay |

### Other differences

- **Default shell**: Git Bash (not zsh) — closest POSIX experience on Windows
- **Font size**: 12pt (vs 14pt on macOS) — Windows DPI scaling is different
- **Tool discovery**: Checks scoop shims first, then falls back to PATH
- **Project dirs**: `~/Documents/GitHub/` (same relative path, different absolute)
- **Removed**: Nushell launcher, lazydocker, visidata (not typically available on Windows)

### What's identical

- Gruvbox Dark Hard theme + all 10 theme choices
- Tab bar styling and colors
- Workspace model (project switcher, Claude Code split)
- Quick select patterns (URLs, paths, hashes, IPs)
- Help overlay (F1)
- Status bar (workspace indicator)

## Keeping in Sync

When the macOS/Linux config (`dot_wezterm.lua`) changes:

1. Check the diff: `git diff master -- dot_wezterm.lua`
2. Apply visual/theme/tab changes directly (they're identical)
3. Translate any new keybindings using the mapping table above
4. Translate any new tool paths (homebrew -> scoop/winget/PATH)

The Windows config intentionally does NOT share a file with macOS/Linux — platform detection in Lua adds fragility. Two files, kept in sync manually, is more reliable.
