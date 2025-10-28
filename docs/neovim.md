# Neovim Configuration Guide

Complete guide for Neovim (LazyVim) configuration in this dotfiles repository.

## Overview

This dotfiles repository includes a fully configured Neovim setup powered by LazyVim with:

- **Distribution**: LazyVim (modern Neovim distribution)
- **Plugin Manager**: lazy.nvim (fast, declarative plugin management)
- **Custom Plugin**: OpenCode integration
- **Modular Configuration**: Shared config + machine-specific overrides
- **LSP Support**: Language Server Protocol for intelligent code completion
- **Fast Startup**: Lazy-loading optimizations

## Configuration Structure

```
config/nvim/
├── init.lua                   # Entry point
├── lazy-lock.json             # Plugin versions lockfile
├── lua/
│   ├── config/                # LazyVim configuration
│   │   ├── autocmds.lua       # Autocommands
│   │   ├── keymaps.lua        # Key mappings
│   │   ├── lazy.lua           # lazy.nvim bootstrap
│   │   └── options.lua        # Vim options
│   ├── plugins/               # Plugin configurations
│   │   └── opencode.lua       # OpenCode plugin
│   └── local.lua              # Machine-specific (git-ignored, symlinked)

machines/<machine-type>/
└── nvim.local.lua             # Source for lua/local.lua
```

## LazyVim Bootstrap

LazyVim is bootstrapped automatically on first `nvim` launch. The process:

1. `init.lua` loads `config/lazy.lua`
2. `lazy.lua` clones lazy.nvim if not present
3. lazy.nvim installs all configured plugins
4. LazyVim sets up default configurations

### Manual Bootstrap

If automatic bootstrap fails, run:

```bash
~/dotfiles/scripts/bootstrap-nvim.sh
```

Or manually:
```bash
nvim --headless "+Lazy! sync" +qa
```

## Main Configuration

Location: `~/dotfiles/config/nvim/`

### Entry Point: init.lua

```lua
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- ============================================================================
-- Machine-Specific Configuration Loading
-- ============================================================================
local local_config_path = vim.fn.stdpath("config") .. "/lua/local.lua"

if vim.loop.fs_stat(local_config_path) then
  local ok, local_config = pcall(require, "local")
  if ok and local_config then
    if local_config.ui then
      vim.notify("Loaded machine-specific UI config", vim.log.levels.INFO)
    end
    if local_config.lsp and local_config.lsp.servers then
      vim.notify("Loaded machine-specific LSP config", vim.log.levels.INFO)
    end
  end
end
```

### OpenCode Plugin

Location: `~/dotfiles/config/nvim/lua/plugins/opencode.lua`

This plugin integrates OpenCode AI assistance directly into Neovim.

```lua
return {
  "your-repo/opencode",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("opencode").setup({
      -- OpenCode configuration
    })
  end,
}
```

Usage:
- `:OpenCode` - Open OpenCode panel
- `:OpenCodeExplain` - Explain selected code
- `:OpenCodeRefactor` - Suggest refactoring

## Machine-Specific Configuration

### How It Works

The main `init.lua` loads `lua/local.lua` after LazyVim bootstrap.

During installation, `install.sh` creates a symlink:
```bash
~/.config/nvim/lua/local.lua -> ~/dotfiles/machines/macbook/nvim.local.lua
```

### Example: MacBook Configuration

File: `~/dotfiles/machines/macbook/nvim.local.lua`

```lua
return {
  -- UI Settings
  ui = {
    theme_variant = "darker",
    transparency = 0.95,
    background = "dark",
  },

  -- LSP Servers (machine-specific)
  lsp = {
    servers = {
      -- Rust (only on development machine)
      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
            },
          },
        },
      },

      -- Go (only on development machine)
      gopls = {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
          },
        },
      },
    },
  },

  -- Custom Keymaps
  keymaps = {
    -- Example: Machine-specific shortcuts
    { "n", "<leader>md", "<cmd>lua require('opencode').debug_mode()<cr>", { desc = "OpenCode Debug" } },
  },

  -- Custom Options
  options = {
    -- Machine-specific settings
    shiftwidth = 4,  -- Different indentation preference
    tabstop = 4,
  },
}
```

### Customizable Settings

Common settings you might want to override per machine:

#### UI Customization

