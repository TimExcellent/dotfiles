-- WezTerm Configuration - macOS
-- Minimal, professional, obvious

local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-- === APPEARANCE ===
-- Professional look, no distractions
config.color_scheme = 'Solarized Dark'
config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'NeverPrompt'
config.scrollback_lines = 10000
config.enable_scroll_bar = false

-- === FONT ===
-- One good monospace font
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 14.0

-- === COLORS ===  
-- Match Starship theme - solid background
-- No transparency or blur effects

-- === KEYBINDINGS ===
-- Muscle memory from tmux/vim
config.keys = {
  -- Tab management
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = true } },
  { key = '1', mods = 'CMD', action = act.ActivateTab(0) },
  { key = '2', mods = 'CMD', action = act.ActivateTab(1) },
  { key = '3', mods = 'CMD', action = act.ActivateTab(2) },
  { key = '4', mods = 'CMD', action = act.ActivateTab(3) },
  { key = '5', mods = 'CMD', action = act.ActivateTab(4) },
  { key = '6', mods = 'CMD', action = act.ActivateTab(5) },
  { key = '7', mods = 'CMD', action = act.ActivateTab(6) },
  { key = '8', mods = 'CMD', action = act.ActivateTab(7) },
  { key = '9', mods = 'CMD', action = act.ActivateTab(8) },
  
  -- Pane management
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'D', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = '[', mods = 'CMD', action = act.ActivatePaneDirection 'Prev' },
  { key = ']', mods = 'CMD', action = act.ActivatePaneDirection 'Next' },
  
  -- Standard shortcuts
  { key = '=', mods = 'CMD', action = act.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = act.ResetFontSize },
  { key = 'f', mods = 'CMD', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },
}

-- === TABS ===
-- Minimal, informative
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false

-- Custom tab title format showing index and directory
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

return config
