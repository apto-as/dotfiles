# Incident Report: Fish Shell Environment Breakage
**Date**: 2025-11-17
**Severity**: HIGH
**Status**: RESOLVED
**Reporter**: User
**Responder**: Trinitas System (Hera, Athena, Artemis, Hestia)

---

## Executive Summary

Fish shell environment was broken during dotfiles integration on 2025-11-13. Critical Homebrew PATH and environment variables were not loaded, causing "主要なコマンドのパスが読み込めず" (main command paths not loading). The issue was discovered on 2025-11-17 when user ran `install.sh`, which resulted in warnings but did not fully break the environment (system-level `/etc/paths.d/homebrew` provided fallback).

**Root Cause**: `config-osx.fish` source statement was not migrated to dotfiles version of `config.fish`.

**Resolution Time**: ~45 minutes (2025-11-17 11:07 - 11:52)

---

## Timeline

| Time | Event |
|------|-------|
| 2025-11-13 20:51 | Initial Fish integration (commit unknown) |
| 2025-11-13 21:24 | Dotfiles config.fish created (274 lines) |
| 2025-11-13 21:24 | **CRITICAL OMISSION**: `source config-osx.fish` not migrated |
| 2025-11-17 11:07 | User runs `install.sh`, notices warnings |
| 2025-11-17 11:10 | User reports "environment is broken" |
| 2025-11-17 11:15 | Trinitas full mode activated (Hera, Athena, Artemis, Hestia) |
| 2025-11-17 11:30 | Root cause identified: missing `config-osx.fish` source |
| 2025-11-17 11:40 | Fix implemented: Added OS-specific config loading |
| 2025-11-17 11:50 | Verification complete: All commands accessible |
| 2025-11-17 11:52 | Environment fully recovered |

---

## Root Cause Analysis

### Primary Cause

**Missing Dependency**: `source config-osx.fish` statement (original line 96)

**Original config.fish** (`~/.config/fish/config.fish.backup-20251113-205153`):
```fish
94→switch (uname)
95→    case Darwin
96→        source (dirname (status --current-filename))/config-osx.fish  # ← CRITICAL
97→    case Linux
```

**New config.fish** (`dotfiles/config/fish/config.fish`):
```fish
# ❌ MISSING: config-osx.fish source statement
# ❌ MISSING: Homebrew environment variables
# ❌ MISSING: Homebrew PATH additions
```

### Contributing Factors

1. **Incomplete Migration**: Only partial content was migrated
2. **No Dependency Analysis**: `config-osx.fish` dependency was not identified
3. **Insufficient Testing**: Post-change testing did not catch missing PATH entries
4. **No Baseline Comparison**: Before/after comparison was not performed

### Impact

**Critical Systems Affected**:
- Homebrew environment variables (`HOMEBREW_PREFIX`, `HOMEBREW_CELLAR`, `HOMEBREW_REPOSITORY`)
- Homebrew PATH (`/opt/homebrew/bin`, `/opt/homebrew/sbin`)
- macOS build dependencies (`LDFLAGS`, `CPPFLAGS`, `TESSDATA_PREFIX`)

**Actual User Impact**: **MEDIUM** (not HIGH)
- System-level `/etc/paths.d/homebrew` provided fallback PATH
- Commands remained accessible despite configuration error
- User experienced warnings but not complete failure