```lua
ui = {
  -- Color scheme variant
  theme_variant = "darker",  -- or "lighter", "storm", etc.

  -- Transparency
  transparency = 0.95,

  -- Background
  background = "dark",  -- or "light"

  -- Line numbers
  number = true,
  relativenumber = true,

  -- Sign column
  signcolumn = "yes",  -- or "auto", "no"
}
```

#### LSP Configuration

```lua
lsp = {
  -- Language servers to enable
  servers = {
    -- Python
    pyright = {},

    -- TypeScript/JavaScript
    tsserver = {},

    -- Rust
    rust_analyzer = {
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true },
          checkOnSave = { command = "clippy" },
        },
      },
    },

    -- Go
    gopls = {},

    -- Lua
    lua_ls = {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
        },
      },
    },
  },

  -- Formatters
  formatters = {
    python = { "black", "isort" },
    javascript = { "prettier" },
    rust = { "rustfmt" },
  },
}
```

#### Keymaps

```lua
keymaps = {
  -- Format: { mode, key, command, opts }
  { "n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" } },
  { "n", "<leader>tt", "<cmd>ToggleTerm<cr>", { desc = "Toggle Terminal" } },
  { "v", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", { desc = "Code Action" } },
}
```

#### Editor Options

```lua
options = {
  -- Indentation
  shiftwidth = 2,    -- Number of spaces for indentation
  tabstop = 2,       -- Number of spaces for tab
  expandtab = true,  -- Use spaces instead of tabs

  -- Line wrapping
  wrap = false,      -- Disable line wrap
  linebreak = true,  -- Break lines at word boundaries

  -- Search
  ignorecase = true, -- Case insensitive search
  smartcase = true,  -- Override ignorecase if search has uppercase

  -- Performance
  updatetime = 200,  -- Faster completion (default 4000)
  timeoutlen = 300,  -- Faster key sequence completion
}
```

## Essential LazyVim Keymaps

### General

| Key | Mode | Action |
|-----|------|--------|
| `<leader>` | - | Space (default leader) |
| `<leader>l` | n | Open Lazy plugin manager |
| `<leader>ql` | n | Open location list |
| `<leader>qq` | n | Quit all |

