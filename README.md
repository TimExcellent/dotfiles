# Cross-Platform Terminal Setup

A comprehensive, synchronized terminal environment that works identically across macOS, Windows, and Linux. This setup provides powerful multiplexing, AI-assisted command line, beautiful prompts, and data processing capabilities.

## 🎯 What This Setup Provides

### **Core Capabilities**
- **Powerful Terminal Multiplexing**: Sessions, workspaces, tabs, and panes with intuitive key bindings
- **AI-Powered Command Line**: GitHub Copilot integration with natural language to command translation
- **Hybrid Shell Environment**: POSIX compatibility with zsh/bash + powerful data processing with Nushell
- **Beautiful, Informative Prompts**: Starship prompts showing git status, languages, and more
- **True Cross-Platform Sync**: Identical configuration across Mac, Windows, and Linux
- **Professional Workflow**: Organized workspaces for different projects and tasks

### **Why This Architecture**

**WezTerm** - Chosen over iTerm2, Windows Terminal, or traditional multiplexers because:
- Native multiplexing eliminates need for tmux/screen
- True cross-platform with identical features everywhere
- Lua configuration enables sophisticated customization
- GPU-accelerated performance
- Built-in SSH support and remote sessions

**Starship** - Universal prompt that:
- Works consistently across all shells and platforms
- Shows contextual information (git, languages, etc.)
- Highly customizable but sensible defaults
- Fast and lightweight

**Hybrid Shell Strategy** - Best of both worlds:
- **zsh/bash**: POSIX compatibility, script execution, system administration
- **Nushell**: Structured data processing, modern syntax, type safety
- Easy switching between shells for different tasks

**GitHub Copilot CLI** - AI assistance for:
- Command discovery and learning
- Complex one-liners and data processing
- Git workflows and debugging

**Chezmoi** - Dotfiles management that:
- Handles platform differences elegantly
- Supports templates for cross-platform configs
- Secure secret management
- Git-based synchronization

## 🚀 Quick Start

### **Fresh Machine Setup (All Platforms)**

If you already have this repository set up, use this one-liner to install everything:

```bash
# Install chezmoi and apply your dotfiles in one command
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply YOUR_GITHUB_USERNAME
```

Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username.

### **Manual Setup (First Time)**

Follow the platform-specific installation guide below, then proceed to the Configuration section.

## 📦 Installation by Platform

### **macOS**

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all components
brew install wezterm starship nushell gh chezmoi

# Install GitHub Copilot extension
gh extension install github/gh-copilot
```

### **Windows**

**Option 1: Using winget (Recommended)**
```powershell
# Install via Windows Package Manager
winget install wezterm
winget install starship
winget install nushell
winget install GitHub.cli
winget install twpayne.chezmoi

# Install GitHub Copilot extension
gh extension install github/gh-copilot
```

**Option 2: Manual Installation**
1. **WezTerm**: Download from [GitHub releases](https://github.com/wez/wezterm/releases)
2. **Starship**: Download from [starship.rs](https://starship.rs/guide/#%F0%9F%9A%80-installation)
3. **Nushell**: Download from [GitHub releases](https://github.com/nushell/nushell/releases)
4. **GitHub CLI**: Download from [cli.github.com](https://cli.github.com/)
5. **Chezmoi**: Download from [chezmoi.io](https://chezmoi.io/install/)

### **Linux (Ubuntu/Debian)**

```bash
# Update package lists
sudo apt update

# Install dependencies
sudo apt install curl wget gpg

# WezTerm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update && sudo apt install wezterm

# Starship
curl -sS https://starship.rs/install.sh | sh

# Nushell
sudo apt install nushell

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# Chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Install GitHub Copilot extension
gh extension install github/gh-copilot
```

### **Linux (Fedora/RHEL)**

```bash
# WezTerm
sudo dnf copr enable wezfurlong/wezterm-nightly
sudo dnf install wezterm

# Starship
curl -sS https://starship.rs/install.sh | sh

# Nushell
sudo dnf install nushell

# GitHub CLI
sudo dnf install gh

# Chezmoi
sudo dnf install chezmoi

# Install GitHub Copilot extension
gh extension install github/gh-copilot
```

### **Linux (Arch)**

```bash
# Install via pacman
sudo pacman -S wezterm starship nushell github-cli chezmoi

# Install GitHub Copilot extension
gh extension install github/gh-copilot
```

## ⚙️ Configuration Setup

### **Step 1: Authenticate with GitHub**

```bash
# Log in to GitHub (opens browser)
gh auth login

# Follow the prompts:
# - Choose GitHub.com
# - Choose HTTPS
# - Yes to authenticate Git
# - Login with web browser

# Verify authentication
gh auth status
```

### **Step 2: Apply This Repository's Configuration**

If you're setting up from this existing repository:

```bash
# Clone and apply this repository's configuration
chezmoi init --apply YOUR_GITHUB_USERNAME

