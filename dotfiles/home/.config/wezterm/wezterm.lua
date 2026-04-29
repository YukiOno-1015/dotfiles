local wezterm = require("wezterm")
local config = wezterm.config_builder()
local keybinds = require("keybinds")

config.automatically_reload_config = true

config.font_size = 14.0
config.font = wezterm.font("Hack Nerd Font")
config.use_ime = true

config.window_background_opacity = 0.75
config.macos_window_background_blur = 20
config.window_background_gradient = {
  colors = { "#000000" },
}

config.window_decorations = "RESIZE"
config.show_tabs_in_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false

config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

config.colors = {
  foreground = "#f0f0f0",
  tab_bar = {
    inactive_tab_edge = "none",
  },
}

config.disable_default_key_bindings = true
config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 }
config.keys = keybinds.keys
config.key_tables = keybinds.key_tables

wezterm.on("maximize-window", function(window, pane)
  window:gui_window():maximize()
end)

wezterm.on("restore-window", function(window, pane)
  window:gui_window():restore()
end)

wezterm.on("update-right-status", function(window, pane)
  local name = window:active_key_table()
  if name then
    name = "TABLE: " .. name
  end
  window:set_right_status(name or "")
end)

local solid_left_arrow = wezterm.nerdfonts.ple_lower_right_triangle
local solid_right_arrow = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#ffffff"
  local edge_background = "none"

  if tab.is_active then
    background = "#ae8b2d"
  end

  local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "

  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = background } },
    { Text = solid_left_arrow },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = background } },
    { Text = solid_right_arrow },
  }
end)

return config
