#!/usr/bin/env bash
# ============================================================================
# lib/backup.sh - Backup Management
# Purpose: Create, restore, and manage configuration backups
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/core.sh"

readonly BACKUP_DIR="${HOME}/.dotfiles-backup"
readonly BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly BACKUP_MANIFEST="${BACKUP_DIR}/.manifest"

# Create backup directory structure
init_backup() {
    mkdir -p "${BACKUP_DIR}/${BACKUP_TIMESTAMP}"
    log_info "Backup location: ${BACKUP_DIR}/${BACKUP_TIMESTAMP}"
}

# Backup single file/directory
backup_item() {
    local target="$1"

    if [[ ! -e "${target}" ]]; then
        log_debug "Skip backup: ${target} does not exist"
        return 0
    fi

    local rel_path="${target#${HOME}/}"
    local dest="${BACKUP_DIR}/${BACKUP_TIMESTAMP}/${rel_path}"

    mkdir -p "$(dirname "${dest}")"

    if [[ -d "${target}" ]]; then
        cp -R "${target}" "${dest}" 2>/dev/null || true
    else
        cp "${target}" "${dest}" 2>/dev/null || true
    fi

    echo "${target}" >> "${BACKUP_MANIFEST}"
    log_success "Backed up: ${target}"
}

# Backup multiple items
backup_batch() {
    local -a items=("$@")

    init_backup

    for item in "${items[@]}"; do
        backup_item "${item}"
    done

    log_info "Backup complete: ${BACKUP_DIR}/${BACKUP_TIMESTAMP}"
}

# List available backups
list_backups() {
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_info "No backups found."
        return
    fi

    log_info "Available backups:"
    ls -1t "${BACKUP_DIR}" | grep -v "^\\." | head -10 | while read -r backup; do
        if [[ -d "${BACKUP_DIR}/${backup}" ]]; then
            local size
            size=$(du -sh "${BACKUP_DIR}/${backup}" 2>/dev/null | cut -f1)
            echo "  ${backup} (${size})"
        fi
    done
}

# Rollback to previous backup
rollback() {
    local backup_id="${1:-latest}"

    if [[ "${backup_id}" == "latest" ]]; then
        backup_id=$(ls -1t "${BACKUP_DIR}" | grep -v "^\\." | head -1)
    fi

    local backup_path="${BACKUP_DIR}/${backup_id}"

    if [[ ! -d "${backup_path}" ]]; then
        log_error "Backup not found: ${backup_id}"
        return 1
    fi

    log_warn "Rolling back to backup: ${backup_id}"

    # Restore from backup
    cd "${backup_path}" || return 1
    find . -type f | while read -r file; do
        local dest="${HOME}/${file#./}"
        mkdir -p "$(dirname "${dest}")"
        cp "${file}" "${dest}"
        log_success "Restored: ${dest}"
    done

    log_info "Rollback complete!"
}

# Clean old backups (keep last N)
cleanup_old_backups() {
    local keep_count="${1:-5}"

    if [[ ! -d "${BACKUP_DIR}" ]]; then
        return
    fi

    local -a old_backups
    mapfile -t old_backups < <(ls -1t "${BACKUP_DIR}" | grep -v "^\\." | tail -n +$((keep_count + 1)))

    if [[ ${#old_backups[@]} -gt 0 ]]; then
        log_info "Cleaning up ${#old_backups[@]} old backup(s)"
        for backup in "${old_backups[@]}"; do
            rm -rf "${BACKUP_DIR:?}/${backup}"
            log_debug "Deleted: ${backup}"
        done
    fi
}

# Export functions
export -f init_backup backup_item backup_batch
export -f list_backups rollback cleanup_old_backups
export BACKUP_DIR BACKUP_TIMESTAMP BACKUP_MANIFEST
