# Dotfiles Configuration

Professional dotfiles management for Wezterm and Neovim with machine-specific customization support.

## Features

- **🖥️ Wezterm**: GPU-accelerated terminal with Dracula theme, custom fonts, and backgrounds
- **✏️ Neovim**: LazyVim distribution with OpenCode plugin and custom configurations
- **🔧 Modular Design**: Shared configurations with machine-specific overrides
- **🔒 Security-First**: Comprehensive .gitignore, secret management, and security guidelines
- **⚡ Performance**: Parallel installation, optimized symlink management
- **🔄 Idempotent**: Run installation scripts safely multiple times
- **💾 Backup/Rollback**: Automatic timestamped backups before any changes
- **📚 Well-Documented**: Comprehensive guides for setup, customization, and troubleshooting

## Quick Start

```bash
# Clone this repository
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles

# Run installation
./install.sh

# Restart your terminal
exec $SHELL

# Open Wezterm and Neovim to verify
```

## Architecture

```
~/dotfiles/
├── config/
│   ├── nvim/           # Neovim configuration (LazyVim)
│   └── wezterm/        # Wezterm configuration
├── machines/
│   ├── macbook/        # MacBook-specific configs
│   │   ├── wezterm.local.lua
│   │   ├── nvim.local.lua
│   │   └── metadata.json
│   └── macmini/        # Mac mini-specific configs
├── assets/
│   ├── fonts/          # Custom fonts (Git LFS)
│   └── wallpapers/     # Terminal backgrounds (Git LFS)
├── lib/                # Core utilities
├── installers/         # Component installers
├── scripts/            # Helper scripts
└── docs/               # Detailed documentation
```

## Installation

### Prerequisites

- macOS 11.0 or later
- Internet connection
- Admin access (for Homebrew)

### Full Installation

```bash
cd ~/dotfiles
./install.sh
```

The installation script performs:

1. **System Validation** - Check dependencies and system information
2. **Backup** - Create timestamped backups of existing configs
3. **Homebrew** - Install package manager (if not present)
4. **Dependencies** - Install fonts, Wezterm, Neovim, and tools (parallel)
5. **Configuration** - Create symlinks and apply machine-specific settings
6. **Verification** - Validate installation completeness

### Installation Options

```bash
./install.sh              # Full installation
./install.sh --debug      # Enable debug logging
./install.sh --rollback   # Restore from latest backup
./install.sh --list-backups  # Show available backups
./install.sh --help       # Show help message
```

## Machine-Specific Configuration

Each machine can have custom settings without modifying shared configurations.

### Directory Structure

```
machines/<machine-type>/
├── wezterm.local.lua   # Wezterm overrides
├── nvim.local.lua      # Neovim overrides
└── metadata.json       # Machine information
```

### Machine Types

- **macbook**: MacBook Pro/Air
- **macmini**: Mac mini
- **default**: Fallback if no machine-specific config exists

### Customization Examples

**Wezterm (`machines/macbook/wezterm.local.lua`)**:
```lua
return {
  background = {
    {
      source = {
        File = os.getenv("HOME") .. "/dotfiles/assets/wallpapers/machines/macbook/custom.png",
      },
      hsb = { brightness = 0.3 },
      opacity = 0.95,
    },
  },
  initial_rows = 40,
  initial_cols = 140,
}
```

**Neovim (`machines/macbook/nvim.local.lua`)**:
```lua
return {
  ui = {
    theme_variant = "darker",
    transparency = 0.95,
  },
  lsp = {
    servers = {
      rust_analyzer = {},
      gopls = {},
    },
  },
}
```

## Updating

Keep your dotfiles and tools up to date:

```bash
cd ~/dotfiles
./update.sh
```

The update script:
1. Pulls latest changes from Git
2. Updates Git submodules
3. Updates Homebrew packages
4. Updates Neovim plugins (headless `:Lazy sync`)
5. Cleans up old backups (keeps last 5)

## Configuration Locations

After installation, configurations are symlinked:

- **Neovim**: `~/.config/nvim` → `~/dotfiles/config/nvim`
- **Wezterm**: `~/.config/wezterm` → `~/dotfiles/config/wezterm`
- **Backups**: `~/.dotfiles-backups/<timestamp>/`
- **Logs**: `~/.dotfiles-install.log`

## Customization

### Wezterm

Edit shared configuration:
```bash
nvim ~/dotfiles/config/wezterm/wezterm.lua
```

Override for specific machine:
```bash
nvim ~/dotfiles/machines/macbook/wezterm.local.lua
```

### Neovim

LazyVim configuration:
```bash
nvim ~/dotfiles/config/nvim/lua/config/
```

