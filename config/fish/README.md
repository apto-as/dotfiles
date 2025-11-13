# Fish Shell Configuration

Secure, modular Fish shell configuration integrated into the dotfiles system.

## 📋 Table of Contents

- [Features](#features)
- [Security](#security)
- [Directory Structure](#directory-structure)
- [Installation](#installation)
- [Configuration](#configuration)
- [Machine-Specific Settings](#machine-specific-settings)
- [Troubleshooting](#troubleshooting)

## ✨ Features

- **Security-First Design**: API keys and credentials stored securely outside Git
- **Modular Architecture**: Clean separation of concerns
- **Machine-Specific Configs**: Easy per-machine customization
- **Automatic Detection**: Hostname-based machine type detection
- **Performance Optimized**: Using `fish_add_path` for efficient PATH management
- **Wezterm Integration**: Native terminal integration (iTerm2 removed)
- **1Password CLI Support**: Optional integration with 1Password for credential management

## 🔒 Security

### Critical Security Features (Hestia Audit 2025-11-13)

1. **No Hardcoded Credentials**: All API keys moved to `~/.secure_credentials/`
2. **Strict Permissions**: Credential files are `chmod 600` (owner-only access)
3. **Git-Ignored**: `~/.secure_credentials/` is excluded from version control
4. **Automatic Loading**: Credentials loaded securely on shell startup
5. **Session Cleanup**: Credentials cleared on shell exit

### Credential Management

Two options for managing credentials:

#### Option 1: Secure Local File (Default)

```bash
# 1. Copy example file
cp ~/.secure_credentials/api_keys.env.example ~/.secure_credentials/api_keys.env

# 2. Set strict permissions
chmod 600 ~/.secure_credentials/api_keys.env

# 3. Edit with your actual credentials
nvim ~/.secure_credentials/api_keys.env
```

#### Option 2: 1Password CLI (Recommended)

```bash
# 1. Install 1Password CLI
brew install 1password-cli

# 2. Store credentials in 1Password
op item create --category=login --title="Gemini API Key" credential=your-key-here
op item create --category=login --title="OpenAI API Key" credential=your-key-here

# 3. Credentials will be loaded automatically when Fish starts
```

### Security Verification

```bash
# Check file permissions
ls -la ~/.secure_credentials/

# Verify credentials are loaded
fish -c 'echo "GEMINI_API_KEY set: $(test -n \"$GEMINI_API_KEY\" && echo YES || echo NO)"'
```

## 📁 Directory Structure

```
~/dotfiles/config/fish/
├── config.fish                      # Main configuration file
├── conf.d/                          # Auto-loaded configs
│   └── secure_credentials.fish      # Secure credential loading
├── functions/                       # Custom functions (optional)
└── completions/                     # Shell completions (optional)

~/dotfiles/machines/{MACHINE_TYPE}/
└── fish.local.fish                  # Machine-specific settings

~/.secure_credentials/
├── api_keys.env                     # Your actual credentials (chmod 600)
└── api_keys.env.example             # Template (version controlled)
```

## 🚀 Installation

### Automated Installation (via dotfiles)

```bash
cd ~/dotfiles
./install.sh
```

This will:
1. Install Fish shell
2. Symlink configurations
3. Create secure credentials directory
4. Add Fish to `/etc/shells`
5. Verify installation

### Manual Installation

```bash
# 1. Install Fish
brew install fish  # macOS
# or
sudo apt install fish  # Ubuntu

# 2. Create symlinks
ln -sf ~/dotfiles/config/fish/config.fish ~/.config/fish/config.fish
ln -sf ~/dotfiles/config/fish/conf.d/secure_credentials.fish ~/.config/fish/conf.d/

# 3. Setup secure credentials
mkdir -p ~/.secure_credentials
chmod 700 ~/.secure_credentials
cp ~/dotfiles/config/fish/api_keys.env.example ~/.secure_credentials/
chmod 600 ~/.secure_credentials/api_keys.env

# 4. Add to valid shells
echo $(which fish) | sudo tee -a /etc/shells

# 5. Set as default (optional)
chsh -s $(which fish)
```

## ⚙️ Configuration

### Main Config (`config.fish`)

The main configuration includes:

- **Environment Variables**: EDITOR, LANG, etc.
- **PATH Management**: Optimized with `fish_add_path`
- **Secure Credentials**: Auto-loaded from `~/.secure_credentials/`
- **Machine-Specific Loading**: Automatic detection and loading
- **Custom Functions**: Enhanced `cd`, `fzf` wrapper, etc.
- **Context Management**: Trinitas and OpenCode integration

### Auto-Loaded Configs (`conf.d/`)

Files in `conf.d/` are automatically loaded on shell startup:

- `secure_credentials.fish`: Handles API key loading
- Custom configs can be added here

### Environment Variables

Set in `config.fish`:

```fish
# Editor
set -gx EDITOR nvim

# Language
set -x LANG ja_JP.UTF-8

# PATH (using fish_add_path for automatic deduplication)
fish_add_path -p $HOME/.local/bin
fish_add_path -p $HOME/bin
fish_add_path -a $HOME/.cargo/bin
```

## 🖥️ Machine-Specific Settings

### Automatic Detection

Machine type is auto-detected based on hostname:

| Hostname Pattern | Machine Type |
|-----------------|--------------|
| `*macbook*` | macbook |
| `*macmini*` | macmini |
| `*ec2*`, `*aws*`, `ip-*` | ec2 |
| Other (macOS) | macos |
| Other (Linux) | linux |

### Manual Override

Set `MACHINE_TYPE` environment variable:

```fish
# In ~/.zshrc or ~/.bashrc (before starting Fish)
export MACHINE_TYPE="macbook"
```

### Creating Machine-Specific Config

Example for MacBook Pro:

```bash
# Create machine directory (if not exists)
mkdir -p ~/dotfiles/machines/macbook

# Create Fish config
cat > ~/dotfiles/machines/macbook/fish.local.fish <<'EOF'
# macOS-specific settings
set -gx HOMEBREW_PREFIX "/opt/homebrew"

# Aliases
alias tailscale "/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Custom functions
function transfer_files
    # Your custom functions here
end
EOF
```

## 🔧 Troubleshooting

### Credentials Not Loading

**Symptom**: API keys not available in Fish

**Solutions**:

```bash
# 1. Check file permissions
ls -la ~/.secure_credentials/api_keys.env
# Should show: -rw------- (600)

# 2. Verify file format (KEY=value, no quotes needed)
cat ~/.secure_credentials/api_keys.env

# 3. Test credential loading
fish -c 'source ~/.config/fish/conf.d/secure_credentials.fish; echo $GEMINI_API_KEY'

# 4. Check for syntax errors
fish -n ~/.config/fish/config.fish
```

### Machine-Specific Config Not Loading

**Symptom**: Warning "Machine config not found"

**Solutions**:

```bash
# 1. Check MACHINE_TYPE detection
fish -c 'echo $MACHINE_TYPE'

# 2. Check if config file exists
ls -la ~/dotfiles/machines/$MACHINE_TYPE/fish.local.fish

# 3. Create missing config
mkdir -p ~/dotfiles/machines/$MACHINE_TYPE
touch ~/dotfiles/machines/$MACHINE_TYPE/fish.local.fish
```

### PATH Issues

**Symptom**: Commands not found, PATH duplicates

**Solutions**:

```bash
# 1. Check current PATH
fish -c 'echo $PATH | tr " " "\n"'

# 2. Verify fish_add_path usage
grep "fish_add_path" ~/dotfiles/config/fish/config.fish

# 3. Reset Fish path
fish -c 'set -e fish_user_paths; exec fish'
```

### Performance Issues

**Symptom**: Slow shell startup

**Solutions**:

```bash
# 1. Profile Fish startup
fish -c 'time fish -c exit'

# 2. Check for slow plugins
fish -c 'time source ~/.config/fish/config.fish'

# 3. Consider migrating from oh-my-posh to Starship
# oh-my-posh: 50-150ms startup delay
# Starship: 5-20ms startup delay
```

## 📚 Additional Resources

- [Fish Shell Documentation](https://fishshell.com/docs/current/)
- [Dotfiles Project Structure](../../README.md)
- [Wezterm Integration](../wezterm/README.md)
- [Zellij Integration](../zellij/README.md)

## 🔄 Updates

### Updating Configuration

```bash
# 1. Pull latest dotfiles
cd ~/dotfiles
git pull

# 2. Reload Fish config
source ~/.config/fish/config.fish

# 3. Verify changes
fish --version
```

### Rollback

```bash
# Restore from backup
cp ~/.config/fish/config.fish.backup-YYYYMMDD-HHMMSS ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

---

**Generated by**: Trinitas System (Artemis Optimization + Hestia Security Audit)
**Date**: 2025-11-13
**Version**: 1.0.0
