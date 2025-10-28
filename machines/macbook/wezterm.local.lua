-- ===========================================================================
-- Machine-Specific Configuration for: Mac (MacBook)
-- ===========================================================================
-- This file contains settings that vary between machines
-- DO NOT commit this file if it contains sensitive paths

local wezterm = require('wezterm')

return {
  -- Background image (machine-specific path)
  background = {
    {
      source = {
        File = os.getenv("HOME") .. "/dotfiles/assets/wallpapers/machines/macbook/os_waallpaper_v3.png",
      },
      height = "Cover",
      width = "Cover",
      vertical_align = "Middle",
      horizontal_align = "Center",
      repeat_x = "NoRepeat",
      repeat_y = "NoRepeat",
      hsb = {
        brightness = 0.3,
        hue = 1.0,
        saturation = 1.0,
      },
      opacity = 0.95,
    },
  },

  -- Window size for this machine (MacBook screen)
  initial_rows = 40,
  initial_cols = 140,

  -- Any other machine-specific overrides
  -- window_background_opacity = 0.95,
}
