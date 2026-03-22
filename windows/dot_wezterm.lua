-- WezTerm Configuration — Windows
-- Mirrors macOS/Linux config: Gruvbox theme, workspaces, Claude integration
-- Adapted: ALT replaces CMD, Windows paths, Git Bash as default shell
-- Press Ctrl+Shift+T to open theme switcher

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- =============================================================================
-- WINDOWS PATHS & SHELL
-- =============================================================================

local home = os.getenv('USERPROFILE') or 'C:\\Users\\' .. os.getenv('USERNAME')
local git_bash = 'C:/Program Files/Git/bin/bash.exe'

-- Default shell: Git Bash (matches macOS/Linux zsh experience)
config.default_prog = { git_bash, '--login', '-i' }

-- Tool paths — resolved at runtime via PATH (winget/scoop install to PATH)
-- Fallback: check scoop shims, then skip if not found
local function find_tool(name)
  local scoop = os.getenv('USERPROFILE') .. '/scoop/shims/' .. name .. '.exe'
  local f = io.open(scoop, 'r')
  if f then f:close(); return scoop end
  return name
end

-- =============================================================================
-- APPEARANCE (identical to macOS/Linux)
-- =============================================================================

config.color_scheme = 'GruvboxDarkHard'

config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.scrollback_lines = 10000
config.enable_scroll_bar = false

config.initial_cols = 140
config.initial_rows = 40

-- =============================================================================
-- FONT (identical to macOS/Linux)
-- =============================================================================

config.font = wezterm.font_with_fallback({
  'Hack Nerd Font Mono',
  'JetBrains Mono',
})
config.font_size = 12.0  -- slightly smaller than macOS 14.0 for typical Windows DPI

-- =============================================================================
-- TAB BAR (identical to macOS/Linux)
-- =============================================================================

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32

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

-- Custom tab title format (identical logic)
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local cwd = tab.active_pane.current_working_directory
  local title = 'Terminal'

  if cwd then
    local path = cwd:gsub('file://[^/]*', '')
    title = path:match('[/\\]([^/\\]+)$') or '~'
  end

  local index = tab.tab_index + 1
  return string.format(' %d: %s ', index, title)
end)

-- Status bar (identical to macOS/Linux)
wezterm.on('update-right-status', function(window, pane)
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

  local key_table = window:active_key_table()
  if key_table == 'help' then
    window:set_left_status(wezterm.format({
      { Foreground = { Color = '#fabd2f' } },
      { Text = ' HELP: p=projects  w=workspaces  c=claude  g=git  y=yazi  b=btop  Esc=cancel ' },
    }))
  else
    window:set_left_status('')
  end
end)

-- Project workspace scanner (Windows paths)
local project_dirs = {
  home .. '/Documents/GitHub',
}

local function get_project_choices()
  local choices = {}
  local seen = {}
  for _, base in ipairs(project_dirs) do
    local ok, paths = pcall(wezterm.glob, base .. '/*')
    if ok then
      for _, path in ipairs(paths) do
        local name = path:match('[/\\]([^/\\]+)$')
        if name and not seen[name] then
          seen[name] = true
          table.insert(choices, { label = name, id = path })
        end
      end
    end
  end
  table.sort(choices, function(a, b) return a.label < b.label end)
  return choices
end

-- =============================================================================
-- KEYBINDINGS
-- Windows mapping: CMD -> ALT for most bindings
-- Tab switching: ALT+1-9 (matches Windows conventions)
-- Pane management: ALT+D/ALT+SHIFT+D
-- Navigation: CTRL+ALT+hjkl (vim-style)
-- Quick launch: CTRL+SHIFT+key (same as macOS CMD+SHIFT+key)
-- =============================================================================

