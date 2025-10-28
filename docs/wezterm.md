# Wezterm Configuration Guide

Complete guide for Wezterm terminal emulator configuration in this dotfiles repository.

## Overview

This dotfiles repository includes a fully configured Wezterm setup with:

- **Theme**: Dracula color scheme
- **Font**: PlemolJP Console NF (Nerd Fonts variant)
- **GPU Acceleration**: Enabled for smooth rendering
- **Custom Backgrounds**: Machine-specific wallpapers
- **Modular Configuration**: Shared config + machine-specific overrides

## Configuration Structure

```
config/wezterm/
├── wezterm.lua          # Main configuration (shared)
└── local.lua            # Machine-specific (git-ignored, symlinked from machines/)

machines/<machine-type>/
└── wezterm.local.lua    # Source for local.lua
```

## Main Configuration

Location: `~/dotfiles/config/wezterm/wezterm.lua`

### Key Features

1. **Color Scheme**: Dracula
2. **Font Configuration**:
   - Family: PlemolJP Console NF
   - Size: 14.0
   - Line height: 1.2
3. **GPU Acceleration**: WebGpu frontend
4. **Tab Bar**: Enabled with customization
5. **Window Decorations**: Integrated buttons
6. **Opacity**: 0.95 (95% opacity)
7. **Custom Background**: Loaded from `local.lua`

### Font Setup

The configuration uses PlemolJP Console NF, which includes:
- Japanese glyph support
- Nerd Fonts icons
- Programming ligatures
- Excellent readability

Installation is automatic via `installers/fonts.sh`:
```bash
brew tap homebrew/cask-fonts
brew install --cask font-plemoljp-nf
```

### Color Scheme

Using the Dracula theme with these key colors:
- Background: `#282a36`
- Foreground: `#f8f8f2`
- Selection: `#44475a`
- Cursor: `#f8f8f2`

Full palette:
```lua
colors = {
  foreground = "#f8f8f2",
  background = "#282a36",
  cursor_bg = "#f8f8f2",
  cursor_border = "#f8f8f2",
  cursor_fg = "#282a36",
  selection_bg = "#44475a",
  selection_fg = "#f8f8f2",
  ansi = {
    "#21222c", "#ff5555", "#50fa7b", "#f1fa8c",
    "#bd93f9", "#ff79c6", "#8be9fd", "#f8f8f2",
  },
  brights = {
    "#6272a4", "#ff6e6e", "#69ff94", "#ffffa5",
    "#d6acff", "#ff92df", "#a4ffff", "#ffffff",
  },
}
```

## Machine-Specific Configuration

### How It Works

The main `wezterm.lua` loads `local.lua` at the end:

```lua
local local_config_path = wezterm.config_dir .. '/local.lua'

if file_exists(local_config_path) then
  local ok, local_config = pcall(dofile, local_config_path)
  if ok and local_config then
    for k, v in pairs(local_config) do
      config[k] = v
    end
  end
end

return config
```

During installation, `install.sh` creates a symlink:
```bash
~/.config/wezterm/local.lua -> ~/dotfiles/machines/macbook/wezterm.local.lua
```

### Example: MacBook Configuration

File: `~/dotfiles/machines/macbook/wezterm.local.lua`

```lua
local wezterm = require('wezterm')

return {
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
  initial_rows = 40,
  initial_cols = 140,
}
```

### Customizable Settings

Common settings you might want to override per machine:

```lua
return {
  -- Background image
  background = { { source = { File = "path/to/image.png" } } },

  -- Window size
  initial_rows = 40,
  initial_cols = 140,

  -- Font size
  font_size = 14.0,

  -- Opacity
  window_background_opacity = 0.95,

  -- Color overrides
  colors = {
    background = "#282a36",
    foreground = "#f8f8f2",
  },

  -- Key bindings (add to existing)
  keys = {
    { key = "t", mods = "CMD", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  },
}
```

## Adding Custom Wallpapers

1. **Add wallpaper to assets**:
```bash
cp my-wallpaper.png ~/dotfiles/assets/wallpapers/machines/macbook/
```

2. **Configure Git LFS** (if not already done):
```bash
git lfs track "*.png"
git lfs track "*.jpg"
```

3. **Update local config**:
```lua
-- ~/dotfiles/machines/macbook/wezterm.local.lua
return {
  background = {
    {
      source = {
        File = os.getenv("HOME") .. "/dotfiles/assets/wallpapers/machines/macbook/my-wallpaper.png",
      },
      hsb = { brightness = 0.3 },  -- Adjust as needed
      opacity = 0.95,
    },
  },
}
```

4. **Commit changes**:
```bash
git add assets/wallpapers/machines/macbook/my-wallpaper.png
git add machines/macbook/wezterm.local.lua
git commit -m "Add custom wallpaper for MacBook"
```

## Key Bindings

Default Wezterm key bindings are preserved. Common ones:

