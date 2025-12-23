# Terminal Setup Cheat Sheet

Quick reference for all shortcuts, commands, and examples.

---

## 🖥️ WezTerm Shortcuts

### Window Management
| Shortcut | Action |
|----------|--------|
| `Cmd+D` | Split pane horizontally |
| `Cmd+Shift+D` | Split pane vertically |
| `Cmd+W` | Close current pane |
| `Cmd+Z` | Zoom/unzoom pane |
| `Cmd+T` | New tab |
| `Cmd+1-9` | Switch to tab 1-9 |

### Pane Navigation
| Shortcut | Action |
|----------|--------|
| `Cmd+Opt+h` | Focus pane left |
| `Cmd+Opt+j` | Focus pane down |
| `Cmd+Opt+k` | Focus pane up |
| `Cmd+Opt+l` | Focus pane right |
| `Cmd+[` | Previous pane |
| `Cmd+]` | Next pane |

### Pane Resizing
| Shortcut | Action |
|----------|--------|
| `Cmd+Opt+Shift+H` | Resize left |
| `Cmd+Opt+Shift+J` | Resize down |
| `Cmd+Opt+Shift+K` | Resize up |
| `Cmd+Opt+Shift+L` | Resize right |

### Other
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+T` | **Theme switcher** (Gruvbox, Tokyo Night, etc.) |
| `Cmd+Shift+N` | Open Nushell in new tab |
| `Cmd+Shift+R` | Reload WezTerm config |
| `Cmd+F` | Search |
| `Cmd+=` / `Cmd+-` | Increase/decrease font size |
| `Cmd+0` | Reset font size |

---

## 💻 Shell Shortcuts (Zsh)

### Command Discovery
| Shortcut/Command | Action |
|------------------|--------|
| `Ctrl+R` | **Search command history** (Atuin) |
| `Ctrl+G` | **Interactive cheatsheets** (navi) |
| `help` | Show custom help/quick reference |
| `tldr <cmd>` | Simple examples (e.g., `tldr tar`) |

### Navigation
| Shortcut | Action |
|----------|--------|
| `Ctrl+A` | Jump to start of line |
| `Ctrl+E` | Jump to end of line |
| `Ctrl+U` | Clear line before cursor |
| `Ctrl+K` | Clear line after cursor |
| `Ctrl+W` | Delete word before cursor |
| `Ctrl+L` | Clear screen |

### Completion
| Shortcut | Action |
|----------|--------|
| `Tab` | Complete command/path |
| `Tab Tab` | Show all completions |

---

## 📝 Neovim (LazyVim) Shortcuts

### Essential Discovery
| Shortcut | Action |
|----------|--------|
| `<Space>` | **Show all keybindings** (which-key) |
| `:Lazy` | Plugin manager |
| `:checkhealth` | Diagnostic check |

### File Operations
| Shortcut | Action |
|----------|--------|
| `<Space>ff` | Find files |
| `<Space>fg` | Find in files (grep) |
| `<Space>fb` | Find buffers |
| `<Space>fr` | Recent files |
| `<Space>e` | File explorer (toggle) |

### AI Assistance (avante.nvim)
| Shortcut | Action |
|----------|--------|
| `<Space>aa` | Ask AI about code |
| `<Space>ae` | Edit selection with AI |
| `<Space>at` | Toggle AI sidebar |
| `<Space>ar` | Refresh AI response |

### Editing
| Shortcut | Action |
|----------|--------|
| `<Space>z` | Zen mode (distraction-free) |
| `<Space>w` | Save file |
| `<Space>q` | Quit |
| `gcc` | Toggle comment (line) |
| `gc` | Toggle comment (visual selection) |

### Window Management
| Shortcut | Action |
|----------|--------|
| `<Space>ww` | Switch windows |
| `<Space>ws` | Split horizontally |
| `<Space>wv` | Split vertically |
| `<Space>wd` | Close window |

---

## 🔧 Modern CLI Tools

### File Listing (eza)
```bash
ll              # Long listing with icons and git status
la              # List all files (including hidden)
lt              # Tree view (2 levels)
llt             # Tree view with details
ls              # Basic listing with icons
```

### File Viewing (bat)
```bash
cat file.txt    # View with syntax highlighting
catp file.txt   # View with paging
bat -l python script.py  # Force Python syntax
```

### File Finding (fd)
```bash
fd readme              # Find files named "readme"
fd -e lua              # Find all .lua files
fd -H config           # Find including hidden files
fd "^test" src/        # Find files starting with "test" in src/
```

### Text Search (ripgrep)
```bash
rg "pattern"           # Search in all files
rg "TODO" --type rust  # Search in Rust files only
rg -i "error"          # Case-insensitive search
rg -l "function"       # Show only filenames
rg "import" -g "*.py"  # Search in Python files
```

### Smart Navigation (zoxide)
```bash
z proj           # Jump to project directory
z doc            # Jump to documents
zi               # Interactive directory picker
z -            # Go to previous directory
```

### Fuzzy Finding (fzf)
```bash
vf               # Fuzzy find file and open in nvim
Ctrl+T           # Paste selected file path
Alt+C            # cd into selected directory
**<Tab>          # Trigger fzf for completions
```

### Command Discovery (navi)
```bash
navi             # Open interactive cheatsheets
Ctrl+G           # Quick access (from shell)
```

### Quick Help (tldr)
```bash
tldr tar         # Simple tar examples
tldr git         # Git command examples
tldr find        # Find command examples
```

### History Search (atuin)
```bash
Ctrl+R           # Search full history (fuzzy)
# Shows: command, directory, time, exit code
```

---

## 📂 Navigation Aliases

### Directory Movement
```bash
..               # cd ..
...              # cd ../..
....             # cd ../../..
z <name>         # Smart cd (learns frequently used dirs)
zi               # Interactive directory picker
```

### Custom Functions
```bash
help             # Show quick reference
mkcd dirname     # Create directory and cd into it
vf               # Fuzzy find and open file in nvim
```

---

## 🔀 Git Aliases

### Status & Info
```bash
g                # git
gs               # git status
gd               # git diff
gds              # git diff --staged
gl               # git log --oneline -15
glg              # git log --graph --oneline --decorate
gb               # git branch
```

### Making Changes
```bash
ga <file>        # git add <file>
gaa              # git add .
gc               # git commit
gcm "msg"        # git commit -m "msg"
gca              # git commit --amend
```

### Remote Operations
```bash
gp               # git push
gpl              # git pull
```

### Branching
```bash
gco <branch>     # git checkout <branch>
gcb <name>       # git checkout -b <name>
```

### Other
```bash
gst              # git stash
gstp             # git stash pop
```

---

## 🐚 Nushell Commands

### Launch Nushell
```bash
nu               # Start Nushell
Cmd+Shift+N      # Open Nushell in new WezTerm tab
```

### Data Processing Examples
```nushell
ls | where size > 1mb                    # Filter large files
ls | sort-by size | reverse              # Largest files first
open data.json | get users               # Extract JSON field
open data.csv | where status == "active" # Filter CSV rows
sys | get host                           # System info
ps | where cpu > 10 | sort-by cpu        # High CPU processes
http get api.github.com/users/octocat    # HTTP request
ls | to json                             # Convert to JSON
ls | to csv                              # Convert to CSV
```

### Nushell Functions
```bash
helpme           # Show Nushell quick reference
mkcd dirname     # Create and cd into directory
find-large       # Find files > 100MB
```

---

## 🎨 Theme Switching

### WezTerm
```
Ctrl+Shift+T → Choose from:
  - Gruvbox Dark Hard (default)
  - Gruvbox Dark
  - Gruvbox Light
  - Tokyo Night
  - Catppuccin Mocha
  - Catppuccin Latte
  - Solarized Dark
  - Dracula
  - Nord
  - One Dark
