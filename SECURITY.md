# 🔐 Security & Secrets Management Guide

## Overview

This dotfiles repository uses a multi-layered approach to protect sensitive information. This document explains how to handle secrets safely.

---

## 🎯 Core Principles

1. **Never commit secrets to git**
2. **Use `.env` files for local secrets** (git-ignored)
3. **Use macOS Keychain for persistent credentials**
4. **Review commits before pushing**
5. **Keep private repository** (recommended)

---

## 📁 File Classification

### ✅ Safe to Commit (Public)
- Configuration structure and logic
- Plugin lists and keybindings
- Shared themes and colorschemes
- Documentation and guides
- `.env.example` (templates only)

### ⚠️ Machine-Specific (Git-Ignored)
- `**/local.lua` - Machine-specific config
- Wallpapers with personal info
- Custom scripts with hardcoded paths

### 🚫 NEVER Commit (Git-Ignored)
- API keys and tokens
- SSH private keys
- GPG keys
- Database credentials
- `.env` files with actual values
- `.git-credentials`
- Any file matching `*secret*`, `*token*`, `*password*`

---

## 🔧 Setup Instructions

### Step 1: Create Your .env File

```bash
cd ~/dotfiles
cp .env.example .env
nano .env  # Or use your preferred editor
```

Fill in your actual values:
```bash
GITHUB_TOKEN="ghp_your_actual_token_here"
OPENAI_API_KEY="sk-your_actual_key_here"
# ... etc
```

### Step 2: Set Proper Permissions

```bash
chmod 600 .env                    # Only you can read/write
chmod 700 ~/.ssh                  # Secure SSH directory
chmod 600 ~/.ssh/id_*             # Secure private keys
chmod 644 ~/.ssh/*.pub            # Public keys can be readable
```

### Step 3: Configure Machine-Specific Settings

```bash
# Copy template for your machine
cp machines/macbook/wezterm.local.lua ~/.config/wezterm/local.lua
cp machines/macbook/nvim.local.lua ~/.config/nvim/lua/local.lua

# Edit with your specific paths
nano ~/.config/wezterm/local.lua
```

### Step 4: Enable Git Credential Helper (macOS)

```bash
# Store credentials in macOS Keychain (encrypted)
git config --global credential.helper osxkeychain

# Remove plain-text credential storage
rm ~/.git-credentials  # If exists
```

---

## 🛡️ Secrets Management Tiers

### Tier 1: Environment Variables (.env)
**Best for**: API keys, tokens, configuration values

```bash
# In .env (git-ignored)
GITHUB_TOKEN="ghp_xxx"

# In shell script
source ~/dotfiles/.env
git clone https://${GITHUB_TOKEN}@github.com/user/repo.git
```

### Tier 2: macOS Keychain
**Best for**: Git credentials, SSH passphrases

```bash
# Store password
security add-generic-password -a "myusername" -s "myservice" -w

# Retrieve password
security find-generic-password -a "myusername" -s "myservice" -w
```

### Tier 3: SSH Agent
**Best for**: SSH key authentication

```bash
# Add key to agent (password required once per session)
ssh-add ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l
```

### Tier 4: Password Manager
**Best for**: Master passwords, recovery codes

Use 1Password, LastPass, or similar for:
- Master passwords
- 2FA recovery codes
- Emergency access credentials

---

## ⚠️ Common Pitfalls & Solutions

### Pitfall 1: Hardcoded Paths

❌ **Bad**:
```lua
File = "/Users/yourname/Pictures/wallpaper.png"
```

✅ **Good**:
```lua
File = os.getenv("HOME") .. "/dotfiles/assets/wallpapers/shared/default.png"
```

### Pitfall 2: Credentials in Shell History

```bash
# Clear sensitive commands from history
history -d $(history 1)

# Or use space prefix (won't be saved)
 export SECRET_KEY="xxx"  # Note the leading space
```

### Pitfall 3: Committing .env by Mistake

```bash
# Check what's staged before committing
git diff --cached

# If .env was accidentally staged:
git reset HEAD .env
```

---

## 🔍 Pre-Commit Security Checks

### Manual Check Before Every Commit

```bash
# Review all changes
git diff --cached

# Search for potential secrets
git diff --cached | grep -E '(token|password|secret|key|credential)'

# Check file permissions
find ~/dotfiles -name "*.lua" -o -name "*.sh" | xargs ls -la
```

### Automated Pre-Commit Hook (Recommended)

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Pre-commit hook: Prevent secrets from being committed

echo "🔍 Scanning for secrets..."

# Patterns to detect
PATTERNS=(
    "ghp_[a-zA-Z0-9]{36}"           # GitHub PAT
    "sk-[a-zA-Z0-9]{32,}"           # OpenAI API key
    "sk-ant-[a-zA-Z0-9-]{95}"       # Anthropic API key
    "AWS[A-Z0-9]{16,}"              # AWS keys
    "/Users/[a-zA-Z0-9-_]+/"        # Hardcoded user paths
)

for pattern in "${PATTERNS[@]}"; do
    if git diff --cached | grep -E "$pattern"; then
        echo "❌ BLOCKED: Potential secret detected!"
        echo "Pattern: $pattern"
        echo ""
        echo "Remove the secret and try again."
        exit 1
    fi
done

echo "✅ No secrets detected. Proceeding with commit."
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## 🚨 Emergency: Secret Was Committed

### If secret was committed but NOT pushed:

```bash
# Remove from last commit
git reset HEAD~1
rm .env  # Or fix the file
git add .
git commit -m "fix: remove sensitive data"
```

### If secret was pushed to remote:

1. **Immediately revoke** the exposed credential:
   - GitHub: https://github.com/settings/tokens
   - OpenAI: https://platform.openai.com/account/api-keys
   - AWS: https://console.aws.amazon.com/iam/

2. **Remove from git history**:
```bash
# Use BFG Repo-Cleaner or git-filter-repo
brew install bfg
bfg --replace-text passwords.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

3. **Rotate all credentials** in that repository

---

## 📋 Security Checklist

### Initial Setup
- [ ] Copy `.env.example` to `.env`
- [ ] Set proper file permissions (600 for .env, 700 for ~/.ssh)
- [ ] Configure git credential helper (osxkeychain)
- [ ] Remove any `.git-credentials` file
- [ ] Install pre-commit hook
- [ ] Review `.gitignore` coverage

### Before Each Commit
- [ ] Run `git diff --cached`
- [ ] Search for patterns: token, password, secret, key
- [ ] Check no hardcoded paths (e.g., `/Users/yourname/`)
- [ ] Verify `.env` is not staged

### Weekly Maintenance
- [ ] Rotate API keys older than 90 days
- [ ] Review git log for any suspicious commits
- [ ] Update `.gitignore` if new patterns emerge
- [ ] Backup `.env` securely (encrypted)

### Monthly Audit
- [ ] Review all SSH keys (ssh-add -l)
- [ ] Check for unused API tokens
- [ ] Verify file permissions haven't changed
- [ ] Update security documentation

---

## 📚 Additional Resources

- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [git-secrets](https://github.com/awslabs/git-secrets): Prevent secrets from being committed
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/): Remove sensitive data from history
- [macOS Keychain](https://support.apple.com/guide/keychain-access): Secure credential storage

---

**Remember**: Security is a process, not a product. Stay vigilant!

*Last updated: 2025-10-28*
