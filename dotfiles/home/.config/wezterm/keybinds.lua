local wezterm = require("wezterm")
local act = wezterm.action

return {
  keys = {
    { key = "p", mods = "SUPER", action = act.ActivateCommandPalette },

    { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
    { key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },
    { key = "t", mods = "SUPER", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = true }) },
    { key = "{", mods = "LEADER", action = act.MoveTabRelative(-1) },
    { key = "}", mods = "LEADER", action = act.MoveTabRelative(1) },

    { key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
    { key = "Enter", mods = "CMD|SHIFT", action = act.ToggleFullScreen },
    { key = "m", mods = "CMD|SHIFT", action = act.EmitEvent("maximize-window") },
    { key = "r", mods = "CMD|SHIFT", action = act.EmitEvent("restore-window") },

    { key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
    { key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
    { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
    { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
    { key = "0", mods = "CTRL", action = act.ResetFontSize },

    { key = "d", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "r", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
    { key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
    { key = "a", mods = "LEADER", action = act.ActivateKeyTable({ name = "activate_pane", timeout_milliseconds = 1000 }) },

    { key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES", title = "ワークスペースを選択" }) },
    {
      key = "$",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = "ワークスペース名を変更:",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
          end
        end),
      }),
    },
    {
      key = "W",
      mods = "LEADER|SHIFT",
      action = act.PromptInputLine({
        description = "新しいワークスペースを作成:",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
          end
        end),
      }),
    },

    { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  },

  key_tables = {
    resize_pane = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
      { key = "Enter", action = "PopKeyTable" },
    },

    activate_pane = {
      { key = "h", action = act.ActivatePaneDirection("Left") },
      { key = "j", action = act.ActivatePaneDirection("Down") },
      { key = "k", action = act.ActivatePaneDirection("Up") },
      { key = "l", action = act.ActivatePaneDirection("Right") },
    },

    copy_mode = {
      { key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
      { key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
      { key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
      { key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
      { key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
      { key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
      { key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
      { key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
      { key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
      { key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
      { key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
      { key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
      { key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
      { key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
      { key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
      { key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
      { key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
      { key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
      { key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
      { key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
      { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
      { key = "y", mods = "NONE", action = act.CopyTo("Clipboard") },
      {
        key = "Enter",
        mods = "NONE",
        action = act.Multiple({ act.CopyTo("ClipboardAndPrimarySelection"), act.CopyMode("Close") }),
      },
      { key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
      { key = "q", mods = "NONE", action = act.CopyMode("Close") },
    },
  },
}