Machine-specific overrides:
```bash
nvim ~/dotfiles/machines/macbook/nvim.local.lua
```

### Adding a New Machine

1. Create machine directory:
```bash
mkdir -p ~/dotfiles/machines/new-machine
```

2. Copy template:
```bash
cp ~/dotfiles/machines/macbook/wezterm.local.lua ~/dotfiles/machines/new-machine/
cp ~/dotfiles/machines/macbook/nvim.local.lua ~/dotfiles/machines/new-machine/
cp ~/dotfiles/machines/macbook/metadata.json ~/dotfiles/machines/new-machine/
```

3. Edit machine type in `lib/detect.sh`:
```bash
detect_machine_type() {
    case "${hostname_lower}" in
        *macbook*) echo "macbook" ;;
        *macmini*) echo "macmini" ;;
        *new-machine*) echo "new-machine" ;;  # Add this line
        *) echo "${hostname_lower}" ;;
    esac
}
```

4. Customize local configs for the new machine

## Security

This repository follows security best practices:

- **Secrets Management**: Use `.env` (git-ignored) for API keys and tokens
- **SSH Keys**: Never commit SSH keys or credentials
- **Pre-commit Hook**: Automatically scans for exposed secrets
- **Private Repository**: Recommended for personal dotfiles

See [SECURITY.md](./SECURITY.md) for detailed security guidelines.

## Troubleshooting

### Common Issues

**Symlink conflicts**:
```bash
# Remove existing configs (backed up automatically)
rm -rf ~/.config/nvim ~/.config/wezterm
./install.sh
```

**Homebrew not found**:
```bash
# Install Homebrew manually
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Neovim plugins not loading**:
```bash
# Bootstrap LazyVim manually
~/dotfiles/scripts/bootstrap-nvim.sh
```

**Check logs**:
```bash
tail -f ~/.dotfiles-install.log
```

See [docs/troubleshooting.md](./docs/troubleshooting.md) for detailed solutions.

## Included Tools

- **git**: Version control
- **curl/wget**: HTTP clients
- **fzf**: Fuzzy finder
- **bat**: Better `cat` with syntax highlighting
- **eza**: Better `ls` with icons
- **zoxide**: Smarter `cd`
- **jq**: JSON processor
- **gh**: GitHub CLI
- **ripgrep/fd**: Fast search tools (required by Neovim)
- **node**: JavaScript runtime (required for LSP servers)

## Documentation

- [Wezterm Configuration Guide](./docs/wezterm.md)
- [Neovim Configuration Guide](./docs/neovim.md)
- [Maintenance Guide](./docs/maintenance.md)
- [Troubleshooting Guide](./docs/troubleshooting.md)
- [Security Guide](./SECURITY.md)

## Project Structure

```
.
├── README.md              # This file
├── SECURITY.md            # Security guidelines
├── install.sh             # Main installation script
├── update.sh              # Update script
├── .gitignore             # Git ignore rules
├── .gitattributes         # Git LFS configuration
├── .env.example           # Environment variables template
├── config/                # Shared configurations
│   ├── nvim/              # Neovim/LazyVim config
│   └── wezterm/           # Wezterm config
├── machines/              # Machine-specific overrides
│   ├── macbook/
│   ├── macmini/
│   └── templates/
├── assets/                # Binary assets (Git LFS)
│   ├── fonts/
│   └── wallpapers/
├── lib/                   # Core utility libraries
│   ├── core.sh            # Logging, error handling
│   ├── detect.sh          # System detection
│   ├── backup.sh          # Backup management
│   └── symlink.sh         # Symlink utilities
├── installers/            # Component installers
│   ├── homebrew.sh
│   ├── fonts.sh
│   ├── wezterm.sh
│   ├── neovim.sh
│   └── tools.sh
├── scripts/               # Helper scripts
│   └── bootstrap-nvim.sh  # Manual LazyVim bootstrap
└── docs/                  # Detailed documentation
    ├── wezterm.md
    ├── neovim.md
    ├── maintenance.md
    └── troubleshooting.md
```

## License

Personal dotfiles configuration. Use at your own discretion.

## Credits

- **Wezterm**: https://wezfurlong.org/wezterm/
- **Neovim**: https://neovim.io/
- **LazyVim**: https://www.lazyvim.org/
- **OpenCode**: https://github.com/your-repo/opencode
- **Dracula Theme**: https://draculatheme.com/
- **PlemolJP**: https://github.com/yuru7/PlemolJP

---

**Status**: ✅ Production Ready

For questions or issues, check the [troubleshooting guide](./docs/troubleshooting.md) or review the installation logs at `~/.dotfiles-install.log`.
