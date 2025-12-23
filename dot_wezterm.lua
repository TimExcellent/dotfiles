-- WezTerm Configuration
-- Gruvbox theme with easy switching, clean design
-- Press Ctrl+Shift+T to open theme switcher

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- =============================================================================
-- APPEARANCE
-- =============================================================================

-- Default to Gruvbox Dark (Hard contrast)
config.color_scheme = 'GruvboxDarkHard'

-- Window styling
config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.scrollback_lines = 10000
config.enable_scroll_bar = false

-- Window size defaults (good for most displays)
config.initial_cols = 140
config.initial_rows = 40

-- =============================================================================
-- FONT
-- =============================================================================

-- Use Hack Nerd Font for icons, fallback to JetBrains Mono
config.font = wezterm.font_with_fallback({
  { family = 'Hack Nerd Font Mono', weight = 'Regular' },
  { family = 'JetBrains Mono', weight = 'Regular' },
})
config.font_size = 14.0

-- =============================================================================
-- TAB BAR
-- =============================================================================

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32

-- Gruvbox-inspired tab colors
config.colors = {
  tab_bar = {
    background = '#1d2021',
    active_tab = {
      bg_color = '#3c3836',
      fg_color = '#ebdbb2',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#1d2021',
      fg_color = '#928374',
    },
    inactive_tab_hover = {
      bg_color = '#282828',
      fg_color = '#a89984',
    },
    new_tab = {
      bg_color = '#1d2021',
      fg_color = '#928374',
    },
    new_tab_hover = {
      bg_color = '#3c3836',
      fg_color = '#ebdbb2',
    },
  },
}

-- Custom tab title format
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local cwd = tab.active_pane.current_working_directory
  local title = 'Terminal'

  if cwd then
    local path = cwd:gsub('file://[^/]*', '')
    title = path:match('/([^/]+)$') or '~'
  end

  local index = tab.tab_index + 1
  return string.format(' %d: %s ', index, title)
end)

-- =============================================================================
-- KEYBINDINGS
-- =============================================================================

config.keys = {
  -- Theme switcher: Ctrl+Shift+T
  { key = 'T', mods = 'CTRL|SHIFT', action = act.InputSelector({
    title = 'Select Color Scheme',
    choices = {
      { label = 'Gruvbox Dark Hard', id = 'GruvboxDarkHard' },
      { label = 'Gruvbox Dark', id = 'Gruvbox Dark (Gogh)' },
      { label = 'Gruvbox Light', id = 'GruvboxLight' },
      { label = 'Tokyo Night', id = 'Tokyo Night' },
      { label = 'Catppuccin Mocha', id = 'Catppuccin Mocha' },
      { label = 'Catppuccin Latte', id = 'Catppuccin Latte' },
      { label = 'Solarized Dark', id = 'Solarized (dark) (terminal.sexy)' },
      { label = 'Dracula', id = 'Dracula' },
      { label = 'Nord', id = 'Nord (Gogh)' },
      { label = 'One Dark', id = 'One Dark (Gogh)' },
    },
    action = wezterm.action_callback(function(window, pane, id, label)
      if id then
        window:set_config_overrides({ color_scheme = id })
      end
    end),
  })},

  -- Tab management (CMD on macOS)
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = false } },
  { key = '1', mods = 'CMD', action = act.ActivateTab(0) },
  { key = '2', mods = 'CMD', action = act.ActivateTab(1) },
  { key = '3', mods = 'CMD', action = act.ActivateTab(2) },
  { key = '4', mods = 'CMD', action = act.ActivateTab(3) },
  { key = '5', mods = 'CMD', action = act.ActivateTab(4) },
  { key = '6', mods = 'CMD', action = act.ActivateTab(5) },
  { key = '7', mods = 'CMD', action = act.ActivateTab(6) },
  { key = '8', mods = 'CMD', action = act.ActivateTab(7) },
  { key = '9', mods = 'CMD', action = act.ActivateTab(-1) },

  -- Pane management
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'D', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Pane navigation (Vim-style)
  { key = 'h', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Right' },
  { key = '[', mods = 'CMD', action = act.ActivatePaneDirection 'Prev' },
  { key = ']', mods = 'CMD', action = act.ActivatePaneDirection 'Next' },

  -- Pane resizing
  { key = 'H', mods = 'CMD|OPT|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'CMD|OPT|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'CMD|OPT|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'CMD|OPT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },

  -- Zoom current pane
  { key = 'z', mods = 'CMD', action = act.TogglePaneZoomState },

  -- Font size
  { key = '=', mods = 'CMD', action = act.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = act.ResetFontSize },

  -- Search and reload
  { key = 'f', mods = 'CMD', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },

  -- Quick Nushell
  { key = 'n', mods = 'CMD|SHIFT', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/nu' } } },
}

-- =============================================================================
-- QUICK SELECT
-- =============================================================================

config.quick_select_patterns = {
  'https?://[^\\s]+',
  '[~\\./][\\w./-]+',
  '[a-f0-9]{7,40}',
  '\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}',
}

return config