### File Navigation

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ff` | n | Find files (Telescope) |
| `<leader>fg` | n | Live grep (Telescope) |
| `<leader>fb` | n | Find buffers (Telescope) |
| `<leader>fr` | n | Recent files (Telescope) |
| `<leader>e` | n | Toggle file explorer (Neo-tree) |

### Code Navigation

| Key | Mode | Action |
|-----|------|--------|
| `gd` | n | Go to definition |
| `gr` | n | Go to references |
| `gi` | n | Go to implementation |
| `K` | n | Hover documentation |
| `<leader>ca` | n/v | Code action |
| `<leader>cr` | n | Rename symbol |

### LSP & Diagnostics

| Key | Mode | Action |
|-----|------|--------|
| `<leader>cd` | n | Line diagnostics |
| `[d` | n | Previous diagnostic |
| `]d` | n | Next diagnostic |
| `<leader>cf` | n | Format document |

### Window Management

| Key | Mode | Action |
|-----|------|--------|
| `<C-h>` | n | Go to left window |
| `<C-j>` | n | Go to down window |
| `<C-k>` | n | Go to up window |
| `<C-l>` | n | Go to right window |
| `<leader>w` | n | Window prefix |
| `<leader>-` | n | Split window below |
| `<leader>\|` | n | Split window right |

### Terminal

| Key | Mode | Action |
|-----|------|--------|
| `<C-/>` | n | Toggle terminal |
| `<Esc><Esc>` | t | Exit terminal mode |

## Plugin Management

### Using Lazy

Open lazy plugin manager:
```
:Lazy
```

Actions:
- `I` - Install missing plugins
- `U` - Update plugins
- `S` - Sync (install + update + clean)
- `C` - Clean unused plugins
- `L` - View logs
- `P` - Profile startup time

### Adding New Plugins

Create a file in `~/dotfiles/config/nvim/lua/plugins/`:

```lua
-- ~/dotfiles/config/nvim/lua/plugins/my-plugin.lua
return {
  "author/plugin-name",
  dependencies = {
    "dependency/name",
  },
  config = function()
    require("plugin-name").setup({
      -- Configuration
    })
  end,
  keys = {
    { "<leader>mp", "<cmd>PluginCommand<cr>", desc = "My Plugin Command" },
  },
}
```

LazyVim automatically loads all files in `lua/plugins/`.

### Disabling Plugins

To disable a LazyVim default plugin:

```lua
-- ~/dotfiles/config/nvim/lua/plugins/disabled.lua
return {
  { "plugin/to-disable", enabled = false },
}
```

## LSP Configuration

### Installing Language Servers

LazyVim uses Mason for LSP installation:

```
:Mason
```

Or install via command line:
```
:MasonInstall rust-analyzer pyright typescript-language-server
```

### Configuring LSP Servers

In `local.lua`:

```lua
lsp = {
  servers = {
    pyright = {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            autoSearchPaths = true,
          },
        },
      },
    },
  },
}
```

### Custom LSP Keymaps

```lua
keymaps = {
  -- Override default LSP keymaps
  { "n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" } },
  { "n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" } },
}
```

## Formatting & Linting

### Configure Formatters

LazyVim uses `conform.nvim` for formatting:

```lua
lsp = {
  formatters = {
    python = { "black", "isort" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    lua = { "stylua" },
    rust = { "rustfmt" },
    go = { "gofmt", "goimports" },
  },
}
```

### Format on Save

Enable in `options`:
```lua
options = {
  autoformat = true,  -- Format on save
}
```

Or format manually:
```
:Format
```

## Troubleshooting

### Plugins Not Loading

1. **Check lazy.nvim installation**:
```bash
ls -la ~/.local/share/nvim/lazy/lazy.nvim
```

2. **Reinstall lazy.nvim**:
```bash
rm -rf ~/.local/share/nvim/lazy
nvim  # Will trigger bootstrap
```

3. **Check logs**:
```
:Lazy log
```

### LSP Not Working

1. **Check LSP status**:
```
:LspInfo
```

2. **Install language server**:
```
:Mason
# Press 'i' on the server to install
```

3. **Check LSP logs**:
```
:LspLog
```

### Slow Startup

1. **Profile startup**:
```
:Lazy profile
```

2. **Lazy-load plugins**:
```lua
return {
  "heavy/plugin",
  lazy = true,  -- Don't load on startup
  ft = "python",  -- Load only for Python files
}
```

### Local Config Not Loading

1. **Verify symlink**:
```bash
ls -la ~/.config/nvim/lua/local.lua
```

2. **Check for syntax errors**:
```bash
nvim --headless -c "luafile ~/dotfiles/machines/macbook/nvim.local.lua" -c "qa"
```

3. **View notifications**:
```
:messages
```

### OpenCode Plugin Issues

1. **Check plugin installation**:
```
:Lazy
# Search for "opencode"
```

2. **Reinstall plugin**:
```
:Lazy clean
:Lazy install
```

3. **Check configuration**:
```lua
:lua print(vim.inspect(require("opencode").config))
```

## Health Check

Run Neovim health check:
```
:checkhealth
```

Check specific components:
```
:checkhealth lazy
:checkhealth lsp
:checkhealth telescope
```

## Advanced Configuration

### Custom Autocommands

```lua
-- In local.lua
return {
  autocommands = {
    -- Format on save for specific filetypes
    {
      event = "BufWritePre",
      pattern = "*.py",
      command = "lua vim.lsp.buf.format()",
    },
    -- Highlight on yank
    {
      event = "TextYankPost",
      pattern = "*",
      callback = function()
        vim.highlight.on_yank({ timeout = 200 })
      end,
    },
  },
}
```

### Custom Commands

```lua
-- In local.lua
return {
  commands = {
    {
      name = "FormatJson",
      command = function()
        vim.cmd("%!jq .")
      end,
    },
  },
}
```

### Conditional Loading

```lua
-- Load configuration based on environment
local is_work_machine = os.getenv("WORK_ENV") == "1"

return {
  lsp = {
    servers = is_work_machine and {
      -- Work-specific LSP servers
      enterprise_lsp = {},
    } or {
      -- Personal LSP servers
      rust_analyzer = {},
    },
  },
}
```

## References

- [LazyVim Documentation](https://www.lazyvim.org/)
- [lazy.nvim GitHub](https://github.com/folke/lazy.nvim)
- [Neovim Documentation](https://neovim.io/doc/)
- [LSP Configuration Guide](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md)

## See Also

- [Wezterm Configuration Guide](./wezterm.md)
- [Maintenance Guide](./maintenance.md)
- [Troubleshooting Guide](./troubleshooting.md)