# Replace YOUR_GITHUB_USERNAME with the actual username
```

### **Step 3: Configure Shell Integration**

The dotfiles should automatically configure your shells, but verify:

**For zsh (macOS default):**
```bash
# Check if Starship is in your .zshrc
grep starship ~/.zshrc

# If not found, add it:
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
echo 'eval "$(gh copilot alias -- zsh)"' >> ~/.zshrc
source ~/.zshrc
```

**For bash (Linux default):**
```bash
# Check if Starship is in your .bashrc
grep starship ~/.bashrc

# If not found, add it:
echo 'eval "$(starship init bash)"' >> ~/.bashrc
echo 'eval "$(gh copilot alias -- bash)"' >> ~/.bashrc
source ~/.bashrc
```

**For PowerShell (Windows):**
```powershell
# Check if profile exists
Test-Path $PROFILE

# If not, create it:
New-Item -Path $PROFILE -Type File -Force

# Add Starship initialization
Add-Content $PROFILE "Invoke-Expression (&starship init powershell)"
```

### **Step 4: Configure Nushell**

```bash
# Start Nushell to create config directories
nu

# In Nushell, configure Starship
mkdir ~/.cache/starship
starship init nu | save ~/.cache/starship/init.nu
echo "source ~/.cache/starship/init.nu" | save --append ($nu.config-path)

# Exit Nushell
exit
```

### **Step 5: Test Your Setup**

Open WezTerm and test the key bindings:

1. **Split horizontally**: `Ctrl+A` then `|`
2. **Split vertically**: `Ctrl+A` then `-`
3. **Navigate panes**: `Ctrl+A` then `h/j/k/l`
4. **New tab**: `Ctrl+A` then `c`
5. **Launch Nushell**: `Ctrl+A` then `u`
6. **New workspace**: `Ctrl+A` then `n`

Test AI assistance:
```bash
# Ask for command suggestions
?? find large files

# Ask for Git help
git? undo last commit
```

## 🎮 Usage Guide

### **Key Bindings Reference**

#### **Universal Leader Key: `Ctrl+A`**
All multiplexing commands start with `Ctrl+A` (hold both, then release, then press the command key):

| Command | Action |
|---------|--------|
| `Ctrl+A` `\|` | Split horizontally |
| `Ctrl+A` `-` | Split vertically |
| `Ctrl+A` `x` | Close current pane |
| `Ctrl+A` `z` | Zoom/unzoom pane |
| `Ctrl+A` `c` | Create new tab |
| `Ctrl+A` `h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl+A` `n` | New workspace |
| `Ctrl+A` `w` | Switch workspace |
| `Ctrl+A` `u` | Launch Nushell |
| `Ctrl+A` `1-5` | Switch to tab 1-5 |

#### **Platform-Specific Quick Keys**

**macOS:**
| Command | Action |
|---------|--------|
| `Cmd+D` | Quick horizontal split |
| `Cmd+Shift+D` | Quick vertical split |
| `Cmd+Option+Arrow` | Navigate panes |
| `Cmd+1-5` | Switch tabs |
| `Cmd+W` | Close pane |
| `Cmd+T` | New tab |

**Windows:**
| Command | Action |
|---------|--------|
| `Ctrl+Shift+D` | Quick horizontal split |
| `Ctrl+Alt+D` | Quick vertical split |
| `Ctrl+Shift+Arrow` | Navigate panes |
| `Alt+1-5` | Switch tabs |
| `Ctrl+W` | Close pane |
| `Ctrl+T` | New tab |

**Linux:**
| Command | Action |
|---------|--------|
| `Ctrl+Alt+D` | Quick horizontal split |
| `Ctrl+Alt+Shift+D` | Quick vertical split |
| `Ctrl+Alt+Arrow` | Navigate panes |
| `Alt+1-5` | Switch tabs |
| `Ctrl+Shift+W` | Close pane |
| `Ctrl+Shift+T` | New tab |

### **AI Command Assistance**

After setting up GitHub Copilot, you have these AI-powered aliases:

```bash
# General command suggestions
?? compress a folder
?? find files modified today
?? monitor system resources

# Git-specific help
git? undo last commit
git? merge branch without fast-forward
git? see changes between branches

# GitHub CLI help
gh? create pull request
gh? list my repositories
```

### **Nushell Data Processing**

Launch Nushell with `Ctrl+A` then `u`, then try these data processing commands:

```bash
# List files as structured data
ls | where size > 1MB | sort-by size

# System information as data
sys | get cpu

# Process information
ps | where cpu > 50 | sort-by cpu

# Working with JSON/CSV
open data.json | where status == "active" | get name

# Network requests as data
http get "https://api.github.com/user" | get login
```

### **Workspace Organization**

Create organized workspaces for different projects:

```bash
# Create a development workspace
Ctrl+A, n, type "development"

# Create a data analysis workspace  
Ctrl+A, n, type "analysis"