```

### Neovim
```vim
:colorscheme gruvbox-material    " Default
:colorscheme gruvbox
:colorscheme tokyonight
:colorscheme catppuccin
```

---

## 🔄 Configuration Management

### Reload Configs
```bash
reload           # Reload zsh config (alias for source ~/.zshrc)
Cmd+Shift+R      # Reload WezTerm config
:source %        # Reload Neovim config (from within nvim)
```

### Edit Configs
```bash
zshrc            # Edit ~/.zshrc in $EDITOR
wezconfig        # Edit ~/.wezterm.lua
starconfig       # Edit ~/.config/starship.toml
nvim ~/.config/nvim/lua/plugins/  # Edit Neovim plugins
```

### Chezmoi (Dotfiles Manager)
```bash
chezmoi status   # Check managed files
chezmoi diff     # Preview changes
chezmoi apply    # Apply changes (unreliable - use cp instead)
```

**Better workflow:**
```bash
# Edit source file
vim dot_zshrc

# Copy directly
cp dot_zshrc ~/.zshrc
cp dot_wezterm.lua ~/.wezterm.lua
cp dot_config/starship.toml ~/.config/starship.toml

# Test and commit
source ~/.zshrc
git add . && git commit -m "Update" && git push
```

---

## 🧰 Workflow Examples

### Quick File Editing
```bash
vf               # Fuzzy find + open in nvim
fd config | fzf | xargs nvim  # Find config, pick, edit
```

### Search and Replace Across Files
```bash
rg "oldtext" -l  # Find files containing "oldtext"
# Then in nvim: :%s/oldtext/newtext/g
```

### View Git Changes in Style
```bash
gd | bat -l diff  # Git diff with syntax highlighting
```

### Process JSON/CSV
```bash
nu               # Switch to Nushell
open data.json | where active == true | select name, email
open sales.csv | where amount > 100 | sort-by date | to json
```

### Find Large Files
```bash
fd -t f -x du -h {} | sort -rh | head -20  # ZSH method
nu -c "ls **/* | where size > 100mb | sort-by size --reverse"  # Nushell method
```

---

## 💡 Pro Tips

1. **Type `help`** in zsh for instant reference
2. **Press `<Space>`** in Neovim to discover all shortcuts
3. **Use `Ctrl+R`** to find that command you ran 2 weeks ago
4. **Try `navi`** when you can't remember syntax
5. **Use `tldr`** instead of `man` for quick examples
6. **Split panes** (`Cmd+D`) instead of new tabs for multitasking
7. **Use `z`** instead of `cd` - it learns your directories
8. **Theme switching**: `Ctrl+Shift+T` in WezTerm, `:colorscheme` in nvim

---

**Quick Start**: Type `help` in your terminal or press `<Space>` in Neovim!
