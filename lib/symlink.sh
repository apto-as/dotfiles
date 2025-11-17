#!/usr/bin/env bash
# ============================================================================
# lib/symlink.sh - Symlink Management
# Purpose: Create and manage symlinks with conflict resolution
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/core.sh"
source "${SCRIPT_DIR}/backup.sh"

# Create symlink with backup
create_symlink() {
    local src="$1"
    local dest="$2"

    # Validate source exists
    if [[ ! -e "${src}" ]]; then
        log_error "Source does not exist: ${src}"
        return 1
    fi

    # If dest exists and is not a symlink, backup
    if [[ -e "${dest}" ]] && [[ ! -L "${dest}" ]]; then
        log_warn "Backing up existing: ${dest}"
        backup_item "${dest}"
        rm -rf "${dest}"
    fi

    # If dest is a symlink pointing to correct location, skip
    if [[ -L "${dest}" ]] && [[ "$(readlink "${dest}")" == "${src}" ]]; then
        log_debug "Symlink already correct: ${dest} -> ${src}"
        return 0
    fi

    # Remove incorrect symlink
    if [[ -L "${dest}" ]]; then
        log_warn "Removing incorrect symlink: ${dest}"
        rm "${dest}"
    fi

    # Create parent directory
    mkdir -p "$(dirname "${dest}")"

    # Create symlink
    ln -sf "${src}" "${dest}"
    log_success "Symlinked: ${dest} -> ${src}"
}

# Create multiple symlinks
create_symlinks() {
    local -a mappings=("$@")

    for mapping in "${mappings[@]}"; do
        local src="${mapping%%:*}"
        local dest="${mapping##*:}"
        create_symlink "${src}" "${dest}"
    done
}

# Verify symlinks are correct
verify_symlinks() {
    local -a mappings=("$@")
    local errors=0

    for mapping in "${mappings[@]}"; do
        local src="${mapping%%:*}"
        local dest="${mapping##*:}"

        if [[ ! -L "${dest}" ]]; then
            log_error "Not a symlink: ${dest}"
            ((errors++))
        elif [[ "$(readlink "${dest}")" != "${src}" ]]; then
            log_error "Incorrect symlink: ${dest} -> $(readlink "${dest}") (expected: ${src})"
            ((errors++))
        else
            log_debug "✓ ${dest} -> ${src}"
        fi
    done

    return "${errors}"
}

# Remove symlink safely
remove_symlink() {
    local dest="$1"

    if [[ -L "${dest}" ]]; then
        rm "${dest}"
        log_success "Removed symlink: ${dest}"
    elif [[ -e "${dest}" ]]; then
        log_warn "Not a symlink, skipping: ${dest}"
    else
        log_debug "Does not exist: ${dest}"
    fi
}

# Export functions
export -f create_symlink create_symlinks verify_symlinks remove_symlink