config.keys = {
  -- Theme switcher: Ctrl+Shift+T (identical)
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

  -- Tab management (ALT replaces CMD)
  { key = 't', mods = 'ALT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },
  { key = '1', mods = 'ALT', action = act.ActivateTab(0) },
  { key = '2', mods = 'ALT', action = act.ActivateTab(1) },
  { key = '3', mods = 'ALT', action = act.ActivateTab(2) },
  { key = '4', mods = 'ALT', action = act.ActivateTab(3) },
  { key = '5', mods = 'ALT', action = act.ActivateTab(4) },
  { key = '6', mods = 'ALT', action = act.ActivateTab(5) },
  { key = '7', mods = 'ALT', action = act.ActivateTab(6) },
  { key = '8', mods = 'ALT', action = act.ActivateTab(7) },
  { key = '9', mods = 'ALT', action = act.ActivateTab(-1) },

  -- Pane management (ALT+D / ALT+SHIFT+D)
  { key = 'd', mods = 'ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'D', mods = 'ALT|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Pane navigation: CTRL+ALT+hjkl (vim-style)
  { key = 'h', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Right' },
  { key = '[', mods = 'ALT', action = act.ActivatePaneDirection 'Prev' },
  { key = ']', mods = 'ALT', action = act.ActivatePaneDirection 'Next' },

  -- Pane resizing: CTRL+ALT+SHIFT+hjkl
  { key = 'H', mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },

  -- Zoom current pane
  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },

  -- Font size (CTRL+=/CTRL+-)
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },

  -- Search and reload
  { key = 'f', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'r', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },

  -- Quick launch TUI applications (CTRL+SHIFT+key)
  { key = 'g', mods = 'CTRL|SHIFT', action = act.SpawnCommandInNewTab { args = { find_tool('lazygit') } } },
  { key = 'b', mods = 'CTRL|SHIFT', action = act.SpawnCommandInNewTab { args = { find_tool('btop') } } },
  { key = 'y', mods = 'CTRL|SHIFT', action = act.SpawnCommandInNewTab { args = { find_tool('yazi') } } },

  -- Workspace management: select project -> open nvim (top) + terminal (bottom)
  { key = 'P', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    local choices = get_project_choices()
    window:perform_action(act.InputSelector({
      title = 'Switch to Project Workspace',
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if not id then return end

        for _, name in ipairs(wezterm.mux.get_workspace_names()) do
          if name == label then
            inner_window:perform_action(act.SwitchToWorkspace({ name = label }), inner_pane)
            return
          end
        end

        -- nvim+Neotree on top, terminal + Claude Code below
        local tab, editor_pane, mux_window = wezterm.mux.spawn_window({
          workspace = label,
          cwd = id,
          args = { find_tool('nvim'), '+Neotree' },
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
          args = { git_bash, '-ic', 'claude' },
        })
        inner_window:perform_action(act.SwitchToWorkspace({ name = label }), inner_pane)
      end),
    }), pane)
  end) },
  { key = 'W', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  { key = '{', mods = 'CTRL|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
  { key = '}', mods = 'CTRL|SHIFT', action = act.SwitchWorkspaceRelative(1) },

  -- Claude Code pane (split right, run claude in Git Bash)
  { key = 'c', mods = 'CTRL|SHIFT', action = act.SplitHorizontal {
    domain = 'CurrentPaneDomain',
    args = { git_bash, '-ic', 'claude' },
  } },

  -- Terminal pane (split below)
  { key = 'Enter', mods = 'CTRL|SHIFT', action = act.SplitVertical {
    domain = 'CurrentPaneDomain',
  } },

  -- Help overlay
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
            args = { find_tool('nvim'), '+Neotree' },
          })
          local term_pane = editor_pane:split({ direction = 'Bottom', size = 0.35, cwd = id })
          term_pane:split({ direction = 'Right', size = 0.5, cwd = id,
            args = { git_bash, '-ic', 'claude' },
          })
          win:perform_action(act.SwitchToWorkspace({ name = label }), p)
        end),
      }), pane)
    end) },
    { key = 'w', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
    { key = 'c', action = act.SpawnCommandInNewTab {
      args = { git_bash, '-ic', 'claude' },
    } },
    { key = 'g', action = act.SpawnCommandInNewTab { args = { find_tool('lazygit') } } },
    { key = 'y', action = act.SpawnCommandInNewTab { args = { find_tool('yazi') } } },
    { key = 'b', action = act.SpawnCommandInNewTab { args = { find_tool('btop') } } },
    { key = 'Escape', action = 'PopKeyTable' },
  },
}

-- =============================================================================
-- QUICK SELECT (identical to macOS/Linux)
-- =============================================================================

config.quick_select_patterns = {
  'https?://[^\\s]+',
  '[~\\./][\\w./-]+',
  '[a-f0-9]{7,40}',
  '\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}',
}

return config
