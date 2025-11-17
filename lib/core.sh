#!/usr/bin/env bash
# ============================================================================
# lib/core.sh - Core Utilities
# Purpose: Logging, error handling, performance utilities
# ============================================================================

set -euo pipefail

# Performance optimized logging
LOG_FILE="${HOME}/.dotfiles-install.log"
TIMESTAMP_FORMAT="+%Y-%m-%d %H:%M:%S"

# Color codes (with terminal detection)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

# Logging functions
log_info() {
    local msg="$1"
    echo -e "${GREEN}[INFO]${NC} ${msg}" | tee -a "${LOG_FILE}"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} ${msg}" | tee -a "${LOG_FILE}"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} ${msg}" | tee -a "${LOG_FILE}" >&2
}

log_debug() {
    local msg="$1"
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} ${msg}" >> "${LOG_FILE}"
    fi
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}✓${NC} ${msg}" | tee -a "${LOG_FILE}"
}

# Check if command exists (using hash, faster than 'which')
command_exists() {
    hash "$1" 2>/dev/null
}

# Check if package is already installed
is_installed() {
    local package="$1"
    case "${OSTYPE}" in
        darwin*)
            brew list "${package}" &>/dev/null
            ;;
        linux*)
            dpkg -l "${package}" &>/dev/null 2>&1 || \
            rpm -q "${package}" &>/dev/null 2>&1
            ;;
    esac
}

# Spinner for long-running operations
show_spinner() {
    local pid=$1
    local msg="${2:-Processing}"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    echo -n "${msg} "
    while ps -p "${pid}" &>/dev/null; do
        local temp=${spinstr#?}
        printf "${CYAN}[%c]${NC} " "${spinstr}"
        spinstr=${temp}${spinstr%"$temp"}
        sleep "${delay}"
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Error handler with stack trace
error_handler() {
    local line_no=$1
    log_error "Failed at line ${line_no}"
    log_error "Stack trace:"
    local i=0
    while caller $i >> "${LOG_FILE}"; do
        ((i++))
    done
    exit 1
}

trap 'error_handler ${LINENO}' ERR

# Dependency check
check_dependencies() {
    local -a required_commands=("curl" "git")
    local missing=()

    for cmd in "${required_commands[@]}"; do
        if ! command_exists "${cmd}"; then
            missing+=("${cmd}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        log_info "Please install them first."
        exit 1
    fi
}

# Performance timer
start_timer() {
    date +%s
}

end_timer() {
    local start=$1
    local end=$(date +%s)
    echo $((end - start))
}

# Format seconds to human-readable time
format_time() {
    local seconds=$1
    if [[ ${seconds} -lt 60 ]]; then
        echo "${seconds}s"
    else
        echo "$((seconds / 60))m $((seconds % 60))s"
    fi
}

# Confirm action
confirm() {
    local msg="$1"
    local default="${2:-n}"

    if [[ "${default}" == "y" ]]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi

    echo -n -e "${YELLOW}${msg}${NC} ${prompt}: "
    read -r response

    response="${response:-${default}}"

    if [[ "${response}" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Export functions for use in subshells
export -f log_info log_warn log_error log_debug log_success
export -f command_exists is_installed
export LOG_FILE
