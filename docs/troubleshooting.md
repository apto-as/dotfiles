# Troubleshooting Guide

Comprehensive troubleshooting guide for common issues with this dotfiles configuration.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Wezterm Issues](#wezterm-issues)
3. [Neovim Issues](#neovim-issues)
4. [Git Issues](#git-issues)
5. [Homebrew Issues](#homebrew-issues)
6. [Symlink Issues](#symlink-issues)
7. [Performance Issues](#performance-issues)
8. [macOS Specific Issues](#macos-specific-issues)

## Installation Issues

### Installation Script Fails Immediately

**Symptoms**: Script exits with error on first run

**Possible Causes**:
1. Missing Bash
2. Insufficient permissions
3. Internet connectivity issues

**Solutions**:

1. **Check Bash version**:
```bash
bash --version
# Should be 3.2 or higher
```

2. **Make script executable**:
```bash
chmod +x ~/dotfiles/install.sh
```

3. **Check internet connection**:
```bash
ping -c 3 google.com
```

4. **Run with debug mode**:
```bash
./install.sh --debug
```

5. **Check logs**:
```bash
tail -50 ~/.dotfiles-install.log
```

### Homebrew Installation Fails

**Symptoms**: Error installing Homebrew

**Solutions**:

1. **Install Homebrew manually**:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. **Add Homebrew to PATH** (Apple Silicon):
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

3. **Add Homebrew to PATH** (Intel Mac):
```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

4. **Verify installation**:
```bash
which brew
brew --version
```

### Parallel Installation Hangs

**Symptoms**: Installation stuck at Phase 4 (parallel installations)

**Solutions**:

1. **Wait longer** - First-time installations can take 5-10 minutes

2. **Check background processes**:
```bash
ps aux | grep -E "brew|nvim|wezterm"
```

3. **Kill hung processes**:
```bash
pkill -f "brew install"
```

4. **Run installation without parallelization** (edit `install.sh`):
```bash
# Comment out background jobs, run sequentially
install_fonts
install_wezterm
install_neovim
install_tools
```

### Permission Denied Errors

**Symptoms**: `Permission denied` errors during installation

**Solutions**:

1. **Fix Homebrew permissions**:
```bash
sudo chown -R $(whoami) /usr/local/Homebrew
sudo chown -R $(whoami) /opt/homebrew  # Apple Silicon
```

2. **Fix config directory permissions**:
```bash
sudo chown -R $(whoami) ~/.config
chmod 755 ~/.config
```

3. **Check sudo access** (for Homebrew installation):
```bash
sudo -v
```

## Wezterm Issues

### Wezterm Won't Launch

**Symptoms**: Wezterm crashes on startup or won't open

**Solutions**:

1. **Check if installed**:
```bash
ls -la /Applications/WezTerm.app
```

2. **Reinstall Wezterm**:
```bash
brew reinstall --cask wezterm
```

3. **Check configuration syntax**:
```bash
wezterm --config-file ~/.config/wezterm/wezterm.lua --version
```

4. **View error logs** (macOS):
```bash
log show --predicate 'process == "wezterm-gui"' --last 5m
```

5. **Reset configuration**:
```bash
# Backup current config
mv ~/.config/wezterm ~/.config/wezterm.backup

# Recreate symlink
ln -sf ~/dotfiles/config/wezterm ~/.config/wezterm
```

### Background Image Not Displaying

**Symptoms**: Solid color background instead of wallpaper

**Solutions**:

1. **Verify image file exists**:
```bash
ls -la ~/dotfiles/assets/wallpapers/machines/macbook/os_waallpaper_v3.png
```

2. **Check file path in config**:
```bash
# In local.lua
cat ~/.config/wezterm/local.lua | grep -A 5 "source"
```

3. **Verify image format**:
```bash
file ~/dotfiles/assets/wallpapers/machines/macbook/os_waallpaper_v3.png
# Should show: PNG image data
```

4. **Test with simpler config**:
```lua
-- Temporarily edit local.lua
return {
  background = {
    {
      source = { File = "/absolute/path/to/image.png" },
      opacity = 1.0,
    },
  },
}
```

5. **Check Wezterm logs**:
```bash
cat ~/Library/Logs/wezterm/wezterm.log | grep -i "background\|image"
```

### Font Not Loading

**Symptoms**: Wrong font displayed in Wezterm

**Solutions**:

1. **Verify font installation**:
```bash
# List installed fonts
fc-list | grep -i "PlemolJP"

# macOS
ls ~/Library/Fonts/ | grep -i Plemol
```

2. **Reinstall font**:
```bash
brew reinstall font-plemoljp-nf
```

3. **Clear font cache** (macOS):
```bash
sudo atsutil databases -remove
atsutil server -shutdown
atsutil server -ping
```

4. **Restart Wezterm**:
```bash
killall wezterm-gui
```

### Transparency Not Working

**Symptoms**: Wezterm window is fully opaque

**Solutions**:

1. **Check macOS transparency settings**:
   - System Settings → Accessibility → Display
   - Disable "Reduce transparency"

2. **Verify opacity in config**:
```lua
-- In wezterm.lua or local.lua
window_background_opacity = 0.95  -- Should be less than 1.0
```

3. **Check compositing**:
```lua
-- Some terminals need this
macos_window_background_blur = 20
```

### Wezterm Crashes Frequently

**Solutions**:

1. **Update Wezterm**:
```bash
brew upgrade --cask wezterm
```

2. **Disable GPU acceleration** (temporary):
```lua
-- Add to local.lua
return {
  front_end = "Software",  -- Use software rendering
}
```

3. **Reset configuration**:
```bash
mv ~/.config/wezterm/local.lua ~/.config/wezterm/local.lua.backup
# Restart Wezterm
```

4. **Check system resources**:
```bash
top -o MEM
# Check if memory is exhausted
```

## Neovim Issues

### Neovim Won't Start

**Symptoms**: Neovim crashes or shows errors on startup

**Solutions**:

1. **Check Neovim installation**:
```bash
which nvim
nvim --version
```

2. **Check configuration syntax**:
```bash
nvim --headless -c "checkhealth" -c "quit"
```

3. **Start with minimal config**:
```bash
nvim --noplugin
```

4. **Reset Neovim data**:
```bash
# Backup first
mv ~/.local/share/nvim ~/.local/share/nvim.backup
mv ~/.local/state/nvim ~/.local/state/nvim.backup

# Restart Neovim (will trigger fresh installation)
nvim
```

### LazyVim Plugins Not Installing

**Symptoms**: Plugins missing or lazy.nvim not working

**Solutions**:

1. **Check lazy.nvim installation**:
```bash
ls -la ~/.local/share/nvim/lazy/lazy.nvim
```

2. **Reinstall lazy.nvim**:
```bash
rm -rf ~/.local/share/nvim/lazy
nvim  # Will trigger bootstrap
```

3. **Manual plugin sync**:
```
:Lazy sync
```

4. **Force reinstall**:
```
:Lazy clean
:Lazy install
```

5. **Check network connectivity**:
```bash
git clone https://github.com/folke/lazy.nvim.git /tmp/test-lazy
rm -rf /tmp/test-lazy
```

### LSP Not Working

**Symptoms**: No code completion, go-to-definition not working

**Solutions**:

1. **Check LSP status**:
```
:LspInfo
```

2. **Install language server**:
```
:Mason
# Press 'i' on the required server
```

3. **Check Mason installation**:
```bash
ls -la ~/.local/share/nvim/mason/bin/
```

4. **Verify server config**:
```
:lua print(vim.inspect(vim.lsp.get_active_clients()))
```

5. **Check LSP logs**:
```
:LspLog
```

6. **Restart LSP**:
```
:LspRestart
```

### Slow Neovim Startup

**Symptoms**: Neovim takes 2+ seconds to start

**Solutions**:

1. **Profile startup**:
```bash
nvim --startuptime startup.log
cat startup.log | sort -k2 -n | tail -20
```

2. **Use lazy.nvim profiler**:
```
:Lazy profile
```

3. **Lazy-load plugins**:
```lua
-- In plugin config
return {
  "heavy/plugin",
  lazy = true,
  event = "VeryLazy",
}
```

4. **Disable unused plugins**:
```lua
return {
  "unused/plugin",
  enabled = false,
}
```

### Telescope Not Finding Files

**Symptoms**: File search returns no results

**Solutions**:

1. **Install dependencies**:
```bash
brew install ripgrep fd
```

2. **Check current directory**:
```
:pwd
```

3. **Try different search**:
```
:Telescope find_files hidden=true
```

4. **Check `.gitignore`**:
```bash
# Telescope respects .gitignore by default
cat .gitignore
```

### OpenCode Plugin Not Working

**Symptoms**: OpenCode commands not available

**Solutions**:

1. **Verify plugin installation**:
```
:Lazy
# Search for "opencode"
```

2. **Check plugin config**:
```bash
cat ~/dotfiles/config/nvim/lua/plugins/opencode.lua
```

3. **Reinstall plugin**:
```
:Lazy clean
:Lazy install
```

4. **Check logs**:
```
:messages
```

## Git Issues

### Cannot Push to Remote

**Symptoms**: `git push` fails with authentication error

**Solutions**:

1. **Check remote URL**:
```bash
git remote -v
```

2. **Use SSH instead of HTTPS**:
```bash
git remote set-url origin git@github.com:username/dotfiles.git
```

3. **Generate SSH key**:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add to GitHub → Settings → SSH Keys
```

4. **Use GitHub CLI**:
```bash
brew install gh
gh auth login
```

### Git LFS Issues

**Symptoms**: Large files not tracked properly

**Solutions**:

1. **Install Git LFS**:
```bash
brew install git-lfs
git lfs install
```

2. **Track file types**:
```bash
git lfs track "*.png"
git lfs track "*.jpg"
git add .gitattributes
```

3. **Check LFS status**:
```bash
git lfs ls-files
git lfs status
```

4. **Migrate existing files**:
```bash
git lfs migrate import --include="*.png,*.jpg"
```

### Merge Conflicts

**Symptoms**: `git pull` fails with conflicts

**Solutions**:

1. **View conflicts**:
```bash
git status
```

2. **Edit conflicting files**:
```bash
nvim <conflicting-file>
# Look for <<<<<<, ======, >>>>>> markers
```

3. **Accept local changes**:
```bash
git checkout --ours <file>
```

4. **Accept remote changes**:
```bash
git checkout --theirs <file>
```

5. **Use merge tool**:
```bash
git mergetool
```

6. **Complete merge**:
```bash
git add <resolved-files>
git commit
```

## Homebrew Issues

### Homebrew Command Not Found

**Symptoms**: `brew: command not found`

**Solutions**:

1. **Add to PATH** (Apple Silicon):
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

2. **Add to PATH** (Intel Mac):
```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### Homebrew Update Fails

**Symptoms**: `brew update` shows errors

**Solutions**:

1. **Reset Homebrew**:
```bash
cd $(brew --repo)
git fetch origin
git reset --hard origin/master
```

2. **Update without auto-update**:
```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew install package
```

3. **Clean Homebrew cache**:
```bash
brew cleanup -s
rm -rf $(brew --cache)
```

### Package Installation Fails

**Solutions**:

1. **Update Homebrew**:
```bash
brew update
```

2. **Retry installation**:
```bash
brew reinstall <package>
```

3. **Check available space**:
```bash
df -h
```

4. **Fix permissions**:
```bash
sudo chown -R $(whoami) $(brew --prefix)
```

## Symlink Issues

### Symlinks Not Created

**Symptoms**: Configurations in `~/.config/` are not symlinks

**Solutions**:

1. **Check existing files**:
```bash
ls -la ~/.config/nvim
ls -la ~/.config/wezterm
```

2. **Remove existing configs** (will be backed up):
```bash
rm -rf ~/.config/nvim ~/.config/wezterm
```

3. **Re-run installation**:
```bash
cd ~/dotfiles
./install.sh
```

### Broken Symlinks

**Symptoms**: Symlinks point to non-existent files

**Solutions**:

1. **Find broken symlinks**:
```bash
find ~/.config -type l ! -exec test -e {} \; -print
```

2. **Remove broken symlinks**:
```bash
find ~/.config -type l ! -exec test -e {} \; -delete
```

3. **Recreate symlinks**:
```bash
ln -sf ~/dotfiles/config/nvim ~/.config/nvim
ln -sf ~/dotfiles/config/wezterm ~/.config/wezterm
```

### Symlink Permission Errors

**Solutions**:

```bash
# Fix ownership
sudo chown -R $(whoami) ~/.config

# Fix permissions
chmod 755 ~/.config
chmod -R 644 ~/.config/*
```

## Performance Issues

### Slow Terminal Rendering

**Solutions**:

1. **Reduce Wezterm opacity**:
```lua
window_background_opacity = 1.0  -- Fully opaque
```

2. **Disable background image**:
```lua
-- Comment out in local.lua
-- background = { ... },
```

3. **Use software rendering**:
```lua
front_end = "Software"
```

### High CPU Usage

**Solutions**:

1. **Identify process**:
```bash
top -o CPU
```

2. **Check for infinite loops** in shell config:
```bash
# Disable custom shell config temporarily
zsh --no-rcs
```

3. **Reduce Neovim animations**:
```lua
-- In Neovim config
vim.g.neovide_cursor_animation_length = 0
```

### High Memory Usage

**Solutions**:

1. **Check memory usage**:
```bash
top -o MEM
```

2. **Reduce Neovim cache**:
```bash
rm -rf ~/.cache/nvim
```

3. **Disable unused plugins**:
```lua
return {
  "heavy/plugin",
  enabled = false,
}
```

## macOS Specific Issues

### Xcode Command Line Tools Missing

**Symptoms**: Installation fails with `xcode-select` error

**Solutions**:

```bash
xcode-select --install
```

### System Integrity Protection (SIP) Issues

**Symptoms**: Permission denied for system directories

**Solutions**:

Do NOT disable SIP. Instead:
1. Use user-writable directories only
2. This dotfiles repo already follows this principle
3. All configs are in `~/.config/` (user directory)

### Gatekeeper Blocks Wezterm

**Symptoms**: "Wezterm cannot be opened because the developer cannot be verified"

**Solutions**:

1. **Open from Finder**:
   - Right-click WezTerm.app
   - Select "Open"
   - Click "Open" in dialog

2. **Command line**:
```bash
xattr -dr com.apple.quarantine /Applications/WezTerm.app
```

## Getting Help

If you're still experiencing issues:

1. **Check installation logs**:
```bash
cat ~/.dotfiles-install.log
```

2. **Run health checks**:
```bash
# Neovim
nvim -c "checkhealth"

# System
brew doctor
```

3. **Create detailed bug report**:
```bash
# Include:
# - Operating system version
# - Error messages
# - Steps to reproduce
# - Relevant log snippets
```

4. **Rollback to previous state**:
```bash
./install.sh --rollback
```

## Emergency Procedures

### Complete Reset

If everything is broken:

```bash
# 1. Backup current state
mv ~/dotfiles ~/dotfiles.broken

# 2. Remove configurations
rm -rf ~/.config/nvim ~/.config/wezterm

# 3. Fresh clone
git clone <your-repo-url> ~/dotfiles

# 4. Fresh installation
cd ~/dotfiles
./install.sh

# 5. If still broken, check logs
cat ~/.dotfiles-install.log
```

### Nuclear Option

Complete removal and reinstall:

```bash
# Remove everything
rm -rf ~/dotfiles
rm -rf ~/.config/nvim
rm -rf ~/.config/wezterm
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.dotfiles-backups

# Reinstall Homebrew packages
brew uninstall --cask wezterm
brew uninstall neovim

# Start from scratch
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

## References

- [Wezterm Troubleshooting](https://wezfurlong.org/wezterm/troubleshooting.html)
- [LazyVim Troubleshooting](https://www.lazyvim.org/troubleshooting)
- [Homebrew Troubleshooting](https://docs.brew.sh/Troubleshooting)
- [Git Troubleshooting](https://git-scm.com/doc)

## See Also

- [Installation Guide](../README.md)
- [Wezterm Configuration](./wezterm.md)
- [Neovim Configuration](./neovim.md)
- [Maintenance Guide](./maintenance.md)
- [Security Guide](../SECURITY.md)
