# Windows Terminal Setup

Second-class citizen — mirrors the macOS/Linux experience as closely as possible but maintained separately.

## Full Install (all tools)

Run from an elevated PowerShell or let winget prompt for UAC:

```powershell
# Core
winget install wez.wezterm
winget install Git.Git
winget install Neovim.Neovim
winget install Starship.Starship

# Modern CLI replacements
winget install sharkdp.bat
winget install sharkdp.fd
winget install eza-community.eza
winget install BurntSushi.ripgrep.MSVC
winget install junegunn.fzf
winget install ajeetdsouza.zoxide
winget install atuinsh.atuin
winget install dbrgn.tealdeer

# TUI apps
winget install jesseduffield.lazygit
winget install sxyazi.yazi
winget install charmbracelet.glow
```

### Fonts

Download and install Hack Nerd Font (required for icons):

```bash
# From Git Bash — downloads and installs to user fonts
curl -sL -o /tmp/Hack.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
mkdir -p /tmp/HackFont && cd /tmp/HackFont && unzip -o /tmp/Hack.zip
powershell.exe -Command "\$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14); Get-ChildItem 'C:\Users\$env:USERNAME\AppData\Local\Temp\HackFont\HackNerdFontMono-*.ttf' | ForEach-Object { \$fonts.CopyHere(\$_.FullName, 0x10) }"
```

## Deploying Configs

```bash
# WezTerm
cp windows/dot_wezterm.lua ~/.wezterm.lua

# Bash (shell aliases, tool integrations, starship prompt)
cp windows/dot_bashrc ~/.bashrc

# Neovim — IMPORTANT: Windows uses AppData/Local/nvim, NOT .config/nvim
mkdir -p ~/AppData/Local/nvim
cp -r dot_config/nvim/* ~/AppData/Local/nvim/

# Starship prompt
mkdir -p ~/.config
cp dot_config/starship.toml ~/.config/starship.toml

# Bootstrap LazyVim plugins (first run downloads everything)
nvim --headless -c 'autocmd User LazyDone quitall'
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
- **Neovim config path**: `~/AppData/Local/nvim/` (not `~/.config/nvim/`)
- **Neovim data path**: `~/AppData/Local/nvim-data/` (not `~/.local/share/nvim/`)
- **Tool discovery**: Checks scoop shims first, then falls back to PATH
- **Project dirs**: `~/Documents/GitHub/` (same relative path, different absolute)
- **Shell config**: `.bashrc` (not `.zshrc`) — same aliases and integrations

### What's identical

- Gruvbox Dark Hard theme + all 10 theme choices
- Tab bar styling and colors
- Workspace model (nvim+Neotree top, terminal+Claude bottom)
- Neovim config (LazyVim + all plugins shared from `dot_config/nvim/`)
- Starship prompt config (shared from `dot_config/starship.toml`)
- Quick select patterns (URLs, paths, hashes, IPs)
- Help overlay (F1)
- All CLI tool aliases (eza, bat, fd, rg, fzf, zoxide, etc.)
- FZF Gruvbox color scheme
- Git aliases

## Keeping in Sync

When the macOS/Linux config (`dot_wezterm.lua`) changes:

1. Check the diff: `git diff master -- dot_wezterm.lua`
2. Apply visual/theme/tab changes directly (they're identical)
3. Translate any new keybindings using the mapping table above
4. Translate any new tool paths (homebrew -> scoop/winget/PATH)

Shared configs (nvim, starship) are used directly from `dot_config/` — just redeploy to the Windows paths.

The Windows config intentionally does NOT share a file with macOS/Linux — platform detection in Lua adds fragility. Two files, kept in sync manually, is more reliable.
