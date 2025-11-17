#!/usr/bin/env bash
# ============================================================================
# scripts/verify-path.sh - PATH Configuration Verification
# Purpose: Verify PATH configuration is correct and secure
# Security: Hestia Audit 2025-11-17
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Verifying PATH configuration..."
echo ""

ERRORS=0
WARNINGS=0

# ============================================================================
# 1. Fish Shell PATH Verification
# ============================================================================
echo "=== Fish Shell PATH ==="

if command -v fish &> /dev/null; then
    FISH_PATH=$(fish -c 'echo $PATH' | tr ' ' '\n')

    # Check for Homebrew paths
    if echo "$FISH_PATH" | grep -q "/opt/homebrew/bin"; then
        echo -e "${GREEN}✓${NC} Homebrew /bin path configured"
    else
        echo -e "${RED}✗${NC} Homebrew /bin path MISSING"
        ((ERRORS++))
    fi

    if echo "$FISH_PATH" | grep -q "/opt/homebrew/sbin"; then
        echo -e "${GREEN}✓${NC} Homebrew /sbin path configured"
    else
        echo -e "${YELLOW}⚠${NC}  Homebrew /sbin path missing (optional)"
        ((WARNINGS++))
    fi

    # Check for user paths
    if echo "$FISH_PATH" | grep -q "$HOME/.local/bin"; then
        echo -e "${GREEN}✓${NC} User .local/bin path configured"
    else
        echo -e "${YELLOW}⚠${NC}  User .local/bin path missing (optional)"
        ((WARNINGS++))
    fi

    # Check for Cargo (Rust)
    if echo "$FISH_PATH" | grep -q "$HOME/.cargo/bin"; then
        echo -e "${GREEN}✓${NC} Cargo (Rust) path configured"
    else
        echo -e "${YELLOW}⚠${NC}  Cargo path missing (install Rust if needed)"
    fi

    # Check for system paths
    if echo "$FISH_PATH" | grep -q "/usr/bin"; then
        echo -e "${GREEN}✓${NC} System /usr/bin path present"
    else
        echo -e "${RED}✗${NC} System /usr/bin path MISSING"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗${NC} Fish shell not found"
    ((ERRORS++))
fi

echo ""

# ============================================================================
# 2. Zellij Binary Verification
# ============================================================================
echo "=== Zellij Binary ==="

