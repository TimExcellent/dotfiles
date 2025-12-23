# Claude AI Assistant Guide for Terminal Environment

## Environment Overview

**Platform**: macOS (Darwin)
**Terminal**: WezTerm with Gruvbox theme
**Shells**: zsh (primary), Nushell (data processing)
**Editor**: Neovim with LazyVim
**Prompt**: Starship (Gruvbox colors)
**Dotfiles Manager**: chezmoi

## Quick Reference

### Command Discovery (Your Main Tools)

| Need | Command | Description |
|------|---------|-------------|
| Forgot a command | `navi` or `Ctrl+G` | Interactive cheatsheet search |
| Quick syntax help | `tldr <command>` | Simplified man pages |
| Find past commands | `Ctrl+R` | Atuin fuzzy history search |
| In Neovim | `<Space>` | which-key shows all keybindings |

### Modern CLI Tools

| Old | New | Usage |
|-----|-----|-------|
| `ls` | `eza` | `ll` (long), `lt` (tree), `la` (all) |
| `cat` | `bat` | Syntax highlighting, line numbers |
| `find` | `fd` | `fd readme` finds README files |
| `grep` | `rg` | `rg 'pattern'` searches fast |
| `cd` | `z` | `z proj` jumps to project dir, `zi` interactive |

### Navigation

```bash
z <partial-name>   # Smart cd (learns directories)
zi                 # Interactive directory picker
..                 # Go up one level
...                # Go up two levels
vf                 # Fuzzy find and open file in nvim
```

### AI Integration

- **Claude Code**: Run `claude` in terminal for AI assistance
- **avante.nvim**: In Neovim, `<Space>aa` to ask AI, `<Space>ae` to edit with AI
- **navi**: Cheatsheets without API costs

## File Locations

### Managed by chezmoi

| Source (dotfiles repo) | Target |
|------------------------|--------|
| `dot_wezterm.lua` | `~/.wezterm.lua` |
| `dot_zshrc` | `~/.zshrc` |
| `dot_config/starship.toml` | `~/.config/starship.toml` |

### Neovim (LazyVim)

| File | Purpose |
|------|---------|
| `~/.config/nvim/lua/plugins/colorscheme.lua` | Gruvbox + theme switching |
| `~/.config/nvim/lua/plugins/avante.lua` | AI integration |
| `~/.config/nvim/lua/plugins/markdown.lua` | Markdown + Zen mode |

### Nushell

| File | Purpose |
|------|---------|
| `~/Library/Application Support/nushell/config.nu` | Main config |
| `~/Library/Application Support/nushell/zoxide.nu` | Smart cd |

## Making Changes

### Edit dotfiles

```bash
chezmoi edit ~/.zshrc        # Edit in repo
chezmoi apply                 # Apply to home
chezmoi diff                  # Preview changes
```

### Update configs after editing

```bash
reload                        # Reload zsh
# For WezTerm: Cmd+Shift+R reloads config
# For Neovim: :Lazy sync updates plugins
```

## Key Bindings

### WezTerm

| Key | Action |
|-----|--------|
| `Ctrl+Shift+T` | Theme switcher |
| `Cmd+D` | Split horizontally |
| `Cmd+Shift+D` | Split vertically |
| `Cmd+Opt+h/j/k/l` | Navigate panes (Vim-style) |
| `Cmd+1-9` | Switch tabs |
| `Cmd+z` | Zoom pane |
| `Cmd+Shift+N` | Open Nushell in new tab |

### Neovim (LazyVim)

| Key | Action |
|-----|--------|
| `<Space>` | Show all keybindings (which-key) |
| `<Space>ff` | Find files |
| `<Space>fg` | Find in files (grep) |
| `<Space>fb` | Find buffers |
| `<Space>aa` | Ask AI (avante) |
| `<Space>ae` | Edit with AI |
| `<Space>z` | Zen mode (distraction-free) |

## Troubleshooting

### Tool not found

```bash
brew list                     # Check installed packages
which <tool>                  # Find tool location
```

### Config not loading

```bash
chezmoi status               # Check chezmoi state
chezmoi apply --force        # Force apply
source ~/.zshrc              # Reload zsh
```

### Neovim plugins issues

```bash
nvim                         # Open Neovim
:Lazy                        # Open plugin manager
:Lazy sync                   # Update plugins
:checkhealth                 # Run health checks
```

## Installed Tools

**Core**: wezterm, starship, nushell, neovim (lazyvim)
**Modern CLI**: eza, bat, fd, ripgrep, zoxide, fzf, atuin, navi, tldr
**AI**: claude-code, avante.nvim

---

**Last Updated**: December 2025
