-- ============================================================================
-- WEZTERM CROSS-PLATFORM CONFIGURATION
-- ============================================================================
-- Comprehensive configuration that works consistently across macOS, Windows, and Linux
-- Based on current WezTerm documentation and best practices (2025)

local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-- ============================================================================
-- PLATFORM DETECTION
-- ============================================================================

local is_windows = wezterm.target_triple == 'x86_64-pc-windows-msvc'
local is_macos = wezterm.target_triple:find("darwin") ~= nil  
local is_linux = not is_windows and not is_macos

-- ============================================================================
-- SHELL CONFIGURATION
-- ============================================================================

-- Function to check if a file exists
local function file_exists(path)
  local f = io.open(path, "r")
  if f ~= nil then 
    io.close(f) 
    return true 
  else 
    return false 
  end
end

-- Platform-specific shell configuration
if is_windows then
  config.default_prog = { 'pwsh.exe' }
elseif is_macos then
  -- macOS: Try different shell locations in order of preference
  if file_exists('/opt/homebrew/bin/zsh') then
    config.default_prog = { '/opt/homebrew/bin/zsh' }
  elseif file_exists('/usr/local/bin/zsh') then
    config.default_prog = { '/usr/local/bin/zsh' }
  elseif file_exists('/bin/zsh') then
    config.default_prog = { '/bin/zsh' }
  else
    config.default_prog = { '/bin/bash' }
  end
else
  -- Linux: Try bash then zsh
  if file_exists('/bin/bash') then
    config.default_prog = { '/bin/bash' }
  elseif file_exists('/bin/zsh') then
    config.default_prog = { '/bin/zsh' }
  else
    config.default_prog = { '/bin/sh' }
  end
end

-- ============================================================================
-- APPEARANCE CONFIGURATION
-- ============================================================================

-- Theme and colors
config.color_scheme = 'Tokyo Night'
config.window_background_opacity = 0.95
config.macos_window_background_blur = 10

-- Font configuration
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 14.0

-- Window and UI
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.scrollback_lines = 10000
config.enable_scroll_bar = false

-- Tab bar
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false

-- ============================================================================
-- LEADER KEY CONFIGURATION
-- ============================================================================

-- Leader key: Ctrl+A (works consistently across all platforms)
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

-- ============================================================================
-- PLATFORM-SPECIFIC KEY BINDINGS
-- ============================================================================

local keys = {}

-- ============================================================================
-- UNIVERSAL LEADER-BASED BINDINGS (Work on all platforms)
-- ============================================================================

local leader_keys = {
  -- Pane management
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER',       action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'LEADER',       action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER',       action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER',       action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER',       action = act.ActivatePaneDirection 'Right' },
  { key = 'x', mods = 'LEADER',       action = act.CloseCurrentPane { confirm = true } },
  { key = 'z', mods = 'LEADER',       action = act.TogglePaneZoomState },

  -- Tab management
  { key = 'c', mods = 'LEADER',       action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER',       action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER',       action = act.ActivateTabRelative(-1) },

  -- Workspace management
  { key = 'w', mods = 'LEADER',       action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  { key = 'W', mods = 'LEADER|SHIFT', action = act.PromptInputLine {
    description = 'Enter name for new workspace',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:perform_action(act.SwitchToWorkspace { name = line }, pane)
      end
    end),
  }},

  -- Shell and programs
  { key = 'u', mods = 'LEADER',       action = act.SpawnCommandInNewTab { args = { 'nu' } } },
  
  -- Send CTRL+A to terminal (for programs that need it)
  { key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },
}

-- Add leader keys to main key table
for _, key_def in ipairs(leader_keys) do
  table.insert(keys, key_def)
end

-- ============================================================================
-- PLATFORM-SPECIFIC ALTERNATIVE BINDINGS
-- ============================================================================