if command -v zellij &> /dev/null; then
    ZELLIJ_PATH=$(which zellij)
    ZELLIJ_VERSION=$(zellij --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓${NC} Zellij binary accessible: $ZELLIJ_PATH"
    echo "  Version: $ZELLIJ_VERSION"

    # Check permissions
    if [ -x "$ZELLIJ_PATH" ]; then
        echo -e "${GREEN}✓${NC} Zellij binary is executable"
    else
        echo -e "${RED}✗${NC} Zellij binary is NOT executable"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗${NC} Zellij binary not found in PATH"
    echo "  Install with: brew install zellij"
    ((ERRORS++))
fi

echo ""

# ============================================================================
# 3. WezTerm Quarantine Check (macOS only)
# ============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "=== WezTerm Quarantine Status ==="

    if [ -d "/Applications/WezTerm.app" ]; then
        if xattr -l /Applications/WezTerm.app 2>/dev/null | grep -q "com.apple.quarantine"; then
            echo -e "${YELLOW}⚠${NC}  WezTerm has Gatekeeper quarantine attribute"
            echo "  This may restrict PATH when launched from Finder/Dock"
            echo ""
            echo "  Fix: xattr -d com.apple.quarantine /Applications/WezTerm.app"
            ((WARNINGS++))
        else
            echo -e "${GREEN}✓${NC} WezTerm quarantine attribute cleared"
        fi

        # Check code signing
        if codesign -vv /Applications/WezTerm.app 2>&1 | grep -q "valid on disk"; then
            echo -e "${GREEN}✓${NC} WezTerm code signature valid"
        else
            echo -e "${YELLOW}⚠${NC}  WezTerm code signature verification failed"
            ((WARNINGS++))
        fi

        # Check Gatekeeper assessment
        if spctl -a -vv -t exec /Applications/WezTerm.app 2>&1 | grep -q "accepted"; then
            echo -e "${GREEN}✓${NC} WezTerm Gatekeeper assessment: accepted"
        else
            echo -e "${YELLOW}⚠${NC}  WezTerm Gatekeeper assessment failed"
            ((WARNINGS++))
        fi
    else
        echo -e "${RED}✗${NC} WezTerm.app not found in /Applications/"
        echo "  Install with: brew install --cask wezterm"
        ((ERRORS++))
    fi

    echo ""
fi

# ============================================================================
# 4. Configuration File Permissions
# ============================================================================
echo "=== Config File Permissions ==="

CONFIG_FILES=(
    "$HOME/.config/fish/config.fish"
    "$HOME/.config/wezterm/wezterm.lua"
    "$HOME/.config/zellij/config.kdl"
)

for config in "${CONFIG_FILES[@]}"; do
    if [ -e "$config" ]; then
        PERMS=$(stat -f "%Lp" "$config" 2>/dev/null || stat -c "%a" "$config" 2>/dev/null)
        OWNER=$(stat -f "%Su" "$config" 2>/dev/null || stat -c "%U" "$config" 2>/dev/null)

        # Check for world-writable (dangerous)
        if [[ "$PERMS" == *"2" ]] || [[ "$PERMS" == *"7" ]]; then
            echo -e "${RED}✗${NC} $config is WORLD-WRITABLE ($PERMS)"
            echo "  Fix: chmod 644 $config"
            ((ERRORS++))
        else
            echo -e "${GREEN}✓${NC} $config ($PERMS, owner: $OWNER)"
        fi
    else
        echo -e "${YELLOW}⚠${NC}  $config not found (may be symlink)"
    fi
done

echo ""

# ============================================================================
# 5. Homebrew Environment Variables
# ============================================================================
if command -v fish &> /dev/null; then
    echo "=== Homebrew Environment ==="

    HOMEBREW_PREFIX=$(fish -c 'echo $HOMEBREW_PREFIX')
    HOMEBREW_CELLAR=$(fish -c 'echo $HOMEBREW_CELLAR')
    HOMEBREW_REPOSITORY=$(fish -c 'echo $HOMEBREW_REPOSITORY')

    if [ -n "$HOMEBREW_PREFIX" ]; then
        echo -e "${GREEN}✓${NC} HOMEBREW_PREFIX: $HOMEBREW_PREFIX"
    else
        echo -e "${RED}✗${NC} HOMEBREW_PREFIX not set"
        ((ERRORS++))
    fi

    if [ -n "$HOMEBREW_CELLAR" ]; then
        echo -e "${GREEN}✓${NC} HOMEBREW_CELLAR: $HOMEBREW_CELLAR"
    else
        echo -e "${YELLOW}⚠${NC}  HOMEBREW_CELLAR not set"
        ((WARNINGS++))
    fi

    if [ -n "$HOMEBREW_REPOSITORY" ]; then
        echo -e "${GREEN}✓${NC} HOMEBREW_REPOSITORY: $HOMEBREW_REPOSITORY"
    else
        echo -e "${YELLOW}⚠${NC}  HOMEBREW_REPOSITORY not set"
        ((WARNINGS++))
    fi

    echo ""
fi

# ============================================================================
# Summary
# ============================================================================
echo "==================================="
echo "Summary:"
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! System is SECURE and FUNCTIONAL.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ System is functional but has $WARNINGS warning(s).${NC}"
    exit 0
else
    echo -e "${RED}✗ System has $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo ""
    echo "Recommended Actions:"
    echo "  1. Review errors above"
    echo "  2. Run installer: ~/dotfiles/install.sh"
    echo "  3. Remove WezTerm quarantine: xattr -d com.apple.quarantine /Applications/WezTerm.app"
    exit 1
fi