**Potential Impact** (if system PATH fallback didn't exist): **CRITICAL**
- All Homebrew commands would be inaccessible
- Git, Neovim, essential tools would fail
- Development work would be blocked

---

## Resolution

### Immediate Fix

1. **Added OS-Specific Config Loading** (`config.fish` lines 108-137):
```fish
switch (uname)
    case Darwin
        set os_config (dirname (status --current-filename))/config-osx.fish
        if test -f $os_config
            source $os_config
        else if test -f ~/.config/fish/config-osx.fish
            source ~/.config/fish/config-osx.fish  # Fallback
        end
    # ... other OS cases
end
```

2. **Copied `config-osx.fish` to Dotfiles**:
```bash
cp ~/.config/fish/config-osx.fish ~/dotfiles/config/fish/config-osx.fish
```

3. **Created Machine-Specific Config**:
```bash
mkdir -p ~/dotfiles/machines/macmini
# Created fish.local.fish (empty, for future customizations)
```

4. **Fixed Hostname Detection**:
```fish
case 'Mac'  # ← Added specific case for user's hostname
    set -gx MACHINE_TYPE "macmini"
```

### Verification

```bash
# ✅ Homebrew environment
HOMEBREW_PREFIX=/opt/homebrew

# ✅ PATH includes Homebrew
/opt/homebrew/bin
/opt/homebrew/sbin

# ✅ All commands accessible
git, brew, nvim, exa, zoxide, fzf
```

---

## Prevention Measures

### Process Improvements

1. **Pre-Change Baseline**:
   ```bash
   # Always capture before state
   fish -c 'echo $PATH' > /tmp/path_before.txt
   fish -c 'set -xg' > /tmp/env_before.txt
   ```

2. **Dependency Analysis**:
   ```bash
   # Identify all source statements
   grep -rn "source" ~/.config/fish/config.fish

   # Identify all external dependencies
   grep -rn "dirname.*status" ~/.config/fish/config.fish
   ```

3. **Post-Change Verification**:
   ```bash
   # Test critical commands
   for cmd in git brew nvim; which $cmd || echo "MISSING: $cmd"; end

   # Compare before/after
   diff /tmp/path_before.txt /tmp/path_after.txt
   ```

4. **Staged Rollout**:
   ```bash
   # Test in isolated session first
   fish --no-config -c 'source ~/dotfiles/config/fish/config.fish; which git'
   ```

### Code Improvements

1. **Explicit Dependency Documentation**:
```fish
# ============================================================================
# DEPENDENCIES (Files that must exist for this config to work)
# ============================================================================
# - config-osx.fish: macOS-specific settings (Homebrew, build tools)
# - conf.d/secure_credentials.fish: API key management
# - machines/{MACHINE_TYPE}/fish.local.fish: Machine-specific overrides
```

2. **Fail-Safe Defaults**:
```fish
# If config-osx.fish not found, set critical variables anyway
if not set -q HOMEBREW_PREFIX
    set -gx HOMEBREW_PREFIX "/opt/homebrew"
    fish_add_path -p /opt/homebrew/bin /opt/homebrew/sbin
end
```

3. **Self-Diagnostic**:
```fish
# config.fish startup diagnostic
function __fish_config_diagnostic
    set -l issues 0

    # Check Homebrew
    if not set -q HOMEBREW_PREFIX
        echo "⚠️  HOMEBREW_PREFIX not set" >&2
        set issues (math $issues + 1)
    end

    # Check critical commands
    for cmd in git brew nvim
        if not type -q $cmd
            echo "⚠️  Command not found: $cmd" >&2
            set issues (math $issues + 1)
        end
    end

    if test $issues -gt 0
        echo "❌ $issues configuration issue(s) detected" >&2
        echo "   Run: fish_diagnose for details" >&2
    end
end

# Run diagnostic on startup (only if FISH_DEBUG set)
if set -q FISH_DEBUG
    __fish_config_diagnostic
end
```

---

## Lessons Learned

### What Went Wrong

1. **Assumption**: "fish_add_path handles everything" → Reality: System-specific variables also needed
2. **Incomplete Analysis**: Only looked at PATH manipulation, not at sourced files
3. **No Testing**: Changes were committed without running Fish in test session
4. **Missing Documentation**: No note that `config-osx.fish` is critical dependency

### What Went Right

1. **Backups Worked**: Multiple backup layers (`*.backup-*`, `*.pre-dotfiles-*`)
2. **System Fallback**: `/etc/paths.d/homebrew` prevented complete failure
3. **Fast Recovery**: Trinitas full mode identified and fixed root cause quickly
4. **No Data Loss**: All configurations preserved and recoverable

### Rule Violations (CLAUDE.md)

| Rule | Violation | Impact |
|------|-----------|--------|
| **Rule 1** | No measurement before reporting | Assumed fish_add_path was sufficient |
| **Rule 2** | No baseline measurement | Didn't capture before-state |
| **Rule 3** | Incomplete transparency | Didn't report config-osx.fish omission |
| **Rule 4** | No staged verification | Committed without testing |

---

## Recommendations

### Immediate (Do Now)

- [x] Add `config-osx.fish` source to `config.fish`
- [x] Create `machines/macmini/fish.local.fish`
- [x] Verify all commands accessible
- [ ] User to test in new terminal session

### Short-term (This Week)

- [ ] Add fish config diagnostic function
- [ ] Document all config.fish dependencies
- [ ] Create `TESTING.md` with pre-change checklist
- [ ] Add CI/CD test for Fish config validity

### Long-term (Next Sprint)

- [ ] Implement automated before/after comparison
- [ ] Add fish config linter (check for common mistakes)
- [ ] Create fish config template with all OS-specific files
- [ ] Document migration process in `CONTRIBUTING.md`

---

## References

- Backup files: `~/.config/fish/*.backup-*`, `~/.config/fish/*.pre-dotfiles-*`
- Installer log: `~/.dotfiles-install.log`
- Git commit: (pending - changes not yet committed)
- User report: 2025-11-17 11:10 (GitHub issue or chat log)

---

## Sign-off

**Incident Resolved By**: Trinitas System (Hera, Athena, Artemis, Hestia)
**Verified By**: User (pending final test in new terminal)
**Date**: 2025-11-17
**Status**: ✅ RESOLVED (environment fully functional)

---

*This incident report is part of the permanent record for the dotfiles project.*
*File location: `/Users/apto-as/dotfiles/INCIDENT_REPORT_20251117.md`*