# Switch between workspaces
Ctrl+A, w (shows fuzzy finder)
```

Example workspace layouts:
- **Development**: Code editor + terminal + logs
- **Data Analysis**: Nushell + visualization + documentation
- **System Admin**: Multiple SSH sessions + monitoring

### **Cross-Platform Sync Workflow**

#### **Making Changes**
```bash
# Edit any tracked file
chezmoi edit ~/.wezterm.lua

# Apply changes locally
chezmoi apply

# Commit and push changes
chezmoi cd
git add .
git commit -m "Updated WezTerm configuration"
git push
exit
```

#### **Syncing to Other Machines**
```bash
# Pull latest changes
chezmoi cd
git pull
exit

# Apply updates
chezmoi apply

# Check what would change first
chezmoi diff
```

#### **Adding New Dotfiles**
```bash
# Track a new configuration file
chezmoi add ~/.gitconfig

# Edit through chezmoi
chezmoi edit ~/.gitconfig

# Apply and sync
chezmoi apply
chezmoi cd && git add . && git commit -m "Added git config" && git push && exit
```

## 🔧 Customization

### **Starship Prompt Customization**

Create a custom Starship configuration:

```bash
# Create custom starship config
chezmoi edit ~/.config/starship.toml
```

Example customizations:
```toml
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[git_branch]
symbol = "🌱 "

[nodejs]
symbol = "⬢ "

[python]
symbol = "🐍 "
```

### **WezTerm Theme Customization**

Edit your WezTerm configuration to change colors:

```bash
chezmoi edit ~/.wezterm.lua
```

Popular color schemes:
- `Tokyo Night`
- `Dracula`
- `Gruvbox Dark`
- `One Dark`
- `Catppuccin`

### **Nushell Customization**

Add custom commands and aliases:

```bash
# Edit Nushell config
nu
config nu
```

Example custom commands:
```nu
# Custom aliases
alias ll = ls -la
alias gst = git status
alias gp = git push

# Custom functions
def find-large [] {
    ls **/* | where size > 100MB | sort-by size
}
```

## 🩺 Troubleshooting

### **Common Issues**

#### **WezTerm Key Bindings Not Working**
```bash
# Check WezTerm configuration syntax
wezterm show-keys --lua

# Test configuration
wezterm --config-file ~/.wezterm.lua
```

#### **Starship Not Appearing**
```bash
# Check if starship is in PATH
which starship

# Manually test starship
starship init zsh

# Check shell configuration
echo $SHELL
```

#### **GitHub Copilot Not Working**
```bash
# Check authentication
gh auth status

# Reinstall extension
gh extension remove github/gh-copilot
gh extension install github/gh-copilot

# Test copilot
gh copilot suggest "list files"
```

#### **Nushell Integration Issues**
```bash
# Check Nushell installation
which nu

# Test Nushell startup
nu --commands "version"

# Check Starship integration
nu --commands "source ~/.cache/starship/init.nu"
```

#### **Chezmoi Sync Issues**
```bash
# Check chezmoi status
chezmoi status

# Force resync
chezmoi cd
git reset --hard origin/main
exit
chezmoi apply --force

# Check differences
chezmoi diff
```

### **Platform-Specific Issues**

#### **macOS: Command Not Found**
```bash
# Check if Homebrew is in PATH
echo $PATH | grep brew

# Add Homebrew to PATH
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### **Windows: PowerShell Execution Policy**
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set execution policy (if needed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### **Linux: Missing Dependencies**
```bash
# Install missing development tools
sudo apt install build-essential curl wget git

# Or on Fedora
sudo dnf groupinstall "Development Tools"
```

## 📚 Resources

### **Official Documentation**
- [WezTerm Documentation](https://wezfurlong.org/wezterm/)
- [Starship Configuration](https://starship.rs/config/)
- [Nushell Book](https://www.nushell.sh/book/)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Chezmoi User Guide](https://chezmoi.io/user-guide/setup/)

### **Community Resources**
- [Awesome WezTerm](https://github.com/wez/wezterm/discussions)
- [Starship Presets](https://starship.rs/presets/)
- [Nushell Cookbook](https://www.nushell.sh/cookbook/)
- [Dotfiles Inspiration](https://dotfiles.github.io/)

### **This Setup's Philosophy**

This configuration prioritizes:
1. **Consistency**: Same experience across all platforms
2. **Productivity**: Fast navigation and AI assistance
3. **Flexibility**: Easy switching between traditional and modern shells
4. **Maintainability**: Simple sync and update process
5. **Performance**: GPU acceleration and efficient tools

The setup is designed to grow with you - start with the basics and gradually add more sophisticated workflows as you become comfortable with the tools.

## 🤝 Contributing

Found an improvement or fix? Feel free to:
1. Fork this repository
2. Make your changes
3. Test across platforms
4. Submit a pull request

When contributing, please:
- Test on multiple platforms when possible
- Update documentation for any new features
- Keep platform-specific code clearly separated
- Maintain backward compatibility

---

**Happy terminal-ing!** 🚀
