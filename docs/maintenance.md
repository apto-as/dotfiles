# Maintenance Guide

Complete guide for maintaining and updating your dotfiles configuration.

## Table of Contents

1. [Regular Updates](#regular-updates)
2. [Adding New Machines](#adding-new-machines)
3. [Modifying Configurations](#modifying-configurations)
4. [Backup Management](#backup-management)
5. [Git Workflow](#git-workflow)
6. [Plugin Management](#plugin-management)
7. [Troubleshooting](#troubleshooting)

## Regular Updates

### Automated Update Script

The repository includes an update script that handles all common update tasks:

```bash
cd ~/dotfiles
./update.sh
```

This script performs the following operations:

1. **Git Pull**: Fetches latest changes from remote repository
2. **Submodule Update**: Updates any git submodules
3. **Homebrew Update**: Updates Homebrew and installed packages
4. **Neovim Plugins**: Updates all Neovim plugins via lazy.nvim
5. **Backup Cleanup**: Removes old backups (keeps last 5)

### Manual Update Steps

If you prefer manual control:

#### 1. Update Dotfiles Repository

```bash
cd ~/dotfiles
git pull origin main
```

#### 2. Update Homebrew Packages

```bash
brew update
brew upgrade
brew cleanup
```

#### 3. Update Neovim Plugins

```bash
# Via command line
nvim --headless "+Lazy! sync" +qa

# Or inside Neovim
:Lazy sync
```

#### 4. Update Wezterm

```bash
brew upgrade --cask wezterm
```

### Update Frequency Recommendations

| Component | Recommended Frequency | Command |
|-----------|----------------------|---------|
| Dotfiles | Weekly | `git pull` |
| Homebrew | Weekly | `brew update && brew upgrade` |
| Neovim Plugins | Weekly | `:Lazy sync` |
| Wezterm | Monthly | `brew upgrade --cask wezterm` |
| Full System | Monthly | `./update.sh` |

## Adding New Machines

### Step 1: Clone Repository on New Machine

```bash
# Clone repository
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
```

### Step 2: Detect Machine Type

The installation script automatically detects machine type based on hostname:

```bash
# View current machine type
grep -A 10 "detect_machine_type" lib/detect.sh
```

### Step 3: Create Machine-Specific Configuration

If your new machine needs custom settings:

```bash
# Create machine directory
mkdir -p ~/dotfiles/machines/new-machine-name

# Copy templates
cp machines/macbook/wezterm.local.lua machines/new-machine-name/
cp machines/macbook/nvim.local.lua machines/new-machine-name/
cp machines/macbook/metadata.json machines/new-machine-name/
```

### Step 4: Edit Machine Detection Logic

Add your machine to the detection function:

```bash
# Edit lib/detect.sh
nvim ~/dotfiles/lib/detect.sh
```

Add your machine type:
```bash
detect_machine_type() {
    local hostname_lower
    hostname_lower=$(hostname -s | tr '[:upper:]' '[:lower:]')

    case "${hostname_lower}" in
        *macbook*) echo "macbook" ;;
        *macmini*) echo "macmini" ;;
        *new-machine*) echo "new-machine-name" ;;  # Add this line
        *) echo "${hostname_lower}" ;;
    esac
}
```

### Step 5: Run Installation

```bash
./install.sh
```

### Step 6: Commit Machine Configuration

```bash
git add machines/new-machine-name/
git add lib/detect.sh
git commit -m "Add configuration for new-machine-name"
git push origin main
```

## Modifying Configurations

### Shared Configuration Changes

For changes that should apply to all machines:

#### Wezterm

```bash
# Edit main config
nvim ~/dotfiles/config/wezterm/wezterm.lua

# Test changes
wezterm
```

#### Neovim

```bash
# Edit LazyVim config
nvim ~/dotfiles/config/nvim/lua/config/options.lua
nvim ~/dotfiles/config/nvim/lua/config/keymaps.lua

# Add new plugins
nvim ~/dotfiles/config/nvim/lua/plugins/new-plugin.lua
```

#### Commit Changes

```bash
cd ~/dotfiles
git add config/
git commit -m "Update shared configuration: <description>"
git push origin main
```

### Machine-Specific Changes

For changes that should only apply to one machine:

#### Wezterm

```bash
# Edit machine-specific config
nvim ~/dotfiles/machines/macbook/wezterm.local.lua

# Reload Wezterm
# Cmd+R in Wezterm or restart
```

#### Neovim

```bash
# Edit machine-specific config
nvim ~/dotfiles/machines/macbook/nvim.local.lua

# Reload Neovim
:source $MYVIMRC
```

#### Commit Changes

```bash
cd ~/dotfiles
git add machines/macbook/
git commit -m "Update macbook-specific configuration"
git push origin main
```

### Testing Configuration Changes

Before committing, test your changes:

1. **Create a backup**:
```bash
cd ~/dotfiles
git stash  # Temporary backup of changes
```

2. **Test the changes**:
```bash
# For Wezterm
wezterm

# For Neovim
nvim

# Check for errors
tail -f ~/.dotfiles-install.log
```

3. **Restore if needed**:
```bash
git stash pop  # Restore changes
# or
git stash drop  # Discard changes
```

## Backup Management

### Automatic Backups

The installation script creates timestamped backups automatically:

```bash
~/.dotfiles-backups/
├── 2025-10-28_14-30-45/
│   ├── nvim/
│   └── wezterm/
└── 2025-10-27_10-15-22/
    ├── nvim/
    └── wezterm/
```

### List Available Backups

```bash
./install.sh --list-backups
```

### Rollback to Previous Configuration

```bash
# Rollback to most recent backup
./install.sh --rollback

# Or manually restore specific backup
cp -r ~/.dotfiles-backups/2025-10-28_14-30-45/nvim ~/.config/
cp -r ~/.dotfiles-backups/2025-10-28_14-30-45/wezterm ~/.config/
```

### Manual Backup

Create a manual backup before major changes:

```bash
# Create backup directory
backup_dir="${HOME}/.dotfiles-backups/manual-$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "${backup_dir}"

# Backup configurations
cp -r ~/.config/nvim "${backup_dir}/"
cp -r ~/.config/wezterm "${backup_dir}/"

echo "Backup created: ${backup_dir}"
```

### Cleanup Old Backups

```bash
# Automatic cleanup (keeps last 5)
./update.sh

# Manual cleanup
find ~/.dotfiles-backups -maxdepth 1 -type d -name "2025-*" | \
  sort -r | tail -n +6 | xargs rm -rf
```

## Git Workflow

### Daily Workflow

1. **Make changes** to configuration files
2. **Test changes** on local machine
3. **Commit changes**:
```bash
cd ~/dotfiles
git add .
git commit -m "Descriptive commit message"
git push origin main
```

### Branch Strategy

For experimental changes, use feature branches:

```bash
# Create feature branch
git checkout -b feature/new-theme

# Make changes
nvim config/wezterm/wezterm.lua

# Test changes
wezterm

# Commit and push
git add config/wezterm/
git commit -m "Experiment with new color theme"
git push origin feature/new-theme

# If successful, merge to main
git checkout main
git merge feature/new-theme
git push origin main

# Delete feature branch
git branch -d feature/new-theme
git push origin --delete feature/new-theme
```

### Syncing Across Machines

When you update dotfiles on one machine:

```bash
# Machine A: Make changes and push
cd ~/dotfiles
# ... make changes ...
git add .
git commit -m "Update configuration"
git push origin main

# Machine B: Pull changes
cd ~/dotfiles
git pull origin main

# Verify changes applied
ls -la ~/.config/nvim
ls -la ~/.config/wezterm
```

### Handling Merge Conflicts

If you modify the same file on different machines:

```bash
# Pull latest changes
git pull origin main

# Git will notify you of conflicts
# Edit conflicting files manually
nvim <conflicting-file>

# Look for conflict markers:
# <<<<<<< HEAD
# Your changes
# =======
# Remote changes
# >>>>>>> origin/main

# Resolve conflicts, then:
git add <conflicting-file>
git commit -m "Resolve merge conflict in <file>"
git push origin main
```

### Tagging Releases

Create tags for stable configurations:

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Stable configuration - October 2025"

# Push tag to remote
git push origin v1.0.0

# List all tags
git tag -l

# Checkout specific tag
git checkout v1.0.0
```

## Plugin Management

### Neovim Plugins

#### Adding New Plugin

1. **Create plugin file**:
```bash
nvim ~/dotfiles/config/nvim/lua/plugins/my-plugin.lua
```

2. **Add configuration**:
```lua
return {
  "author/plugin-name",
  dependencies = { "dependency/name" },
  config = function()
    require("plugin-name").setup({
      -- Configuration
    })
  end,
}
```

3. **Restart Neovim** and run:
```
:Lazy install
```

#### Removing Plugin

1. **Delete or disable plugin file**:
```bash
# Disable
nvim ~/dotfiles/config/nvim/lua/plugins/old-plugin.lua
```
```lua
return {
  "author/old-plugin",
  enabled = false,
}
```

2. **Clean unused plugins**:
```
:Lazy clean
```

#### Updating Specific Plugin

```
:Lazy update plugin-name
```

### Wezterm Updates

Wezterm is installed via Homebrew:

```bash
# Update Wezterm
brew upgrade --cask wezterm

# Check version
wezterm --version
```

## Troubleshooting

### Symlinks Broken

If symlinks are broken after moving the dotfiles directory:

```bash
# Re-run installation to recreate symlinks
cd ~/dotfiles
./install.sh
```

### Configuration Not Loading

1. **Check symlinks**:
```bash
ls -la ~/.config/nvim
ls -la ~/.config/wezterm
```

2. **Verify symlink targets**:
```bash
readlink ~/.config/nvim
readlink ~/.config/wezterm
```

3. **Re-create symlinks**:
```bash
rm -f ~/.config/nvim ~/.config/wezterm
ln -sf ~/dotfiles/config/nvim ~/.config/nvim
ln -sf ~/dotfiles/config/wezterm ~/.config/wezterm
```

### Git Issues

#### Detached HEAD State

```bash
git checkout main
```

#### Undo Last Commit

```bash
# Keep changes
git reset --soft HEAD~1

# Discard changes
git reset --hard HEAD~1
```

#### Reset to Remote State

```bash
# Warning: This discards all local changes
git fetch origin
git reset --hard origin/main
```

### Installation Script Issues

Check logs:
```bash
tail -f ~/.dotfiles-install.log
```

Run with debug mode:
```bash
./install.sh --debug
```

## Performance Optimization

### Neovim Startup Time

Profile startup:
```
:Lazy profile
```

Optimize slow plugins:
```lua
-- Lazy-load plugins
return {
  "slow/plugin",
  lazy = true,
  event = "VeryLazy",  -- Load after startup
}
```

### Reduce Homebrew Update Time

```bash
# Skip update check
HOMEBREW_NO_AUTO_UPDATE=1 brew install package-name

# Or set permanently in shell config
export HOMEBREW_NO_AUTO_UPDATE=1
```

## Best Practices

1. **Commit Often**: Small, focused commits are easier to manage
2. **Test Before Pushing**: Always test changes locally first
3. **Use Descriptive Messages**: Clear commit messages help future you
4. **Backup Regularly**: Keep multiple backups of important configurations
5. **Document Changes**: Update docs when adding new features
6. **Version Tags**: Tag stable configurations for easy rollback
7. **Review Logs**: Check `~/.dotfiles-install.log` after updates
8. **Keep It Simple**: Don't over-customize; maintain readability

## Maintenance Checklist

### Weekly

- [ ] Update dotfiles: `git pull`
- [ ] Update Homebrew: `brew update && brew upgrade`
- [ ] Update Neovim plugins: `:Lazy sync`
- [ ] Review logs: `tail ~/.dotfiles-install.log`

### Monthly

- [ ] Full system update: `./update.sh`
- [ ] Clean old backups: Keep last 5 only
- [ ] Review and commit local changes
- [ ] Update documentation if needed
- [ ] Test on all machines

### Quarterly

- [ ] Review and optimize plugin list
- [ ] Update machine-specific configs
- [ ] Create version tag
- [ ] Archive old branches
- [ ] Review security settings

## References

- [Git Documentation](https://git-scm.com/doc)
- [Homebrew Documentation](https://docs.brew.sh/)
- [LazyVim Documentation](https://www.lazyvim.org/)
- [Wezterm Documentation](https://wezfurlong.org/wezterm/)

## See Also

- [Installation Guide](../README.md)
- [Wezterm Configuration](./wezterm.md)
- [Neovim Configuration](./neovim.md)
- [Troubleshooting Guide](./troubleshooting.md)
- [Security Guide](../SECURITY.md)
