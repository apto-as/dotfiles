# Machine-Specific Configurations

This directory contains machine-specific configurations for different computers.

## Structure

```
machines/
├── _template/           # Template for new machines (copy this)
│   ├── fish.local.fish  # Fish shell configuration template
│   └── metadata.json    # Machine metadata template
├── macbook/             # MacBook Pro configuration
│   ├── fish.local.fish  # Fish shell settings
│   ├── metadata.json    # Machine info
│   ├── nvim.local.lua   # Neovim settings (optional)
│   └── wezterm.local.lua # Wezterm settings (optional)
└── README.md            # This file
```

## Adding a New Machine

1. **Copy the template:**
   ```bash
   cp -r machines/_template machines/{your-machine-name}
   ```

2. **Edit metadata.json** with your machine's information

3. **Customize fish.local.fish** with machine-specific:
   - Conda/Python environment paths
   - Homebrew paths (Intel vs Apple Silicon)
   - Build dependencies (LDFLAGS, CPPFLAGS)
   - Machine-specific aliases and functions

4. **Set MACHINE_TYPE** (optional - auto-detects from hostname):
   ```fish
   set -gx MACHINE_TYPE "your-machine-name"
   ```

## How It Works

The main `config.fish` loads machine-specific configuration based on:

1. `$MACHINE_TYPE` environment variable (if set)
2. Auto-detection from hostname patterns

Loading order:
```
config.fish (portable, shared)
    ↓
config-{os}.fish (OS-specific: macOS, Linux)
    ↓
machines/{MACHINE_TYPE}/fish.local.fish (machine-specific)
```

## Common Machine Types

| MACHINE_TYPE | Description |
|--------------|-------------|
| `macbook` | MacBook Pro/Air (Apple Silicon or Intel) |
| `macmini` | Mac Mini |
| `macos` | Generic macOS (fallback) |
| `linux` | Generic Linux |
| `ec2` | AWS EC2 instances |

## What Goes Where?

| Setting | Location |
|---------|----------|
| Editor, shell options | `config.fish` |
| Aliases (universal) | `config.fish` |
| OS-specific paths | `config-{os}.fish` |
| Conda/Miniforge | `machines/{type}/fish.local.fish` |
| Build dependencies | `machines/{type}/fish.local.fish` |
| Personal functions | `machines/{type}/fish.local.fish` |
| SSH shortcuts | `machines/{type}/fish.local.fish` |