if is_macos then
  -- macOS-specific bindings using CMD key (SUPER)
  local macos_keys = {
    -- Tab navigation (browser-like)
    { key = '1', mods = 'CMD', action = act.ActivateTab(0) },
    { key = '2', mods = 'CMD', action = act.ActivateTab(1) },
    { key = '3', mods = 'CMD', action = act.ActivateTab(2) },
    { key = '4', mods = 'CMD', action = act.ActivateTab(3) },
    { key = '5', mods = 'CMD', action = act.ActivateTab(4) },
    
    -- Pane navigation (CMD+Option+Arrow)
    { key = 'LeftArrow',  mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow',    mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow',  mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Down' },
    
    -- Quick splits
    { key = 'd', mods = 'CMD',       action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'D', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    
    -- Standard macOS shortcuts
    { key = 't', mods = 'CMD',       action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w', mods = 'CMD',       action = act.CloseCurrentPane { confirm = true } },
    
    -- Configuration
    { key = ',', mods = 'CMD', action = act.SpawnCommandInNewWindow {
      cwd = os.getenv("HOME"),
      args = { os.getenv("SHELL"), "-c", "$EDITOR ~/.wezterm.lua" }
    }},
  }
  
  for _, key_def in ipairs(macos_keys) do
    table.insert(keys, key_def)
  end

elseif is_windows then
  -- Windows-specific bindings
  local windows_keys = {
    -- Tab navigation
    { key = '1', mods = 'ALT', action = act.ActivateTab(0) },
    { key = '2', mods = 'ALT', action = act.ActivateTab(1) },
    { key = '3', mods = 'ALT', action = act.ActivateTab(2) },
    { key = '4', mods = 'ALT', action = act.ActivateTab(3) },
    { key = '5', mods = 'ALT', action = act.ActivateTab(4) },
    
    -- Pane navigation (Ctrl+Shift+Arrow)
    { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow',    mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },
    
    -- Quick splits
    { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'D', mods = 'CTRL|ALT',   action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    
    -- Standard Windows shortcuts
    { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
  }
  
  for _, key_def in ipairs(windows_keys) do
    table.insert(keys, key_def)
  end

else
  -- Linux-specific bindings
  local linux_keys = {
    -- Tab navigation
    { key = '1', mods = 'ALT', action = act.ActivateTab(0) },
    { key = '2', mods = 'ALT', action = act.ActivateTab(1) },
    { key = '3', mods = 'ALT', action = act.ActivateTab(2) },
    { key = '4', mods = 'ALT', action = act.ActivateTab(3) },
    { key = '5', mods = 'ALT', action = act.ActivateTab(4) },
    
    -- Pane navigation (Ctrl+Alt+Arrow)
    { key = 'LeftArrow',  mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow',    mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow',  mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Down' },
    
    -- Quick splits
    { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'D', mods = 'CTRL|ALT',   action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    
    -- Standard shortcuts
    { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
  }
  
  for _, key_def in ipairs(linux_keys) do
    table.insert(keys, key_def)
  end
end

-- ============================================================================
-- UNIVERSAL NON-LEADER BINDINGS (All platforms)
-- ============================================================================

local universal_keys = {
  -- Font size adjustment
  { key = '=', mods = 'CTRL',       action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL',       action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL',       action = act.ResetFontSize },
  
  -- Copy/Paste
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
  
  -- Search
  { key = 'f', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
  
  -- Reload configuration
  { key = 'r', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  
  -- Debug overlay
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ShowDebugOverlay },
}

for _, key_def in ipairs(universal_keys) do
  table.insert(keys, key_def)
end

-- Apply the key configuration
config.keys = keys

-- ============================================================================
-- MOUSE BINDINGS
-- ============================================================================

config.mouse_bindings = {
  -- Right-click to paste
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action_callback(function(window, pane)
      local has_selection = window:get_selection_text_for_pane(pane) ~= ""
      if has_selection then
        window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.PasteFrom("Clipboard"), pane)
      end
    end),
  },
}

-- ============================================================================
-- WORKSPACES CONFIGURATION
-- ============================================================================

-- Define some default workspaces
config.default_workspace = "main"

-- ============================================================================
-- LAUNCH MENU (for quick access to different environments)
-- ============================================================================

local launch_menu = {}

if is_macos then
  launch_menu = {
    { label = "Zsh", args = { "zsh" } },
    { label = "Bash", args = { "bash" } },
  }
  -- Add Nushell if available
  if file_exists('/opt/homebrew/bin/nu') or file_exists('/usr/local/bin/nu') then
    table.insert(launch_menu, { label = "Nushell", args = { "nu" } })
  end
elseif is_windows then
  launch_menu = {
    { label = "PowerShell", args = { "pwsh.exe" } },
    { label = "Command Prompt", args = { "cmd.exe" } },
    { label = "Git Bash", args = { "C:\\Program Files\\Git\\bin\\bash.exe" } },
  }
elseif is_linux then
  launch_menu = {
    { label = "Bash", args = { "bash" } },
    { label = "Zsh", args = { "zsh" } },
  }
  if file_exists('/usr/bin/nu') or file_exists('/usr/local/bin/nu') then
    table.insert(launch_menu, { label = "Nushell", args = { "nu" } })
  end
end

config.launch_menu = launch_menu

-- ============================================================================
-- PERFORMANCE OPTIMIZATION
-- ============================================================================

config.max_fps = 120
config.animation_fps = 60
config.cursor_blink_rate = 500

-- ============================================================================
-- RETURN CONFIGURATION
-- ============================================================================

return config
