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

-- Status bar updates: workspace name (right) + help key table hint (left)
wezterm.on('update-right-status', function(window, pane)
  -- Right status: workspace name when 2+ workspaces exist
  local workspace = window:active_workspace()
  local workspaces = wezterm.mux.get_workspace_names()
  if #workspaces > 1 then
    window:set_right_status(wezterm.format({
      { Foreground = { Color = '#fabd2f' } },
      { Text = '\u{2387} ' .. workspace },
      { Foreground = { Color = '#928374' } },
      { Text = ' [' .. #workspaces .. ']  ' },
    }))
  else
    window:set_right_status('')
  end

  -- Left status: help overlay hint when active
  local key_table = window:active_key_table()
  if key_table == 'help' then
    window:set_left_status(wezterm.format({
      { Foreground = { Color = '#fabd2f' } },
      { Text = ' HELP: p=projects  w=workspaces  c=claude  g=git  y=yazi  b=btop  v=visidata  Esc=cancel ' },
    }))
  else
    window:set_left_status('')
  end
end)

-- Project workspace scanner
local project_dirs = {
  os.getenv('HOME') .. '/Documents/Github',
}

local function get_project_choices()
  local choices = {}
  local seen = {}
  for _, base in ipairs(project_dirs) do
    for _, path in ipairs(wezterm.glob(base .. '/*')) do
      local name = path:match('/([^/]+)$')
      if name and not seen[name] then
        seen[name] = true
        table.insert(choices, { label = name, id = path })
      end
    end
  end
  table.sort(choices, function(a, b) return a.label < b.label end)
  return choices
end

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

  -- Quick launch TUI applications
  { key = 'n', mods = 'CMD|SHIFT', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/nu' } } },
  { key = 'g', mods = 'CMD|SHIFT', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/lazygit' } } },
  { key = 'b', mods = 'CMD|SHIFT', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/btop' } } },
  { key = 'y', mods = 'CMD|SHIFT', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/yazi' } } },
  { key = 'l', mods = 'CMD|SHIFT', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/lazydocker' } } },
  { key = 'v', mods = 'CMD|SHIFT', action = act.SpawnCommandInNewTab { args = { os.getenv('HOME') .. '/.local/bin/vd' } } },

  -- Workspace management: select project → open nvim (top) + terminal (bottom)
  { key = 'P', mods = 'CMD|SHIFT', action = wezterm.action_callback(function(window, pane)
    local choices = get_project_choices()
    window:perform_action(act.InputSelector({
      title = 'Switch to Project Workspace',
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if not id then return end

        -- If workspace already exists, just switch to it
        for _, name in ipairs(wezterm.mux.get_workspace_names()) do
          if name == label then
            inner_window:perform_action(act.SwitchToWorkspace({ name = label }), inner_pane)
            return
          end
        end

        -- New workspace: nvim+Neotree on top, terminal + Claude Code below
        local tab, editor_pane, mux_window = wezterm.mux.spawn_window({
          workspace = label,
          cwd = id,
          args = { '/opt/homebrew/bin/nvim', '+Neotree' },
        })
        local terminal_pane = editor_pane:split({
          direction = 'Bottom',
          size = 0.35,
          cwd = id,
        })
        terminal_pane:split({
          direction = 'Right',
          size = 0.5,
          cwd = id,
          args = { '/bin/zsh', '-ic', 'claude' },
        })
        inner_window:perform_action(act.SwitchToWorkspace({ name = label }), inner_pane)
      end),
    }), pane)
  end) },
  { key = 'W', mods = 'CMD|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  { key = '[', mods = 'CMD|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
  { key = ']', mods = 'CMD|SHIFT', action = act.SwitchWorkspaceRelative(1) },

  -- Claude Code pane (split right, run claude)
  { key = 'c', mods = 'CMD|SHIFT', action = act.SplitHorizontal {
    domain = 'CurrentPaneDomain',
    args = { '/bin/zsh', '-ic', 'claude' },
  } },

  -- Terminal pane (split below)
  { key = 'Enter', mods = 'CMD|SHIFT', action = act.SplitVertical {
    domain = 'CurrentPaneDomain',
  } },

  -- Help overlay — activates HELP key table with status hint
  { key = 'F1', action = act.ActivateKeyTable {
    name = 'help',
    one_shot = true,
    timeout_milliseconds = 5000,
  } },
}

-- =============================================================================
-- HELP KEY TABLE
-- =============================================================================

config.key_tables = {
  help = {
    { key = 'p', action = wezterm.action_callback(function(window, pane)
      local choices = get_project_choices()
      window:perform_action(act.InputSelector({
        title = 'Switch to Project Workspace',
        choices = choices,
        fuzzy = true,
        action = wezterm.action_callback(function(win, p, id, label)
          if not id then return end
          for _, name in ipairs(wezterm.mux.get_workspace_names()) do
            if name == label then
              win:perform_action(act.SwitchToWorkspace({ name = label }), p)
              return
            end
          end
          local tab, editor_pane, mux_window = wezterm.mux.spawn_window({
            workspace = label, cwd = id,
            args = { '/opt/homebrew/bin/nvim', '+Neotree' },
          })
          local term_pane = editor_pane:split({ direction = 'Bottom', size = 0.35, cwd = id })
          term_pane:split({ direction = 'Right', size = 0.5, cwd = id,
            args = { '/bin/zsh', '-ic', 'claude' },
          })
          win:perform_action(act.SwitchToWorkspace({ name = label }), p)
        end),
      }), pane)
    end) },
    { key = 'w', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
    { key = 'c', action = act.SpawnCommandInNewTab {
      args = { '/bin/zsh', '-ic', 'claude' },
    } },
    { key = 'g', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/lazygit' } } },
    { key = 'y', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/yazi' } } },
    { key = 'b', action = act.SpawnCommandInNewTab { args = { '/opt/homebrew/bin/btop' } } },
    { key = 'v', action = act.SpawnCommandInNewTab { args = { os.getenv('HOME') .. '/.local/bin/vd' } } },
    { key = 'Escape', action = 'PopKeyTable' },
  },
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