| Key | Action |
|-----|--------|
| `Cmd+T` | New tab |
| `Cmd+W` | Close tab |
| `Cmd+1-9` | Switch to tab N |
| `Cmd+Shift+[` | Previous tab |
| `Cmd+Shift+]` | Next tab |
| `Cmd+D` | Split pane horizontal |
| `Cmd+Shift+D` | Split pane vertical |
| `Cmd+K` | Clear scrollback |
| `Cmd+F` | Search |
| `Cmd++` | Increase font size |
| `Cmd+-` | Decrease font size |
| `Cmd+0` | Reset font size |

### Custom Key Bindings

Add custom bindings in `local.lua`:

```lua
local wezterm = require('wezterm')

return {
  keys = {
    -- Example: Toggle opacity
    {
      key = 'o',
      mods = 'CMD|SHIFT',
      action = wezterm.action.EmitEvent('toggle-opacity'),
    },
    -- Example: Quick commands
    {
      key = 'r',
      mods = 'CMD|SHIFT',
      action = wezterm.action.SpawnCommandInNewTab {
        args = { 'zsh', '-c', 'ranger' },
      },
    },
  },
}
```

## Tab Bar Customization

The tab bar is styled to match the Dracula theme:

```lua
window_frame = {
  font = wezterm.font { family = 'PlemolJP Console NF', weight = 'Bold' },
  font_size = 12.0,
  active_titlebar_bg = '#282a36',
  inactive_titlebar_bg = '#21222c',
}

colors = {
  tab_bar = {
    background = '#282a36',
    active_tab = {
      bg_color = '#bd93f9',
      fg_color = '#282a36',
    },
    inactive_tab = {
      bg_color = '#44475a',
      fg_color = '#f8f8f2',
    },
    inactive_tab_hover = {
      bg_color = '#6272a4',
      fg_color = '#f8f8f2',
    },
  },
}
```

## Performance Tuning

### GPU Acceleration

GPU acceleration is enabled by default:
```lua
front_end = "WebGpu"
```

For systems without WebGpu support, Wezterm falls back to OpenGL automatically.

### Font Shaping

Hardware font shaping is enabled for better performance:
```lua
harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
```

## Troubleshooting

### Font Not Found

If PlemolJP Console NF is not found:
```bash
# Reinstall font
brew reinstall font-plemoljp-nf

# Verify installation
ls ~/Library/Fonts/ | grep -i plemol
```

### Background Image Not Loading

1. Check file path in `local.lua`:
```lua
File = os.getenv("HOME") .. "/dotfiles/assets/wallpapers/machines/macbook/os_waallpaper_v3.png"
```

2. Verify file exists:
```bash
ls -la ~/dotfiles/assets/wallpapers/machines/macbook/
```

3. Check Wezterm logs:
```bash
# macOS
~/Library/Logs/wezterm/wezterm.log
```

### Local Config Not Loading

1. Verify symlink exists:
```bash
ls -la ~/.config/wezterm/local.lua
```

2. Re-create symlink:
```bash
ln -sf ~/dotfiles/machines/macbook/wezterm.local.lua ~/.config/wezterm/local.lua
```

3. Check Wezterm logs for Lua errors

### Performance Issues

If you experience lag or high CPU usage:

1. **Disable background image temporarily**:
```lua
-- Comment out background in local.lua
-- background = { ... },
```

2. **Reduce opacity effects**:
```lua
window_background_opacity = 1.0  -- Fully opaque
text_background_opacity = 1.0
```

3. **Adjust rendering backend**:
```lua
-- Try software rendering
front_end = "Software"
```

## Advanced Configuration

### Dynamic Background Based on Time

```lua
local wezterm = require('wezterm')

local function get_background()
  local hour = tonumber(os.date("%H"))

  if hour >= 6 and hour < 12 then
    return "morning.png"
  elseif hour >= 12 and hour < 18 then
    return "afternoon.png"
  elseif hour >= 18 and hour < 22 then
    return "evening.png"
  else
    return "night.png"
  end
end

return {
  background = {
    {
      source = {
        File = os.getenv("HOME") .. "/dotfiles/assets/wallpapers/machines/macbook/" .. get_background(),
      },
      hsb = { brightness = 0.3 },
      opacity = 0.95,
    },
  },
}
```

### Multiple Background Layers

```lua
return {
  background = {
    -- Layer 1: Base wallpaper
    {
      source = { File = "base.png" },
      opacity = 0.9,
    },
    -- Layer 2: Overlay gradient
    {
      source = {
        Gradient = {
          colors = { "#282a36", "#21222c" },
        },
      },
      opacity = 0.5,
    },
  },
}
```

## References

- [Wezterm Official Docs](https://wezfurlong.org/wezterm/)
- [Wezterm Configuration](https://wezfurlong.org/wezterm/config/files.html)
- [Dracula Theme](https://draculatheme.com/wezterm)
- [PlemolJP Font](https://github.com/yuru7/PlemolJP)

## See Also

- [Neovim Configuration Guide](./neovim.md)
- [Maintenance Guide](./maintenance.md)
- [Troubleshooting Guide](./troubleshooting.md)
